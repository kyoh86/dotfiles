#!/usr/bin/env -S deno run --allow-run --allow-read --allow-write --allow-env

type Axis = "row" | "col";

type Rect = {
  x: number;
  y: number;
  w: number;
  h: number;
};

type Leaf = {
  type: "leaf";
  pane: string;
  rect: Rect;
};

type Split = {
  type: "split";
  axis: Axis;
  rect: Rect;
  children: [Node, Node];
};

type Node = Leaf | Split;

type State = {
  selectedPath: number[];
  preselect: Axis | null;
  popups: string[];
};

const SELECT_BG = "#2a2230";
const FOCUS_BG = "#33283a";
const STEP = 5;

async function tmux(args: string[]): Promise<string> {
  const cmd = new Deno.Command("tmux", { args, stdout: "piped", stderr: "piped" });
  const out = await cmd.output();
  if (!out.success) {
    const err = new TextDecoder().decode(out.stderr);
    throw new Error(`tmux ${args.join(" ")} failed: ${err}`);
  }
  return new TextDecoder().decode(out.stdout).trimEnd();
}

function parseRectParts(w: string, h: string, x: string, y: string): Rect {
  return { w: Number(w), h: Number(h), x: Number(x), y: Number(y) };
}

function parseLayout(input: string): Node {
  let i = 0;

  function parseNode(): Node {
    const rest = input.slice(i);
    const m = rest.match(/^([0-9]+)x([0-9]+),([0-9]+),([0-9]+)(?:,([0-9]+))?/);
    if (!m) throw new Error(`invalid layout node at ${i}: ${rest.slice(0, 40)}`);

    const rect = parseRectParts(m[1], m[2], m[3], m[4]);
    const paneId = m[5] ? `%${m[5]}` : null;
    i += m[0].length;

    if (input[i] === "{") {
      i++;
      const children = parseChildren("}");
      if (children.length !== 2) throw new Error("only binary row splits are supported in this prototype");
      return { type: "split", axis: "row", rect, children: [children[0], children[1]] };
    }
    if (input[i] === "[") {
      i++;
      const children = parseChildren("]");
      if (children.length !== 2) throw new Error("only binary col splits are supported in this prototype");
      return { type: "split", axis: "col", rect, children: [children[0], children[1]] };
    }

    if (!paneId) throw new Error(`pane id not found at ${i}: ${rest.slice(0, 40)}`);
    return { type: "leaf", pane: paneId, rect };
  }

  function parseChildren(end: string): Node[] {
    const out: Node[] = [];
    while (i < input.length && input[i] !== end) {
      out.push(parseNode());
      if (input[i] === ",") i++;
    }
    if (input[i] !== end) throw new Error(`missing ${end}`);
    i++;
    return out;
  }

  // tmux layout starts with a window checksum prefix like "bb62,237x61,..."
  const firstComma = input.indexOf(",");
  if (firstComma >= 0 && /^[0-9a-f]+$/.test(input.slice(0, firstComma))) {
    i = firstComma + 1;
  }
  return parseNode();
}

function nodeAt(root: Node, path: number[]): Node {
  let n = root;
  for (const p of path) {
    if (n.type === "leaf") return n;
    n = n.children[p];
  }
  return n;
}

function parentPath(path: number[]): number[] {
  return path.slice(0, -1);
}

function siblingPath(path: number[]): number[] {
  if (path.length === 0) return path;
  const out = path.slice();
  out[out.length - 1] = 1 - out[out.length - 1];
  return out;
}

function leaves(node: Node): Leaf[] {
  if (node.type === "leaf") return [node];
  return [...leaves(node.children[0]), ...leaves(node.children[1])];
}

function allNodes(node: Node, path: number[] = []): Array<{ node: Node; path: number[] }> {
  const out = [{ node, path }];
  if (node.type === "split") {
    out.push(...allNodes(node.children[0], [...path, 0]));
    out.push(...allNodes(node.children[1], [...path, 1]));
  }
  return out;
}

function firstLeaf(node: Node): Leaf {
  return leaves(node)[0];
}

function center(n: Node): { x: number; y: number } {
  return { x: n.rect.x + n.rect.w / 2, y: n.rect.y + n.rect.h / 2 };
}

