#!/usr/bin/env -S deno run --allow-run

// Test coordinate-based flip mapping

type Leaf = {
  pane: string;
  x: number;
  y: number;
  w: number;
  h: number;
};

function testEqualLength() {
  console.log("=== Test 1: Equal length [[A,B],[C,D]] → [[C,D],[A,B]] ===");
  const leftLeaves: Leaf[] = [
    { pane: "%0", x: 0, y: 0, w: 50, h: 50 },
    { pane: "%1", x: 0, y: 50, w: 50, h: 50 },
  ];
  const rightLeaves: Leaf[] = [
    { pane: "%2", x: 50, y: 0, w: 50, h: 50 },
    { pane: "%3", x: 50, y: 50, w: 50, h: 50 },
  ];

  const paneIdOverride = new Map<string, string>();

  for (let i = 0; i < Math.max(leftLeaves.length, rightLeaves.length); i++) {
    if (i < leftLeaves.length && i < rightLeaves.length) {
      const leftCoord = `${leftLeaves[i].x},${leftLeaves[i].y},${leftLeaves[i].w},${leftLeaves[i].h}`;
      const rightPane = rightLeaves[i].pane.slice(1);
      paneIdOverride.set(leftCoord, rightPane);

      const rightCoord = `${rightLeaves[i].x},${rightLeaves[i].y},${rightLeaves[i].w},${rightLeaves[i].h}`;
      const leftPane = leftLeaves[i].pane.slice(1);
      paneIdOverride.set(rightCoord, leftPane);
    }
  }

  console.log(`Coordinate mappings:`);
  for (const [coord, pane] of paneIdOverride) {
    console.log(`  ${coord} -> ${pane}`);
  }

  // Verify expected mappings
  const expected = new Map([
    ["0,0,50,50", "2"], // left[0] coord -> right[0] pane
    ["0,50,50,50", "3"], // left[1] coord -> right[1] pane
    ["50,0,50,50", "0"], // right[0] coord -> left[0] pane
    ["50,50,50,50", "1"], // right[1] coord -> left[1] pane
  ]);

  let pass = true;
  for (const [coord, pane] of expected) {
    const actual = paneIdOverride.get(coord);
    if (actual !== pane) {
      console.log(`FAIL: ${coord} expected ${pane}, got ${actual ?? "undefined"}`);
      pass = false;
    }
  }
  console.log(`Pass? ${pass}`);
  console.log("");
}

function testUnequalLength() {
  console.log("=== Test 2: Unequal length [A, [B,C]] → [[B,C], A] ===");
  const leftLeaves: Leaf[] = [
    { pane: "%0", x: 0, y: 0, w: 50, h: 100 },
  ];
  const rightLeaves: Leaf[] = [
    { pane: "%1", x: 50, y: 0, w: 50, h: 50 },
    { pane: "%2", x: 50, y: 50, w: 50, h: 50 },
  ];

  const paneIdOverride = new Map<string, string>();

  for (let i = 0; i < Math.max(leftLeaves.length, rightLeaves.length); i++) {
    if (i < leftLeaves.length && i < rightLeaves.length) {
      const leftCoord = `${leftLeaves[i].x},${leftLeaves[i].y},${leftLeaves[i].w},${leftLeaves[i].h}`;
      const rightPane = rightLeaves[i].pane.slice(1);
      paneIdOverride.set(leftCoord, rightPane);

      const rightCoord = `${rightLeaves[i].x},${rightLeaves[i].y},${rightLeaves[i].w},${rightLeaves[i].h}`;
      const leftPane = leftLeaves[i].pane.slice(1);
      paneIdOverride.set(rightCoord, leftPane);
    }
  }

  console.log(`Coordinate mappings:`);
  for (const [coord, pane] of paneIdOverride) {
    console.log(`  ${coord} -> ${pane}`);
  }

  // Expected:
  // left[0] coord (0,0,50,100) -> right[0] pane (1)
  // right[0] coord (50,0,50,50) -> left[0] pane (0)
  // right[1] coord (50,50,50,50) -> no mapping (no left[1])

  const expected = new Map([
    ["0,0,50,100", "1"],
    ["50,0,50,50", "0"],
  ]);

  let pass = true;
  for (const [coord, pane] of expected) {
    const actual = paneIdOverride.get(coord);
    if (actual !== pane) {
      console.log(`FAIL: ${coord} expected ${pane}, got ${actual ?? "undefined"}`);
      pass = false;
    }
  }

  // Check that right[1] has no mapping
  if (paneIdOverride.has("50,50,50,50")) {
    console.log(`FAIL: 50,50,50,50 should have no mapping, got ${paneIdOverride.get("50,50,50,50")}`);
    pass = false;
  } else {
    console.log(`OK: 50,50,50,50 has no mapping (will keep original pane)`);
  }

  console.log(`Pass? ${pass}`);
  console.log("");
}

testEqualLength();
testUnequalLength();
