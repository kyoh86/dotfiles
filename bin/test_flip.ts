#!/usr/bin/env -S deno run --allow-run

// Test flip operation logic with position-based mapping

type Leaf = {
  pane: string;
  x: number;
  y: number;
};

function sortLeavesByGeometry(a: Leaf, b: Leaf): number {
  if (Math.abs(a.y - b.y) > 1) return a.y - b.y;
  return a.x - b.x;
}

// Simulate flip with position-based mapping
function flipWithPositionMapping(originalLeaves: Leaf[], newLeaves: Leaf[]): { pass: boolean; finalOrder: string } {
  const allOriginal = [...originalLeaves].sort(sortLeavesByGeometry);
  const allNew = [...newLeaves].sort(sortLeavesByGeometry);

  console.log(`Original leaves (sorted): ${allOriginal.map(l => l.pane).join(", ")}`);
  console.log(`New leaves (sorted): ${allNew.map(l => l.pane).join(", ")}`);

  // Track content at each position (initially: content[i] is at position i)
  const contentAt = allOriginal.map(l => l.pane);

  // Simulate swap operations
  for (let i = 0; i < Math.min(allOriginal.length, allNew.length); i++) {
    const originalPane = allOriginal[i].pane;
    const newPane = allNew[i].pane;
    if (originalPane !== newPane) {
      console.log(`  swap ${originalPane} -> ${newPane} (position ${i})`);
      // Find where newPane's content is currently
      const newPaneContentIdx = contentAt.indexOf(newPane);
      // Swap content at position i with content at newPane's position
      [contentAt[i], contentAt[newPaneContentIdx]] = [contentAt[newPaneContentIdx], contentAt[i]];
    }
  }

  const finalOrder = contentAt.join(", ");
  const expected = allNew.map(l => l.pane).join(", ");
  console.log(`Final content by position: ${finalOrder}`);
  console.log(`Expected: ${expected}`);
  const pass = finalOrder === expected;
  console.log(`Pass? ${pass}`);
  console.log("");
  return { pass, finalOrder };
}

// Test 1: [A, [B, C]] → [[B, C], A]
// Geometry: A at (0,0), B at (50,0), C at (50,30)
// After flip: B at (0,0), C at (0,30), A at (50,0)
console.log("=== Test 1: [A, [B, C]] → [[B, C], A] ===");
const test1Original: Leaf[] = [
  { pane: "A", x: 0, y: 0 },
  { pane: "B", x: 50, y: 0 },
  { pane: "C", x: 50, y: 30 },
];
const test1New: Leaf[] = [
  { pane: "B", x: 0, y: 0 },
  { pane: "C", x: 0, y: 30 },
  { pane: "A", x: 50, y: 0 },
];
flipWithPositionMapping(test1Original, test1New);

// Test 2: [[B, C], A] → [A, [B, C]] (reverse)
console.log("=== Test 2: [[B, C], A] → [A, [B, C]] (back to original) ===");
const test2Original: Leaf[] = [
  { pane: "B", x: 0, y: 0 },
  { pane: "C", x: 0, y: 30 },
  { pane: "A", x: 50, y: 0 },
];
const test2New: Leaf[] = [
  { pane: "A", x: 0, y: 0 },
  { pane: "B", x: 50, y: 0 },
  { pane: "C", x: 50, y: 30 },
];
flipWithPositionMapping(test2Original, test2New);

// Test 3: Equal length [[A,B],[C,D]] → [[C,D],[A,B]]
console.log("=== Test 3: Equal length [[A,B],[C,D]] → [[C,D],[A,B]] ===");
const test3Original: Leaf[] = [
  { pane: "A", x: 0, y: 0 },
  { pane: "B", x: 0, y: 30 },
  { pane: "C", x: 50, y: 0 },
  { pane: "D", x: 50, y: 30 },
];
const test3New: Leaf[] = [
  { pane: "C", x: 0, y: 0 },
  { pane: "D", x: 0, y: 30 },
  { pane: "A", x: 50, y: 0 },
  { pane: "B", x: 50, y: 30 },
];
flipWithPositionMapping(test3Original, test3New);

// Test 4: Reverse equal length [[C,D],[A,B]] → [[A,B],[C,D]]
console.log("=== Test 4: [[C,D],[A,B]] → [[A,B],[C,D]] (back to original) ===");
const test4Original: Leaf[] = [
  { pane: "C", x: 0, y: 0 },
  { pane: "D", x: 0, y: 30 },
  { pane: "A", x: 50, y: 0 },
  { pane: "B", x: 50, y: 30 },
];
const test4New: Leaf[] = [
  { pane: "A", x: 0, y: 0 },
  { pane: "B", x: 0, y: 30 },
  { pane: "C", x: 50, y: 0 },
  { pane: "D", x: 50, y: 30 },
];
flipWithPositionMapping(test4Original, test4New);