function isPrefix(a: number[], b: number[]): boolean {
  return a.length <= b.length && a.every((v, i) => v === b[i]);
}

function compact(node: Node): string {
  if (node.type === "leaf") return node.pane;
  const op = node.axis === "row" ? "|" : "/";
  return `(${compact(node.children[0])}${op}${compact(node.children[1])})`;
}

function neighbor(root: Node, selectedPath: number[], dir: "h" | "j" | "k" | "l"): { node: Node; path: number[] } | null {
  const selected = nodeAt(root, selectedPath);
  const c = center(selected);
  const candidates = allNodes(root).filter(({ path }) => {
    if (path.join(",") === selectedPath.join(",")) return false;
    if (isPrefix(path, selectedPath) || isPrefix(selectedPath, path)) return false;
    return true;
  });

  const scored = candidates.map(({ node, path }) => {
    const n = center(node);
    const dx = n.x - c.x;
    const dy = n.y - c.y;
    if (dir === "h" && dx >= 0) return null;
    if (dir === "l" && dx <= 0) return null;
    if (dir === "k" && dy >= 0) return null;
    if (dir === "j" && dy <= 0) return null;
    const primary = dir === "h" || dir === "l" ? Math.abs(dx) : Math.abs(dy);
    const secondary = dir === "h" || dir === "l" ? Math.abs(dy) : Math.abs(dx);
    return { node, path, score: primary * 10 + secondary };
  }).filter((v): v is { node: Node; path: number[]; score: number } => !!v)
    .sort((a, b) => a.score - b.score);

  return scored[0] ?? null;
}

async function currentWindowId(): Promise<string> {
  return await tmux(["display-message", "-p", "#{session_id}:#{window_id}"]);
}

async function statePath(): Promise<string> {
  const base = Deno.env.get("XDG_RUNTIME_DIR") ?? "/tmp";
  const id = (await currentWindowId()).replace(/[^A-Za-z0-9_.:-]/g, "_");
  return `${base}/tmux-layout-paredit-${id}.json`;
}

async function loadState(): Promise<State> {
  const path = await statePath();
  try {
    const raw = await Deno.readTextFile(path);
    return JSON.parse(raw) as State;
  } catch {
    return { selectedPath: [], preselect: null, popups: [] };
  }
}

async function saveState(state: State): Promise<void> {
  await Deno.writeTextFile(await statePath(), JSON.stringify(state));
}

async function readTree(): Promise<Node> {
  const layout = await tmux(["display-message", "-p", "#{window_layout}"]);
  return parseLayout(layout);
}

async function currentPane(): Promise<string> {
  return await tmux(["display-message", "-p", "#{pane_id}"]);
}

function pathOfPane(root: Node, pane: string): number[] {
  const found = allNodes(root).find(({ node }) => node.type === "leaf" && node.pane === pane);
  return found?.path ?? [];
}

async function clearStyles(): Promise<void> {
  const panes = (await tmux(["list-panes", "-F", "#{pane_id}"])).split("\n").filter(Boolean);
  for (const p of panes) {
    await tmux(["set-option", "-upt", p, "window-style"]);
  }
}

async function clearPopups(state: State): Promise<void> {
  // Kill all popups running "true" (our dummy command)
  const panes = (await tmux(["list-panes", "-a", "-F", "#{pane_id}:#{pane_current_command}"]))
    .split("\n")
    .filter(Boolean)
    .filter((line) => line.endsWith(":true"));

  for (const line of panes) {
    const id = line.split(":")[0];
    await tmux(["kill-pane", "-t", id]);
  }
  state.popups = [];
}

async function paneRect(paneId: string): Promise<Rect | null> {
  const info = await tmux(["list-panes", "-t", paneId, "-F", "#{pane_left},#{pane_top},#{pane_width},#{pane_height}"]);
  const parts = info.split(",");
  if (parts.length !== 4) return null;
  return { x: Number(parts[0]), y: Number(parts[1]), w: Number(parts[2]), h: Number(parts[3]) };
}

