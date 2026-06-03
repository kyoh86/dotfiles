#!/usr/bin/env -S deno run --allow-run

// Test flip operation logic

type Leaf = {
  pane: string;
};

function swap(arr: Leaf[], i: number, j: number): Leaf[] {
  const result = [...arr];
  const temp = result[i];
  result[i] = result[j];
  result[j] = temp;
  return result;
}

// Correct logic: swap halves (preserving order within each half)
// left[0] <-> right[0], left[1] <-> right[1], etc.
function swapHalves(leftLeaves: Leaf[], rightLeaves: Leaf[]): { leftLeaves: Leaf[], rightLeaves: Leaf[] } {
  const allLeaves = [...leftLeaves, ...rightLeaves];
  console.log(`Before: ${allLeaves.map(l => l.pane).join(", ")}`);

  const result = [...allLeaves];
  const count = Math.min(leftLeaves.length, rightLeaves.length);

  for (let i = 0; i < count; i++) {
    const leftIdx = i;                      // left[i]
    const rightIdx = leftLeaves.length + i;  // right[i]
    console.log(`  swap(${leftIdx}, ${rightIdx}): ${result[leftIdx].pane} <-> ${result[rightIdx].pane}`);
    const temp = result[leftIdx];
    result[leftIdx] = result[rightIdx];
    result[rightIdx] = temp;
  }

  console.log(`After: ${result.map(l => l.pane).join(", ")}`);

  return {
    leftLeaves: result.slice(0, leftLeaves.length),
    rightLeaves: result.slice(leftLeaves.length),
  };
}

console.log("=== Test 1: [A, [B, C]] → [[B, C], A] ===");
console.log("Expected: left=[B, C], right=[A]");
let result1 = swapHalves(
  [{ pane: "A" }],
  [{ pane: "B" }, { pane: "C" }]
);
console.log(`Result: left=[${result1.leftLeaves.map(l => l.pane).join(", ")}], right=[${result1.rightLeaves.map(l => l.pane).join(", ")}]`);
console.log(`Pass? ${result1.leftLeaves.map(l => l.pane).join(",") === "B,C" && result1.rightLeaves.map(l => l.pane).join(",") === "A"}`);

console.log("\n=== Test 2: [[B, C], A] → [A, [B, C]] ===");
console.log("Expected: left=[A], right=[B, C]");
let result2 = swapHalves(
  [{ pane: "B" }, { pane: "C" }],
  [{ pane: "A" }]
);
console.log(`Result: left=[${result2.leftLeaves.map(l => l.pane).join(", ")}], right=[${result2.rightLeaves.map(l => l.pane).join(", ")}]`);
console.log(`Pass? ${result2.leftLeaves.map(l => l.pane).join(",") === "A" && result2.rightLeaves.map(l => l.pane).join(",") === "B,C"}`);

console.log("\n=== Test 3: [[A, B], C] → [C, [A, B]] ===");
console.log("Expected: left=[C], right=[A, B]");
let result3 = swapHalves(
  [{ pane: "A" }, { pane: "B" }],
  [{ pane: "C" }]
);
console.log(`Result: left=[${result3.leftLeaves.map(l => l.pane).join(", ")}], right=[${result3.rightLeaves.map(l => l.pane).join(", ")}]`);
console.log(`Pass? ${result3.leftLeaves.map(l => l.pane).join(",") === "C" && result3.rightLeaves.map(l => l.pane).join(",") === "A,B"}`);

console.log("\n=== Test 4: [C, [A, B]] → [[A, B], C] ===");
console.log("Expected: left=[A, B], right=[C]");
let result4 = swapHalves(
  [{ pane: "C" }],
  [{ pane: "A" }, { pane: "B" }]
);
console.log(`Result: left=[${result4.leftLeaves.map(l => l.pane).join(", ")}], right=[${result4.rightLeaves.map(l => l.pane).join(", ")}]`);
console.log(`Pass? ${result4.leftLeaves.map(l => l.pane).join(",") === "A,B" && result4.rightLeaves.map(l => l.pane).join(",") === "C"}`);

console.log("\n=== Test 5: [[A, B], [C, D]] (equal length) ===");
console.log("Expected: left=[C, D], right=[A, B]");
let result5 = swapHalves(
  [{ pane: "A" }, { pane: "B" }],
  [{ pane: "C" }, { pane: "D" }]
);
console.log(`Result: left=[${result5.leftLeaves.map(l => l.pane).join(", ")}], right=[${result5.rightLeaves.map(l => l.pane).join(", ")}]`);
console.log(`Pass? ${result5.leftLeaves.map(l => l.pane).join(",") === "C,D" && result5.rightLeaves.map(l => l.pane).join(",") === "A,B"}`);
