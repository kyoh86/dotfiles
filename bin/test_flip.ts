#!/usr/bin/env -S deno run --allow-run

// Test flip operation logic

type Leaf = {
  pane: string;
};

// Test equal length case with pair-wise swap
function testEqualLength() {
  console.log("=== Test 1: Equal length [[A,B],[C,D]] → [[C,D],[A,B]] ===");
  const leftLeaves = [{ pane: "A" }, { pane: "B" }];
  const rightLeaves = [{ pane: "C" }, { pane: "D" }];

  const contentAt = ["A", "B", "C", "D"]; // Simulating: left[0]=A, left[1]=B, right[0]=C, right[1]=D

  // Pair-wise swap
  for (let i = 0; i < leftLeaves.length; i++) {
    const leftPane = leftLeaves[i].pane;
    const rightPane = rightLeaves[i].pane;
    console.log(`  swap left[${i}] ${leftPane} <-> right[${i}] ${rightPane}`);
    // Find indices and swap
    const leftIdx = contentAt.indexOf(leftPane);
    const rightIdx = contentAt.indexOf(rightPane);
    [contentAt[leftIdx], contentAt[rightIdx]] = [contentAt[rightIdx], contentAt[leftIdx]];
  }

  console.log(`Final: ${contentAt.join(", ")}`);
  console.log(`Expected: C, D, A, B`);
  console.log(`Pass? ${contentAt.join(",") === "C,D,A,B"}`);
  console.log("");
}

// Test unequal length case with cycle-based swap
function testUnequalLength() {
  console.log("=== Test 2: Unequal length [A, [B,C]] → [[B,C], A] ===");
  const leftLeaves = [{ pane: "A" }];
  const rightLeaves = [{ pane: "B" }, { pane: "C" }];

  // After flip: left=[B,C], right=[A]
  const newLeftLeaves = [{ pane: "B" }, { pane: "C" }];
  const newRightLeaves = [{ pane: "A" }];
  const newLeaves = [...newLeftLeaves, ...newRightLeaves];

  const allLeaves = [...leftLeaves, ...rightLeaves];

  // Build mapping: original pane -> new position index
  const paneToNewIdx = new Map<string, number>();
  for (let i = 0; i < newLeaves.length; i++) {
    paneToNewIdx.set(newLeaves[i].pane, i);
  }

  const targetAt = new Array(allLeaves.length).fill(null);
  for (let i = 0; i < allLeaves.length; i++) {
    const originalPane = allLeaves[i].pane;
    const targetIdx = paneToNewIdx.get(originalPane);
    if (targetIdx !== undefined) {
      targetAt[i] = targetIdx;
    }
  }

  console.log(`All leaves: ${allLeaves.map(l => l.pane).join(", ")}`);
  console.log(`New leaves: ${newLeaves.map(l => l.pane).join(", ")}`);
  console.log(`Target mapping: ${targetAt.map((t, i) => `${allLeaves[i].pane}->${t !== null ? newLeaves[t].pane : "?"}`).join(", ")}`);

  // Perform swaps using cycle decomposition
  const visited = new Set<number>();
  const contentAt = [...allLeaves.map(l => l.pane)];

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
      // Rotate the cycle
      const temp = contentAt[cycle[cycle.length - 1]];
      for (let j = cycle.length - 1; j > 0; j--) {
        contentAt[cycle[j]] = contentAt[cycle[j - 1]];
      }
      contentAt[cycle[0]] = temp;
      console.log(`After rotation: ${contentAt.join(", ")}`);
    }
  }

  console.log(`Final: ${contentAt.join(", ")}`);
  console.log(`Expected: B, C, A`);
  console.log(`Pass? ${contentAt.join(",") === "B,C,A"}`);
  console.log("");
}

// Test reverse unequal length
function testUnequalLengthReverse() {
  console.log("=== Test 3: Reverse [[B,C], A] → [A, [B,C]] ===");
  const leftLeaves = [{ pane: "B" }, { pane: "C" }];
  const rightLeaves = [{ pane: "A" }];

  // After flip: left=[A], right=[B,C]
  const newLeftLeaves = [{ pane: "A" }];
  const newRightLeaves = [{ pane: "B" }, { pane: "C" }];
  const newLeaves = [...newLeftLeaves, ...newRightLeaves];

  const allLeaves = [...leftLeaves, ...rightLeaves];

  const paneToNewIdx = new Map<string, number>();
  for (let i = 0; i < newLeaves.length; i++) {
    paneToNewIdx.set(newLeaves[i].pane, i);
  }

  const targetAt = new Array(allLeaves.length).fill(null);
  for (let i = 0; i < allLeaves.length; i++) {
    const originalPane = allLeaves[i].pane;
    const targetIdx = paneToNewIdx.get(originalPane);
    if (targetIdx !== undefined) {
      targetAt[i] = targetIdx;
    }
  }

  console.log(`All leaves: ${allLeaves.map(l => l.pane).join(", ")}`);
  console.log(`New leaves: ${newLeaves.map(l => l.pane).join(", ")}`);
  console.log(`Target mapping: ${targetAt.map((t, i) => `${allLeaves[i].pane}->${t !== null ? newLeaves[t].pane : "?"}`).join(", ")}`);

  const visited = new Set<number>();
  const contentAt = [...allLeaves.map(l => l.pane)];

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
      const temp = contentAt[cycle[cycle.length - 1]];
      for (let j = cycle.length - 1; j > 0; j--) {
        contentAt[cycle[j]] = contentAt[cycle[j - 1]];
      }
      contentAt[cycle[0]] = temp;
      console.log(`After rotation: ${contentAt.join(", ")}`);
    }
  }

  console.log(`Final: ${contentAt.join(", ")}`);
  console.log(`Expected: A, B, C`);
  console.log(`Pass? ${contentAt.join(",") === "A,B,C"}`);
  console.log("");
}

testEqualLength();
testUnequalLength();
testUnequalLengthReverse();