async function nodeRect(node: Node): Promise<Rect | null> {
  if (node.type === "leaf") {
    return await paneRect(node.pane);
  }

  const childRects = await Promise.all([nodeRect(node.children[0]), nodeRect(node.children[1])]);
  const [a, b] = childRects;
  if (!a || !b) return a || b || null;

  return {
    x: Math.min(a.x, b.x),
    y: Math.min(a.y, b.y),
    w: Math.max(a.x + a.w, b.x + b.w) - Math.min(a.x, b.x),
    h: Math.max(a.y + a.h, b.y + b.h) - Math.min(a.y, b.y),
  };
}

async function drawFrame(state: State, rect: Rect, title: string, style: string): Promise<void> {
  // Skip small frames
  if (rect.w < 3 || rect.h < 2) return;

  await tmux([
    "display-popup",
    "-b", "rounded",
    "-h", rect.h.toString(),
    "-w", rect.w.toString(),
    "-x", rect.x.toString(),
    "-y", rect.y.toString(),
    "-T", title,
    "-S", style,
    "true",
  ]);
}

async function paint(root: Node, state: State): Promise<void> {
  const selected = nodeAt(root, state.selectedPath);
  const selectedLeaves = leaves(selected).map((l) => l.pane);
  const focus = await currentPane();
  await clearStyles();

  // Draw selection background
  for (const p of selectedLeaves) {
    await tmux(["set-option", "-pt", p, "window-style", `bg=${SELECT_BG}`]);
  }

  // Highlight focused pane
  if (selectedLeaves.includes(focus)) {
    await tmux(["set-option", "-pt", focus, "window-style", `bg=${FOCUS_BG}`]);
  }

  // Show preselect preview by tinting the relevant panes
  if (state.preselect) {
    const selectedRect = await nodeRect(selected);

    if (state.preselect === "v" && selectedRect) {
      // Tint right side: panes whose center is in the right half of selection
      const centerX = selectedRect.x + selectedRect.w / 2;
      for (const p of selectedLeaves) {
        const rect = await paneRect(p);
        if (rect && rect.x + rect.w / 2 > centerX) {
          await tmux(["set-option", "-pt", p, "window-style", `bg=#3a2a30`]); // Darker tint for preview
        }
      }
    } else if (state.preselect === "s" && selectedRect) {
      // Tint bottom side: panes whose center is in the bottom half of selection
      const centerY = selectedRect.y + selectedRect.h / 2;
      for (const p of selectedLeaves) {
        const rect = await paneRect(p);
        if (rect && rect.y + rect.h / 2 > centerY) {
          await tmux(["set-option", "-pt", p, "window-style", `bg=#3a2a30`]); // Darker tint for preview
        }
      }
    }
  }

  let msg = `selection: ${compact(selected)}  path=[${state.selectedPath.join(",")}]`;
  if (state.preselect) {
    const splitDesc = state.preselect === "v" ? "vertical (right)" : "horizontal (below)";
    msg += `  preselect=${state.preselect}  Enter to split ${splitDesc}`;
  }
  await tmux(["display-message", msg]);
}

async function selectPane(pane: string): Promise<void> {
  await tmux(["select-pane", "-t", pane]);
}

async function swapPane(a: string, b: string): Promise<void> {
  if (a === b) return;
  await tmux(["swap-pane", "-s", a, "-t", b]);
}

async function swapSubtree(root: Node, state: State, dir: "h" | "j" | "k" | "l"): Promise<void> {
  const a = nodeAt(root, state.selectedPath);
  const bHit = neighbor(root, state.selectedPath, dir);
  if (!bHit) return;
  const b = bHit.node;

  const aLeaves = leaves(a).sort(sortLeavesByGeometry);
  const bLeaves = leaves(b).sort(sortLeavesByGeometry);
  const n = Math.min(aLeaves.length, bLeaves.length);

  for (let i = 0; i < n; i++) {
    await swapPane(aLeaves[i].pane, bLeaves[i].pane);
  }
  state.selectedPath = bHit.path;
  await saveState(state);
}

function sortLeavesByGeometry(a: Leaf, b: Leaf): number {
  if (Math.abs(a.rect.y - b.rect.y) > 1) return a.rect.y - b.rect.y;
  return a.rect.x - b.rect.x;
}

