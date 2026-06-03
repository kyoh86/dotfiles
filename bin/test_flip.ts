#!/usr/bin/env -S deno run --allow-run

// Test simplified flip logic

type Leaf = { pane: string };

function testEqualLength() {
  console.log("=== Test 1: Equal length [[A,B],[C,D]] → [[C,D],[A,B]] ===");
  const leftLeaves = [{ pane: "A" }, { pane: "B" }];
  const rightLeaves = [{ pane: "C" }, { pane: "D" }];

  const allPanes = [...leftLeaves, ...rightLeaves].map(l => l.pane);
  console.log(`All panes: ${allPanes.join(", ")}`);

  const newLeftCount = rightLeaves.length;  // 2
  const newRightCount = leftLeaves.length; // 2

  // After layout change, the structure is flipped
  // But pane IDs stay at original positions, so:
  // newLeftLeaves = [A, B] (pane IDs that are now in left subtree)
  // newRightLeaves = [C, D] (pane IDs that are now in right subtree)
  const newLeftLeaves = [{ pane: "A" }, { pane: "B" }];
  const newRightLeaves = [{ pane: "C" }, { pane: "D" }];

  for (let i = 0; i < allPanes.length; i++) {
    const sourcePane = allPanes[i];
    let targetPane: string | null = null;

    if (i < newLeftCount) {
      targetPane = newLeftLeaves[i]?.pane ?? null;
    } else {
      targetPane = newRightLeaves[i - newLeftCount]?.pane ?? null;
    }

    if (targetPane && sourcePane !== targetPane) {
      console.log(`  swap ${sourcePane} -> ${targetPane}`);
      // Simulate swap
      const allIdx = allPanes.indexOf(sourcePane);
      const targetIdx = allPanes.indexOf(targetPane);
      [allPanes[allIdx], allPanes[targetIdx]] = [allPanes[targetIdx], allPanes[allIdx]];
    }
  }

  console.log(`Final allPanes: ${allPanes.join(", ")}`);
  console.log(`Expected distribution: left=[C,D], right=[A,B]`);
  console.log(`Pass? ${allPanes.slice(0, 2).join(",") === "C,D" && allPanes.slice(2).join(",") === "A,B"}`);
  console.log("");
}

function testUnequalLength() {
  console.log("=== Test 2: Unequal length [A, [B,C]] → [[B,C], A] ===");
  const leftLeaves = [{ pane: "A" }];
  const rightLeaves = [{ pane: "B" }, { pane: "C" }];

  const allPanes = [...leftLeaves, ...rightLeaves].map(l => l.pane);
  console.log(`All panes: ${allPanes.join(", ")}`);

  const newLeftCount = rightLeaves.length;  // 2
  const newRightCount = leftLeaves.length; // 1

  // After layout change, pane IDs stay at original positions:
  // newLeftLeaves = [A] (A was in left, still in left structurally)
  // newRightLeaves = [B, C] (B,C were in right, still in right structurally)
  const newLeftLeaves = [{ pane: "A" }];
  const newRightLeaves = [{ pane: "B" }, { pane: "C" }];

  for (let i = 0; i < allPanes.length; i++) {
    const sourcePane = allPanes[i];
    let targetPane: string | null = null;

    if (i < newLeftCount) {
      targetPane = newLeftLeaves[i]?.pane ?? null;
    } else {
      targetPane = newRightLeaves[i - newLeftCount]?.pane ?? null;
    }

    if (targetPane && sourcePane !== targetPane) {
      console.log(`  swap ${sourcePane} -> ${targetPane}`);
      const allIdx = allPanes.indexOf(sourcePane);
      const targetIdx = allPanes.indexOf(targetPane);
      [allPanes[allIdx], allPanes[targetIdx]] = [allPanes[targetIdx], allPanes[allIdx]];
    }
  }

  console.log(`Final allPanes: ${allPanes.join(", ")}`);
  console.log(`Expected distribution: left=[B,C], right=[A]`);
  console.log(`Pass? ${allPanes.slice(0, 2).join(",") === "B,C" && allPanes.slice(2).join(",") === "A"}`);
  console.log("");
}

function testUnequalLengthReverse() {
  console.log("=== Test 3: Reverse [[B,C], A] → [A, [B,C]] ===");
  const leftLeaves = [{ pane: "B" }, { pane: "C" }];
  const rightLeaves = [{ pane: "A" }];

  const allPanes = [...leftLeaves, ...rightLeaves].map(l => l.pane);
  console.log(`All panes: ${allPanes.join(", ")}`);

  const newLeftCount = rightLeaves.length;  // 1
  const newRightCount = leftLeaves.length; // 2

  // After layout change:
  // newLeftLeaves = [B, C] (still in left structurally)
  // newRightLeaves = [A] (still in right structurally)
  const newLeftLeaves = [{ pane: "B" }, { pane: "C" }];
  const newRightLeaves = [{ pane: "A" }];

  for (let i = 0; i < allPanes.length; i++) {
    const sourcePane = allPanes[i];
    let targetPane: string | null = null;

    if (i < newLeftCount) {
      targetPane = newLeftLeaves[i]?.pane ?? null;
    } else {
      targetPane = newRightLeaves[i - newLeftCount]?.pane ?? null;
    }

    if (targetPane && sourcePane !== targetPane) {
      console.log(`  swap ${sourcePane} -> ${targetPane}`);
      const allIdx = allPanes.indexOf(sourcePane);
      const targetIdx = allPanes.indexOf(targetPane);
      [allPanes[allIdx], allPanes[targetIdx]] = [allPanes[targetIdx], allPanes[allIdx]];
    }
  }

  console.log(`Final allPanes: ${allPanes.join(", ")}`);
  console.log(`Expected distribution: left=[A], right=[B,C]`);
  console.log(`Pass? ${allPanes.slice(0, 1).join(",") === "A" && allPanes.slice(1).join(",") === "B,C"}`);
  console.log("");
}

testEqualLength();
testUnequalLength();
testUnequalLengthReverse();
