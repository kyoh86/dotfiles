#!/usr/bin/env -S deno run --allow-run

// Test cycle-based swap for unequal length

type Leaf = { pane: string };

function simulateSwap(paneA: string, paneB: string, panes: string[]): void {
  const idxA = panes.indexOf(paneA);
  const idxB = panes.indexOf(paneB);
  if (idxA >= 0 && idxB >= 0) {
    [panes[idxA], panes[idxB]] = [panes[idxB], panes[idxA]];
  }
}

function testUnequalLength() {
  console.log("=== Test 1: [A, [B,C]] → [[B,C], A] ===");
  const allLeaves = [{ pane: "A" }, { pane: "B" }, { pane: "C" }];
  const newLeaves = [{ pane: "B" }, { pane: "C" }, { pane: "A" }];

  const panes = allLeaves.map(l => l.pane);
  console.log(`Before: ${panes.join(", ")}`);
  console.log(`Expected: ${newLeaves.map(l => l.pane).join(", ")}`);

  // Build mapping
  const targetAt: (number | null)[] = [];
  for (let i = 0; i < allLeaves.length; i++) {
    const paneId = allLeaves[i].pane;
    const targetIdx = newLeaves.findIndex(l => l.pane === paneId);
    targetAt[i] = targetIdx >= 0 ? targetIdx : null;
  }

  console.log(`Target mapping: ${targetAt.map((t, i) => `${allLeaves[i].pane}->pos${t}`).join(", ")}`);

  // Perform swaps using cycle decomposition
  const visited = new Set<number>();
  for (let i = 0; i < allLeaves.length; i++) {
    if (visited.has(i)) continue;
    const cycle: number[] = [];
    let current = i;
    while (current !== null && !visited.has(current) && targetAt[current] !== null) {
      cycle.push(current);
      visited.add(current);
      const next = targetAt[current];
      if (next === cycle[0]) break;
      current = next;
    }

    if (cycle.length > 1) {
      console.log(`Cycle: ${cycle.map(c => allLeaves[c].pane).join(" -> ")}`);
      const tempPane = allLeaves[cycle[cycle.length - 1]].pane;
      for (let j = cycle.length - 1; j > 0; j--) {
        const fromPane = allLeaves[cycle[j - 1]].pane;
        console.log(`  swap ${fromPane} -> ${tempPane}`);
        simulateSwap(fromPane, tempPane, panes);
      }
      console.log(`  After cycle: ${panes.join(", ")}`);
    }
  }

  console.log(`Final: ${panes.join(", ")}`);
  console.log(`Pass? ${panes.join(",") === newLeaves.map(l => l.pane).join(",")}`);
  console.log("");
}

function testUnequalLengthReverse() {
  console.log("=== Test 2: [[B,C], A] → [A, [B,C]] ===");
  const allLeaves = [{ pane: "B" }, { pane: "C" }, { pane: "A" }];
  const newLeaves = [{ pane: "A" }, { pane: "B" }, { pane: "C" }];

  const panes = allLeaves.map(l => l.pane);
  console.log(`Before: ${panes.join(", ")}`);
  console.log(`Expected: ${newLeaves.map(l => l.pane).join(", ")}`);

  const targetAt: (number | null)[] = [];
  for (let i = 0; i < allLeaves.length; i++) {
    const paneId = allLeaves[i].pane;
    const targetIdx = newLeaves.findIndex(l => l.pane === paneId);
    targetAt[i] = targetIdx >= 0 ? targetIdx : null;
  }

  console.log(`Target mapping: ${targetAt.map((t, i) => `${allLeaves[i].pane}->pos${t}`).join(", ")}`);

  const visited = new Set<number>();
  for (let i = 0; i < allLeaves.length; i++) {
    if (visited.has(i)) continue;
    const cycle: number[] = [];
    let current = i;
    while (current !== null && !visited.has(current) && targetAt[current] !== null) {
      cycle.push(current);
      visited.add(current);
      const next = targetAt[current];
      if (next === cycle[0]) break;
      current = next;
    }

    if (cycle.length > 1) {
      console.log(`Cycle: ${cycle.map(c => allLeaves[c].pane).join(" -> ")}`);
      const tempPane = allLeaves[cycle[cycle.length - 1]].pane;
      for (let j = cycle.length - 1; j > 0; j--) {
        const fromPane = allLeaves[cycle[j - 1]].pane;
        console.log(`  swap ${fromPane} -> ${tempPane}`);
        simulateSwap(fromPane, tempPane, panes);
      }
      console.log(`  After cycle: ${panes.join(", ")}`);
    }
  }

  console.log(`Final: ${panes.join(", ")}`);
  console.log(`Pass? ${panes.join(",") === newLeaves.map(l => l.pane).join(",")}`);
  console.log("");
}

function testEqualLength() {
  console.log("=== Test 3: Equal length [[A,B],[C,D]] → [[C,D],[A,B]] ===");
  const allLeaves = [{ pane: "A" }, { pane: "B" }, { pane: "C" }, { pane: "D" }];
  const newLeaves = [{ pane: "C" }, { pane: "D" }, { pane: "A" }, { pane: "B" }];

  const panes = allLeaves.map(l => l.pane);
  console.log(`Before: ${panes.join(", ")}`);
  console.log(`Expected: ${newLeaves.map(l => l.pane).join(", ")}`);

  const targetAt: (number | null)[] = [];
  for (let i = 0; i < allLeaves.length; i++) {
    const paneId = allLeaves[i].pane;
    const targetIdx = newLeaves.findIndex(l => l.pane === paneId);
    targetAt[i] = targetIdx >= 0 ? targetIdx : null;
  }

  console.log(`Target mapping: ${targetAt.map((t, i) => `${allLeaves[i].pane}->pos${t}`).join(", ")}`);

  const visited = new Set<number>();
  for (let i = 0; i < allLeaves.length; i++) {
    if (visited.has(i)) continue;
    const cycle: number[] = [];
    let current = i;
    while (current !== null && !visited.has(current) && targetAt[current] !== null) {
      cycle.push(current);
      visited.add(current);
      const next = targetAt[current];
      if (next === cycle[0]) break;
      current = next;
    }

    if (cycle.length > 1) {
      console.log(`Cycle: ${cycle.map(c => allLeaves[c].pane).join(" -> ")}`);
      const tempPane = allLeaves[cycle[cycle.length - 1]].pane;
      for (let j = cycle.length - 1; j > 0; j--) {
        const fromPane = allLeaves[cycle[j - 1]].pane;
        console.log(`  swap ${fromPane} -> ${tempPane}`);
        simulateSwap(fromPane, tempPane, panes);
      }
      console.log(`  After cycle: ${panes.join(", ")}`);
    }
  }

  console.log(`Final: ${panes.join(", ")}`);
  console.log(`Pass? ${panes.join(",") === newLeaves.map(l => l.pane).join(",")}`);
  console.log("");
}

testUnequalLength();
testUnequalLengthReverse();
testEqualLength();