async function flipSelected(root: Node, state: State): Promise<void> {
  const n = nodeAt(root, state.selectedPath);
  if (n.type === "leaf") return;
  const a = leaves(n.children[0]).sort(sortLeavesByGeometry);
  const b = leaves(n.children[1]).sort(sortLeavesByGeometry);
  const count = Math.min(a.length, b.length);
  for (let i = 0; i < count; i++) await swapPane(a[i].pane, b[i].pane);
}

async function growChild(root: Node, state: State, child: 0 | 1): Promise<void> {
  const n = nodeAt(root, state.selectedPath);
  if (n.type === "leaf") return;

  const target = firstLeaf(n.children[child]).pane;
  // tmux resize direction is applied to a pane edge.  This is an approximation but works well for normal binary splits.
  if (n.axis === "row") {
    await tmux(["resize-pane", "-t", target, child === 0 ? "-R" : "-L", String(STEP)]);
  } else {
    await tmux(["resize-pane", "-t", target, child === 0 ? "-D" : "-U", String(STEP)]);
  }
}

async function splitSelected(root: Node, state: State): Promise<void> {
  if (!state.preselect) {
    await tmux(["display-message", "split ignored: press v or s first"]);
    return;
  }
  const selected = nodeAt(root, state.selectedPath);
  const target = firstLeaf(selected).pane;
  const flag = state.preselect === "row" ? "-h" : "-v";
  await tmux(["split-window", flag, "-t", target]);
  state.preselect = null;
  await saveState(state);
}

async function main() {
  const cmd = Deno.args[0] ?? "paint";
  const root = await readTree();
  const state = await loadState();

  switch (cmd) {
    case "enter": {
      state.selectedPath = pathOfPane(root, await currentPane());
      state.preselect = null;
      break;
    }
    case "select-focus": {
      state.selectedPath = pathOfPane(root, await currentPane());
      break;
    }
    case "parent": {
      if (state.selectedPath.length > 0) state.selectedPath = parentPath(state.selectedPath);
      break;
    }
    case "child0": {
      const n = nodeAt(root, state.selectedPath);
      if (n.type === "split") state.selectedPath = [...state.selectedPath, 0];
      break;
    }
    case "child1": {
      const n = nodeAt(root, state.selectedPath);
      if (n.type === "split") state.selectedPath = [...state.selectedPath, 1];
      break;
    }
    case "sibling": {
      state.selectedPath = siblingPath(state.selectedPath);
      break;
    }
    case "pre-v": {
      // Only allow preselect on leaf nodes (single pane selection)
      const root = await readTree();
      const selected = nodeAt(root, state.selectedPath);
      if (selected.type === "split") {
        await tmux(["display-message", "preselect: only available on single pane (use u/1/2 to select a leaf)"]);
        await saveState(state);
        await paint(root, state);
        break;
      }
      state.preselect = "row";
      break;
    }
    case "pre-s": {
      // Only allow preselect on leaf nodes (single pane selection)
      const root = await readTree();
      const selected = nodeAt(root, state.selectedPath);
      if (selected.type === "split") {
        await tmux(["display-message", "preselect: only available on single pane (use u/1/2 to select a leaf)"]);
        await saveState(state);
        await paint(root, state);
        break;
      }
      state.preselect = "col";
      break;
    }
    case "cancel": {
      state.preselect = null;
      break;
    }
    case "split": {
      await splitSelected(root, state);
      break;
    }
    case "flip": {
      await flipSelected(root, state);
      break;
    }
    case "swap-left": await swapSubtree(root, state, "h"); break;
    case "swap-down": await swapSubtree(root, state, "j"); break;
    case "swap-up": await swapSubtree(root, state, "k"); break;
    case "swap-right": await swapSubtree(root, state, "l"); break;
    case "grow0": await growChild(root, state, 0); break;
    case "grow1": await growChild(root, state, 1); break;
    case "clear": {
      await clearStyles();
      state.preselect = null;
      await saveState(state);
      return;
    }
  }

  await saveState(state);
  const updatedRoot = await readTree();
  await paint(updatedRoot, state);
}

if (import.meta.main) {
  main().catch(async (e) => {
    await tmux(["display-message", `layout-paredit error: ${e.message}`]).catch(() => {});
    console.error(e);
    Deno.exit(1);
  });
}
