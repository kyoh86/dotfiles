# tmux-layout-paredit prototype

`prefix + C-w` で tmux の pane/subtree 操作用サブモードに入り、HTML デモに近い操作を tmux 上で試すための MVP 実装です。

この版の方針:

* `selection = leaf | subtree` を外部 state として保持
* tmux の現在 pane 配置を `#{window_layout}` から読み、tree として扱う
* 選択 subtree に含まれる pane を `window-style` で tint
* focus leaf と selection は分離
* `u` / `1` / `2` / `o` で selection 移動
* `H/J/K/L` で選択 subtree と隣接 subtree を swap
* `f` で選択 subtree の child を flip
* `[` / `]` で選択 split の child 比率を調整
* `v` / `s` で split 予約、`Enter` で実行、`Escape` でキャンセル

制約:

* subtree swap は「subtree 内 leaf の pane 内容を swap する」方式です。形が同じ subtree 間では自然に見えます。形が違う場合も leaf の重心順で対応づけますが、完全な tree reparent ではありません。
* `rotate` は tmux の実 layout を安全に回転するのが重いため、この MVP では未実装です。
* Neovim 側は `Normal` 背景を `NONE` にしておくと tint が見えます。

---

## 1. `~/.tmux/bin/layout-paredit.ts`

```ts
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
    return { selectedPath: [], preselect: null };
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

async function paint(root: Node, state: State): Promise<void> {
  const selected = nodeAt(root, state.selectedPath);
  const selectedLeaves = leaves(selected).map((l) => l.pane);
  const focus = await currentPane();
  await clearStyles();
  for (const p of selectedLeaves) {
    await tmux(["set-option", "-pt", p, "window-style", `bg=${SELECT_BG}`]);
  }
  if (selectedLeaves.includes(focus)) {
    await tmux(["set-option", "-pt", focus, "window-style", `bg=${FOCUS_BG}`]);
  }
  await tmux(["display-message", `selection: ${compact(selected)}  path=[${state.selectedPath.join(",")}]${state.preselect ? `  preselect=${state.preselect}` : ""}`]);
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
      state.preselect = "row";
      break;
    }
    case "pre-s": {
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
```

---

## 2. `~/.tmux.conf`

```tmux
# layout-paredit command
set -g @layout_paredit 'deno run --allow-run --allow-read --allow-write --allow-env ~/.tmux/bin/layout-paredit.ts'

# Enter submode with prefix + C-w
bind-key C-w run-shell '#{@layout_paredit} enter' \; switch-client -T layout-paredit

# Keep submode alive after most operations.
bind-key -T layout-paredit u run-shell '#{@layout_paredit} parent' \; switch-client -T layout-paredit
bind-key -T layout-paredit 1 run-shell '#{@layout_paredit} child0' \; switch-client -T layout-paredit
bind-key -T layout-paredit 2 run-shell '#{@layout_paredit} child1' \; switch-client -T layout-paredit
bind-key -T layout-paredit o run-shell '#{@layout_paredit} sibling' \; switch-client -T layout-paredit
bind-key -T layout-paredit . run-shell '#{@layout_paredit} select-focus' \; switch-client -T layout-paredit

# split preselection
bind-key -T layout-paredit v run-shell '#{@layout_paredit} pre-v' \; switch-client -T layout-paredit
bind-key -T layout-paredit s run-shell '#{@layout_paredit} pre-s' \; switch-client -T layout-paredit
bind-key -T layout-paredit Enter run-shell '#{@layout_paredit} split' \; switch-client -T layout-paredit
bind-key -T layout-paredit Escape run-shell '#{@layout_paredit} cancel' \; switch-client -T layout-paredit

# subtree operations
bind-key -T layout-paredit f run-shell '#{@layout_paredit} flip' \; switch-client -T layout-paredit
bind-key -T layout-paredit H run-shell '#{@layout_paredit} swap-left' \; switch-client -T layout-paredit
bind-key -T layout-paredit J run-shell '#{@layout_paredit} swap-down' \; switch-client -T layout-paredit
bind-key -T layout-paredit K run-shell '#{@layout_paredit} swap-up' \; switch-client -T layout-paredit
bind-key -T layout-paredit L run-shell '#{@layout_paredit} swap-right' \; switch-client -T layout-paredit

# selected split ratio
bind-key -T layout-paredit [ run-shell '#{@layout_paredit} grow0' \; switch-client -T layout-paredit
bind-key -T layout-paredit ] run-shell '#{@layout_paredit} grow1' \; switch-client -T layout-paredit

# leave mode and clear tint
bind-key -T layout-paredit q run-shell '#{@layout_paredit} clear'
bind-key -T layout-paredit C-c run-shell '#{@layout_paredit} clear'
```

---

## 3. Neovim 側の背景透過例

```vim
highlight Normal guibg=NONE ctermbg=NONE
highlight NormalNC guibg=NONE ctermbg=NONE
highlight EndOfBuffer guibg=NONE ctermbg=NONE
```

Lua なら:

```lua
vim.api.nvim_set_hl(0, "Normal", { bg = "NONE" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "NONE" })
vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "NONE" })
```

---

## 4. 操作イメージ

`prefix + C-w` で submode に入ります。

```text
u       select parent subtree
1 / 2   select child[0] / child[1]
o       select sibling
.       select current focused leaf

v       preselect side-by-side split
s       preselect stacked split
Enter   split selected subtree's first leaf
Esc     cancel split preselection

f       flip selected subtree
H/J/K/L swap selected subtree with neighbor
[ / ]   grow child[0] / child[1]
q       quit mode and clear tint
```

---

## 5. まず試す形

```sh
mkdir -p ~/.tmux/bin
chmod +x ~/.tmux/bin/layout-paredit.ts
```

`~/.tmux.conf` を読み直します。

```sh
tmux source-file ~/.tmux.conf
```

適当に 4 pane 作ってから:

```text
prefix + C-w
u
L
```

で subtree selection と swap の挙動を見ます。
