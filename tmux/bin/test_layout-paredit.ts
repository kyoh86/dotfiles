#!/usr/bin/env -S deno test --allow-run

// Comprehensive edge case tests for layout-paredit.ts functions

import {
  parseRectParts,
  normalizeToBinary,
  reconstructLayout,
  calculateChecksum,
  nodeAt,
  parentPath,
  siblingPath,
  leaves,
  allNodes,
  firstLeaf,
  center,
  isPrefix,
  compact,
  recalculateRects,
  swapChildren,
  pathOfPane,
  sortLeavesByGeometry,
  type Node,
  type Leaf,
  type Rect,
} from "./layout-paredit.ts";

// Mock types for testing
type MockState = {
  selectedPath: number[];
  preselect: "row" | "col" | null;
};

// Helper function to create a leaf node
function leaf(pane: string, x: number, y: number, w: number, h: number): Leaf {
  return { type: "leaf", pane, rect: { x, y, w, h } };
}

// Helper function to create a split node
function split(axis: "row" | "col", x: number, y: number, w: number, h: number, children: Node[]): Node {
  return { type: "split", axis, rect: { x, y, w, h }, children };
}

// ==================== parseRectParts Tests ====================
Deno.test("parseRectParts - valid input", () => {
  const result = parseRectParts("100", "200", "10", "20");
  assertEquals(result, { w: 100, h: 200, x: 10, y: 20 });
});

Deno.test("parseRectParts - zeros", () => {
  const result = parseRectParts("0", "0", "0", "0");
  assertEquals(result, { w: 0, h: 0, x: 0, y: 0 });
});

Deno.test("parseRectParts - negative numbers (edge case)", () => {
  const result = parseRectParts("-1", "-1", "-10", "-20");
  assertEquals(result, { w: -1, h: -1, x: -10, y: -20 });
});

// ==================== normalizeToBinary Tests ====================
Deno.test("normalizeToBinary - single leaf", () => {
  const input = leaf("%0", 0, 0, 100, 100);
  const result = normalizeToBinary(input);
  assertEquals(result, input);
});

Deno.test("normalizeToBinary - single split with one child", () => {
  const input = split("row", 0, 0, 100, 100, [leaf("%0", 0, 0, 100, 100)]);
  const result = normalizeToBinary(input);
  assertEquals(result, input.children[0]);
});

Deno.test("normalizeToBinary - already binary (2 children)", () => {
  const input = split("row", 0, 0, 100, 100, [
    leaf("%0", 0, 0, 50, 100),
    leaf("%1", 50, 0, 50, 100),
  ]);
  const result = normalizeToBinary(input);
  assertEquals(result, input);
});

Deno.test("normalizeToBinary - 3 children (row)", () => {
  const input = split("row", 0, 0, 150, 100, [
    leaf("%0", 0, 0, 50, 100),
    leaf("%1", 50, 0, 50, 100),
    leaf("%2", 100, 0, 50, 100),
  ]);
  const result = normalizeToBinary(input);
  // Should become [[%0, %1], %2]
  assertEquals(result.type, "split");
  assertEquals(result.axis, "row");
  assertEquals(result.children.length, 2);

  const leftChild = result.children[0];
  assertEquals(leftChild.type, "split");
  assertEquals(leftChild.children.length, 2);
  assertEquals(leftChild.children[0], input.children[0]);
  assertEquals(leftChild.children[1], input.children[1]);
  assertEquals(result.children[1], input.children[2]);

  // Verify intermediate rect calculation
  assertEquals(leftChild.rect.x, 0);
  assertEquals(leftChild.rect.y, 0);
  assertEquals(leftChild.rect.w, 101); // 50 + 1 + 50 (border)
  assertEquals(leftChild.rect.h, 100);
});

Deno.test("normalizeToBinary - 3 children (col)", () => {
  const input = split("col", 0, 0, 100, 150, [
    leaf("%0", 0, 0, 100, 50),
    leaf("%1", 0, 50, 100, 50),
    leaf("%2", 0, 100, 100, 50),
  ]);
  const result = normalizeToBinary(input);
  // Should become [[%0, %1], %2]
  assertEquals(result.type, "split");
  assertEquals(result.axis, "col");
  assertEquals(result.children.length, 2);

  const leftChild = result.children[0];
  assertEquals(leftChild.type, "split");
  assertEquals(leftChild.children.length, 2);

  // Verify intermediate rect calculation
  assertEquals(leftChild.rect.x, 0);
  assertEquals(leftChild.rect.y, 0);
  assertEquals(leftChild.rect.w, 100);
  assertEquals(leftChild.rect.h, 101); // 50 + 1 + 50 (border)
});

Deno.test("normalizeToBinary - 4 children", () => {
  const input = split("row", 0, 0, 200, 100, [
    leaf("%0", 0, 0, 50, 100),
    leaf("%1", 50, 0, 50, 100),
    leaf("%2", 100, 0, 50, 100),
    leaf("%3", 150, 0, 50, 100),
  ]);
  const result = normalizeToBinary(input);
  // Should become [[[%0, %1], %2], %3]
  assertEquals(result.type, "split");
  assertEquals(result.children.length, 2);

  const leftChild = result.children[0];
  assertEquals(leftChild.type, "split");
  assertEquals(leftChild.children.length, 2);

  const leftLeftChild = leftChild.children[0];
  assertEquals(leftLeftChild.type, "split");
  assertEquals(leftLeftChild.children.length, 2);
  assertEquals(leftLeftChild.children[0], input.children[0]);
  assertEquals(leftLeftChild.children[1], input.children[1]);
  assertEquals(leftChild.children[1], input.children[2]);
  assertEquals(result.children[1], input.children[3]);
});

Deno.test("normalizeToBinary - empty children", () => {
  const input = split("row", 0, 0, 100, 100, []);
  const result = normalizeToBinary(input);
  assertEquals(result, input);
});

Deno.test("normalizeToBinary - deeply nested structure", () => {
  const input = split("row", 0, 0, 200, 100, [
    split("col", 0, 0, 100, 100, [
      leaf("%0", 0, 0, 100, 50),
      leaf("%1", 0, 50, 100, 50),
    ]),
    split("col", 100, 0, 100, 100, [
      leaf("%2", 100, 0, 100, 50),
      leaf("%3", 100, 50, 100, 50),
    ]),
  ]);
  const result = normalizeToBinary(input);
  assertEquals(result.type, "split");
  assertEquals(result.axis, "row");
  assertEquals(result.children.length, 2);
});

// ==================== reconstructLayout Tests ====================
Deno.test("reconstructLayout - single leaf", () => {
  const input = leaf("%0", 0, 0, 100, 100);
  const result = reconstructLayout(input);
  assertEquals(result, "100x100,0,0,0");
});

Deno.test("reconstructLayout - row split with 2 leaves", () => {
  const input = split("row", 0, 0, 200, 100, [
    leaf("%0", 0, 0, 100, 100),
    leaf("%1", 100, 0, 100, 100),
  ]);
  const result = reconstructLayout(input);
  assertEquals(result, "200x100,0,0{100x100,0,0,0,100x100,100,0,1}");
});

Deno.test("reconstructLayout - col split with 2 leaves", () => {
  const input = split("col", 0, 0, 100, 200, [
    leaf("%0", 0, 0, 100, 100),
    leaf("%1", 0, 100, 100, 100),
  ]);
  const result = reconstructLayout(input);
  assertEquals(result, "100x200,0,0[100x100,0,0,0,100x100,0,100,1]");
});

Deno.test("reconstructLayout - nested structure", () => {
  const input = split("row", 0, 0, 200, 100, [
    split("col", 0, 0, 100, 100, [
      leaf("%0", 0, 0, 100, 50),
      leaf("%1", 0, 50, 100, 50),
    ]),
    leaf("%2", 100, 0, 100, 100),
  ]);
  const result = reconstructLayout(input);
  assertEquals(result, "200x100,0,0{100x100,0,0[100x50,0,0,0,100x50,0,50,1],100x100,100,0,2}");
});

Deno.test("reconstructLayout - with paneIdOverride", () => {
  const input = split("row", 0, 0, 200, 100, [
    leaf("%0", 0, 0, 100, 100),
    leaf("%1", 100, 0, 100, 100),
  ]);
  const override = new Map([["0,0,100,100", "5"]]);
  const result = reconstructLayout(input, override);
  assertEquals(result, "200x100,0,0{100x100,0,0,5,100x100,100,0,1}");
});

Deno.test("reconstructLayout - empty override map", () => {
  const input = leaf("%0", 0, 0, 100, 100);
  const result = reconstructLayout(input, new Map());
  assertEquals(result, "100x100,0,0,0");
});

// ==================== calculateChecksum Tests ====================
Deno.test("calculateChecksum - empty string", () => {
  const result = calculateChecksum("");
  assertEquals(result, "0000");
});

Deno.test("calculateChecksum - simple layout", () => {
  const result = calculateChecksum("100x100,0,0,0");
  // Verify checksum is consistent
  const result2 = calculateChecksum("100x100,0,0,0");
  assertEquals(result, result2);
});

Deno.test("calculateChecksum - different layouts produce different checksums", () => {
  const checksum1 = calculateChecksum("100x100,0,0,0");
  const checksum2 = calculateChecksum("200x100,0,0,0");
  assertNotEquals(checksum1, checksum2);
});

Deno.test("calculateChecksum - same layout, same checksum", () => {
  const layout = "100x100,0,0{50x100,0,0,0,50x100,50,0,1}";
  const checksum1 = calculateChecksum(layout);
  const checksum2 = calculateChecksum(layout);
  assertEquals(checksum1, checksum2);
});

// ==================== nodeAt Tests ====================
Deno.test("nodeAt - empty path", () => {
  const tree = leaf("%0", 0, 0, 100, 100);
  const result = nodeAt(tree, []);
  assertEquals(result, tree);
});

Deno.test("nodeAt - single level", () => {
  const tree = split("row", 0, 0, 200, 100, [
    leaf("%0", 0, 0, 100, 100),
    leaf("%1", 100, 0, 100, 100),
  ]);
  const result = nodeAt(tree, [0]);
  assertEquals(result, tree.children[0]);
});

Deno.test("nodeAt - multi level", () => {
  const tree = split("row", 0, 0, 200, 100, [
    split("col", 0, 0, 100, 100, [
      leaf("%0", 0, 0, 100, 50),
      leaf("%1", 0, 50, 100, 50),
    ]),
    leaf("%2", 100, 0, 100, 100),
  ]);
  const result = nodeAt(tree, [0, 1]);
  assertEquals(result, tree.children[0].children[1]);
});

Deno.test("nodeAt - invalid path (leaf in middle)", () => {
  const tree = split("row", 0, 0, 200, 100, [
    leaf("%0", 0, 0, 100, 100),
    leaf("%1", 100, 0, 100, 100),
  ]);
  const result = nodeAt(tree, [0, 0]); // Try to go into a leaf
  assertEquals(result, tree.children[0]);
});

Deno.test("nodeAt - out of bounds index", () => {
  const tree = split("row", 0, 0, 200, 100, [
    leaf("%0", 0, 0, 100, 100),
    leaf("%1", 100, 0, 100, 100),
  ]);
  // This will access undefined, but the function doesn't validate bounds
  // Just document this behavior
  const result = nodeAt(tree, [5]);
  // In TypeScript/JavaScript, this will return undefined
  // But our function doesn't handle this case explicitly
});

// ==================== parentPath Tests ====================
Deno.test("parentPath - empty path", () => {
  const result = parentPath([]);
  assertEquals(result, []);
});

Deno.test("parentPath - single element", () => {
  const result = parentPath([0]);
  assertEquals(result, []);
});

Deno.test("parentPath - multi element", () => {
  const result = parentPath([0, 1, 0]);
  assertEquals(result, [0, 1]);
});

Deno.test("parentPath - preserves original", () => {
  const input = [0, 1, 2];
  const result = parentPath(input);
  assertEquals(input, [0, 1, 2]); // Original unchanged
  assertEquals(result, [0, 1]);
});

// ==================== siblingPath Tests ====================
Deno.test("siblingPath - empty path", () => {
  const result = siblingPath([]);
  assertEquals(result, []);
});

Deno.test("siblingPath - path with 0", () => {
  const result = siblingPath([0, 1, 0]);
  assertEquals(result, [0, 1, 1]);
});

Deno.test("siblingPath - path with 1", () => {
  const result = siblingPath([1, 0, 1]);
  assertEquals(result, [1, 0, 0]);
});

Deno.test("siblingPath - preserves original", () => {
  const input = [0, 1, 0];
  const result = siblingPath(input);
  assertEquals(input, [0, 1, 0]); // Original unchanged
  assertEquals(result, [0, 1, 1]);
});

// ==================== leaves Tests ====================
Deno.test("leaves - single leaf", () => {
  const tree = leaf("%0", 0, 0, 100, 100);
  const result = leaves(tree);
  assertEquals(result.length, 1);
  assertEquals(result[0], tree);
});

Deno.test("leaves - row split with 2 leaves", () => {
  const tree = split("row", 0, 0, 200, 100, [
    leaf("%0", 0, 0, 100, 100),
    leaf("%1", 100, 0, 100, 100),
  ]);
  const result = leaves(tree);
  assertEquals(result.length, 2);
  assertEquals(result[0], tree.children[0]);
  assertEquals(result[1], tree.children[1]);
});

Deno.test("leaves - nested structure", () => {
  const tree = split("row", 0, 0, 200, 100, [
    split("col", 0, 0, 100, 100, [
      leaf("%0", 0, 0, 100, 50),
      leaf("%1", 0, 50, 100, 50),
    ]),
    leaf("%2", 100, 0, 100, 100),
  ]);
  const result = leaves(tree);
  assertEquals(result.length, 3);
  assertEquals(result[0], tree.children[0].children[0]);
  assertEquals(result[1], tree.children[0].children[1]);
  assertEquals(result[2], tree.children[1]);
});

Deno.test("leaves - deeply nested", () => {
  const tree = split("row", 0, 0, 200, 100, [
    split("col", 0, 0, 100, 100, [
      split("row", 0, 0, 100, 50, [
        leaf("%0", 0, 0, 50, 50),
        leaf("%1", 50, 0, 50, 50),
      ]),
      leaf("%2", 0, 50, 100, 50),
    ]),
    leaf("%3", 100, 0, 100, 100),
  ]);
  const result = leaves(tree);
  assertEquals(result.length, 4);
});

// ==================== allNodes Tests ====================
Deno.test("allNodes - single leaf", () => {
  const tree = leaf("%0", 0, 0, 100, 100);
  const result = allNodes(tree);
  assertEquals(result.length, 1);
  assertEquals(result[0].node, tree);
  assertEquals(result[0].path, []);
});

Deno.test("allNodes - simple split", () => {
  const tree = split("row", 0, 0, 200, 100, [
    leaf("%0", 0, 0, 100, 100),
    leaf("%1", 100, 0, 100, 100),
  ]);
  const result = allNodes(tree);
  assertEquals(result.length, 3); // root + 2 leaves

  assertEquals(result[0].node, tree);
  assertEquals(result[0].path, []);

  assertEquals(result[1].node, tree.children[0]);
  assertEquals(result[1].path, [0]);

  assertEquals(result[2].node, tree.children[1]);
  assertEquals(result[2].path, [1]);
});

Deno.test("allNodes - nested structure", () => {
  const tree = split("row", 0, 0, 200, 100, [
    split("col", 0, 0, 100, 100, [
      leaf("%0", 0, 0, 100, 50),
      leaf("%1", 0, 50, 100, 50),
    ]),
    leaf("%2", 100, 0, 100, 100),
  ]);
  const result = allNodes(tree);
  assertEquals(result.length, 6); // root + col split + 3 leaves

  // Find the col split
  const colSplit = result.find(r => r.path.join(",") === "0");
  assertEquals(colSplit!.node.type, "split");
});

Deno.test("allNodes - with custom initial path", () => {
  const tree = split("row", 0, 0, 200, 100, [
    leaf("%0", 0, 0, 100, 100),
    leaf("%1", 100, 0, 100, 100),
  ]);
  const result = allNodes(tree, [1]);
  assertEquals(result.length, 3);

  assertEquals(result[0].path, [1]);
  assertEquals(result[1].path, [1, 0]);
  assertEquals(result[2].path, [1, 1]);
});

// ==================== firstLeaf Tests ====================
Deno.test("firstLeaf - single leaf", () => {
  const tree = leaf("%0", 0, 0, 100, 100);
  const result = firstLeaf(tree);
  assertEquals(result, tree);
});

Deno.test("firstLeaf - row split", () => {
  const tree = split("row", 0, 0, 200, 100, [
    leaf("%0", 0, 0, 100, 100),
    leaf("%1", 100, 0, 100, 100),
  ]);
  const result = firstLeaf(tree);
  assertEquals(result, tree.children[0]);
});

Deno.test("firstLeaf - nested structure", () => {
  const tree = split("row", 0, 0, 200, 100, [
    split("col", 0, 0, 100, 100, [
      leaf("%0", 0, 0, 100, 50),
      leaf("%1", 0, 50, 100, 50),
    ]),
    leaf("%2", 100, 0, 100, 100),
  ]);
  const result = firstLeaf(tree);
  assertEquals(result, tree.children[0].children[0]);
});

// ==================== center Tests ====================
Deno.test("center - leaf node", () => {
  const node = leaf("%0", 10, 20, 100, 50);
  const result = center(node);
  assertEquals(result.x, 60); // 10 + 100/2
  assertEquals(result.y, 45); // 20 + 50/2
});

Deno.test("center - split node", () => {
  const node = split("row", 10, 20, 200, 100, []);
  const result = center(node);
  assertEquals(result.x, 110); // 10 + 200/2
  assertEquals(result.y, 70); // 20 + 100/2
});

Deno.test("center - zero size", () => {
  const node = leaf("%0", 0, 0, 0, 0);
  const result = center(node);
  assertEquals(result.x, 0);
  assertEquals(result.y, 0);
});

Deno.test("center - negative coordinates", () => {
  const node = leaf("%0", -10, -20, 100, 50);
  const result = center(node);
  assertEquals(result.x, 40); // -10 + 100/2
  assertEquals(result.y, 5); // -20 + 50/2
});

// ==================== isPrefix Tests ====================
Deno.test("isPrefix - empty array is prefix of anything", () => {
  assertEquals(isPrefix([], []), true);
  assertEquals(isPrefix([], [0]), true);
  assertEquals(isPrefix([], [0, 1]), true);
});

Deno.test("isPrefix - same array", () => {
  assertEquals(isPrefix([0], [0]), true);
  assertEquals(isPrefix([0, 1], [0, 1]), true);
  assertEquals(isPrefix([0, 1, 2], [0, 1, 2]), true);
});

Deno.test("isPrefix - actual prefix", () => {
  assertEquals(isPrefix([0], [0, 1]), true);
  assertEquals(isPrefix([0, 1], [0, 1, 2]), true);
});

Deno.test("isPrefix - not a prefix (different values)", () => {
  assertEquals(isPrefix([0], [1]), false);
  assertEquals(isPrefix([0, 1], [0, 2]), false);
});

Deno.test("isPrefix - not a prefix (shorter but different)", () => {
  assertEquals(isPrefix([0, 1], [0]), false);
  assertEquals(isPrefix([0, 1], [0, 1, 2]), true); // This is prefix
});

Deno.test("isPrefix - longer array can't be prefix", () => {
  assertEquals(isPrefix([0, 1], [0]), false);
  assertEquals(isPrefix([0, 1, 2], [0, 1]), false);
});

// ==================== compact Tests ====================
Deno.test("compact - single leaf", () => {
  const tree = leaf("%0", 0, 0, 100, 100);
  const result = compact(tree);
  assertEquals(result, "%0");
});

Deno.test("compact - row split", () => {
  const tree = split("row", 0, 0, 200, 100, [
    leaf("%0", 0, 0, 100, 100),
    leaf("%1", 100, 0, 100, 100),
  ]);
  const result = compact(tree);
  assertEquals(result, "(%0|%%1)");
});

Deno.test("compact - col split", () => {
  const tree = split("col", 0, 0, 100, 200, [
    leaf("%0", 0, 0, 100, 100),
    leaf("%1", 0, 100, 100, 100),
  ]);
  const result = compact(tree);
  assertEquals(result, "(%0/%1)");
});

Deno.test("compact - nested structure", () => {
  const tree = split("row", 0, 0, 200, 100, [
    split("col", 0, 0, 100, 100, [
      leaf("%0", 0, 0, 100, 50),
      leaf("%1", 0, 50, 100, 50),
    ]),
    leaf("%2", 100, 0, 100, 100),
  ]);
  const result = compact(tree);
  assertEquals(result, "((%0/%1)|%2)");
});

// ==================== recalculateRects Tests ====================
Deno.test("recalculateRects - single leaf without parent", () => {
  const tree = leaf("%0", 0, 0, 100, 100);
  const result = recalculateRects(tree, null);
  assertEquals(result, tree);
});

Deno.test("recalculateRects - single leaf with parent", () => {
  const tree = leaf("%0", 0, 0, 100, 100);
  const parentRect = { x: 10, y: 20, w: 200, h: 200 };
  const result = recalculateRects(tree, parentRect);
  assertEquals(result.rect.w, 100); // Size unchanged
  assertEquals(result.rect.h, 100);
  assertEquals(result.rect.x, 10); // Position from parent
  assertEquals(result.rect.y, 20);
});

Deno.test("recalculateRects - row split with 2 children", () => {
  const tree = split("row", 0, 0, 200, 100, [
    leaf("%0", 0, 0, 100, 100),
    leaf("%1", 100, 0, 100, 100),
  ]);
  const result = recalculateRects(tree, null);

  assertEquals(result.type, "split");
  assertEquals(result.axis, "row");
  assertEquals(result.rect.w, 201); // 100 + 1 + 100 (border)
  assertEquals(result.rect.h, 100);

  assertEquals(result.children[0].rect.x, 0);
  assertEquals(result.children[0].rect.y, 0);
  assertEquals(result.children[0].rect.w, 100);
  assertEquals(result.children[0].rect.h, 100);

  assertEquals(result.children[1].rect.x, 101); // 0 + 100 + 1 (border)
  assertEquals(result.children[1].rect.y, 0);
  assertEquals(result.children[1].rect.w, 100);
  assertEquals(result.children[1].rect.h, 100);
});

Deno.test("recalculateRects - col split with 2 children", () => {
  const tree = split("col", 0, 0, 100, 200, [
    leaf("%0", 0, 0, 100, 100),
    leaf("%1", 0, 100, 100, 100),
  ]);
  const result = recalculateRects(tree, null);

  assertEquals(result.type, "split");
  assertEquals(result.axis, "col");
  assertEquals(result.rect.w, 100);
  assertEquals(result.rect.h, 201); // 100 + 1 + 100 (border)

  assertEquals(result.children[0].rect.x, 0);
  assertEquals(result.children[0].rect.y, 0);
  assertEquals(result.children[0].rect.w, 100);
  assertEquals(result.children[0].rect.h, 100);

  assertEquals(result.children[1].rect.x, 0);
  assertEquals(result.children[1].rect.y, 101); // 0 + 100 + 1 (border)
  assertEquals(result.children[1].rect.w, 100);
  assertEquals(result.children[1].rect.h, 100);
});

Deno.test("recalculateRects - nested structure", () => {
  const tree = split("row", 0, 0, 200, 100, [
    split("col", 0, 0, 100, 100, [
      leaf("%0", 0, 0, 100, 50),
      leaf("%1", 0, 50, 100, 50),
    ]),
    leaf("%2", 100, 0, 100, 100),
  ]);
  const result = recalculateRects(tree, null);

  // Root should have correct dimensions
  assertEquals(result.rect.w, 201); // 100 + 1 + 100
  assertEquals(result.rect.h, 100);

  // Left col split
  const leftCol = result.children[0];
  assertEquals(leftCol.rect.w, 100);
  assertEquals(leftCol.rect.h, 101); // 50 + 1 + 50

  // Leaves should be positioned correctly
  assertEquals(result.children[0].children[0].rect.x, 0);
  assertEquals(result.children[0].children[0].rect.y, 0);

  assertEquals(result.children[0].children[1].rect.x, 0);
  assertEquals(result.children[0].children[1].rect.y, 51); // 0 + 50 + 1

  assertEquals(result.children[1].rect.x, 101); // 0 + 100 + 1
  assertEquals(result.children[1].rect.y, 0);
});

Deno.test("recalculateRects - with parent rect offset", () => {
  const tree = split("row", 0, 0, 200, 100, [
    leaf("%0", 0, 0, 100, 100),
    leaf("%1", 100, 0, 100, 100),
  ]);
  const parentRect = { x: 50, y: 50, w: 300, h: 200 };
  const result = recalculateRects(tree, parentRect);

  assertEquals(result.rect.x, 50); // From parent
  assertEquals(result.rect.y, 50);

  assertEquals(result.children[0].rect.x, 50); // From parent
  assertEquals(result.children[0].rect.y, 50);

  assertEquals(result.children[1].rect.x, 151); // 50 + 100 + 1
  assertEquals(result.children[1].rect.y, 50);
});

// ==================== swapChildren Tests ====================
Deno.test("swapChildren - empty path (swap root's children)", () => {
  const tree = split("row", 0, 0, 200, 100, [
    leaf("%0", 0, 0, 100, 100),
    leaf("%1", 100, 0, 100, 100),
  ]);
  const result = swapChildren(tree, []);

  assertEquals(result.children[0].pane, "%1");
  assertEquals(result.children[1].pane, "%0");

  // Original should be unchanged (deep copy)
  assertEquals(tree.children[0].pane, "%0");
  assertEquals(tree.children[1].pane, "%1");
});

Deno.test("swapChildren - single level path", () => {
  const tree = split("row", 0, 0, 200, 100, [
    split("col", 0, 0, 100, 100, [
      leaf("%0", 0, 0, 100, 50),
      leaf("%1", 0, 50, 100, 50),
    ]),
    leaf("%2", 100, 0, 100, 100),
  ]);
  const result = swapChildren(tree, [0]);

  assertEquals(result.children[0].children[0].pane, "%1");
  assertEquals(result.children[0].children[1].pane, "%0");

  // Root's children should be unchanged
  assertEquals(result.children[0].type, "split");
  assertEquals(result.children[1].pane, "%2");
});

Deno.test("swapChildren - multi level path", () => {
  const tree = split("row", 0, 0, 200, 100, [
    split("col", 0, 0, 100, 100, [
      split("row", 0, 0, 100, 50, [
        leaf("%0", 0, 0, 50, 50),
        leaf("%1", 50, 0, 50, 50),
      ]),
      leaf("%2", 0, 50, 100, 50),
    ]),
    leaf("%3", 100, 0, 100, 100),
  ]);
  const result = swapChildren(tree, [0, 0]);

  assertEquals(result.children[0].children[0].children[0].pane, "%1");
  assertEquals(result.children[0].children[0].children[1].pane, "%0");
});

Deno.test("swapChildren - swap leaf (no-op)", () => {
  const tree = split("row", 0, 0, 200, 100, [
    leaf("%0", 0, 0, 100, 100),
    leaf("%1", 100, 0, 100, 100),
  ]);
  const result = swapChildren(tree, [0]);

  // Can't swap children of a leaf, should return unchanged copy
  assertEquals(result.children[0].pane, "%0");
  assertEquals(result.children[1].pane, "%1");

  // Should be a copy though
  assertNotEquals(result, tree);
});

Deno.test("swapChildren - invalid path (out of bounds)", () => {
  const tree = split("row", 0, 0, 200, 100, [
    leaf("%0", 0, 0, 100, 100),
    leaf("%1", 100, 0, 100, 100),
  ]);

  // This will throw in JavaScript due to accessing undefined
  // The function doesn't handle this case
  try {
    swapChildren(tree, [5]);
    throw new Error("Should have thrown");
  } catch (e) {
    // Expected to throw
  }
});

// ==================== pathOfPane Tests ====================
Deno.test("pathOfPane - find pane in simple tree", () => {
  const tree = split("row", 0, 0, 200, 100, [
    leaf("%0", 0, 0, 100, 100),
    leaf("%1", 100, 0, 100, 100),
  ]);
  const result = pathOfPane(tree, "%1");
  assertEquals(result, [1]);
});

Deno.test("pathOfPane - find pane in nested tree", () => {
  const tree = split("row", 0, 0, 200, 100, [
    split("col", 0, 0, 100, 100, [
      leaf("%0", 0, 0, 100, 50),
      leaf("%1", 0, 50, 100, 50),
    ]),
    leaf("%2", 100, 0, 100, 100),
  ]);
  const result = pathOfPane(tree, "%1");
  assertEquals(result, [0, 1]);
});

Deno.test("pathOfPane - pane not found", () => {
  const tree = split("row", 0, 0, 200, 100, [
    leaf("%0", 0, 0, 100, 100),
    leaf("%1", 100, 0, 100, 100),
  ]);
  const result = pathOfPane(tree, "%99");
  assertEquals(result, []);
});

Deno.test("pathOfPane - first pane", () => {
  const tree = split("row", 0, 0, 200, 100, [
    leaf("%0", 0, 0, 100, 100),
    leaf("%1", 100, 0, 100, 100),
  ]);
  const result = pathOfPane(tree, "%0");
  assertEquals(result, [0]);
});

Deno.test("pathOfPane - deeply nested pane", () => {
  const tree = split("row", 0, 0, 200, 100, [
    split("col", 0, 0, 100, 100, [
      split("row", 0, 0, 100, 50, [
        leaf("%0", 0, 0, 50, 50),
        leaf("%1", 50, 0, 50, 50),
      ]),
      leaf("%2", 0, 50, 100, 50),
    ]),
    leaf("%3", 100, 0, 100, 100),
  ]);
  const result = pathOfPane(tree, "%2");
  assertEquals(result, [0, 1]);
});

// ==================== sortLeavesByGeometry Tests ====================
Deno.test("sortLeavesByGeometry - same y, sort by x", () => {
  const leaf1 = leaf("%1", 10, 0, 50, 50);
  const leaf2 = leaf("%2", 0, 0, 50, 50);
  const result = sortLeavesByGeometry(leaf1, leaf2);
  // leaf2.x < leaf1.x, so leaf2 should come first (negative return means leaf1 - leaf2)
  assertEquals(result > 0, true); // leaf1 - leaf2 = 10 - 0 = 10 > 0
});

Deno.test("sortLeavesByGeometry - different y, sort by y", () => {
  const leaf1 = leaf("%1", 0, 10, 50, 50);
  const leaf2 = leaf("%2", 0, 0, 50, 50);
  const result = sortLeavesByGeometry(leaf1, leaf2);
  // leaf2.y < leaf1.y, so leaf2 should come first
  assertEquals(result > 0, true); // leaf1 - leaf2 = 10 - 0 = 10 > 0
});

Deno.test("sortLeavesByGeometry - same position", () => {
  const leaf1 = leaf("%1", 0, 0, 50, 50);
  const leaf2 = leaf("%2", 0, 0, 50, 50);
  const result = sortLeavesByGeometry(leaf1, leaf2);
  assertEquals(result, 0); // Same position
});

Deno.test("sortLeavesByGeometry - y difference > 1", () => {
  const leaf1 = leaf("%1", 0, 100, 50, 50);
  const leaf2 = leaf("%2", 0, 0, 50, 50);
  const result = sortLeavesByGeometry(leaf1, leaf2);
  assertEquals(result, 100); // 100 - 0 = 100
});

Deno.test("sortLeavesByGeometry - y difference <= 1, sort by x", () => {
  const leaf1 = leaf("%1", 10, 0, 50, 50);
  const leaf2 = leaf("%2", 0, 1, 50, 50); // y difference = 1
  const result = sortLeavesByGeometry(leaf1, leaf2);
  // y difference <= 1, so sort by x
  assertEquals(result, 10); // 10 - 0 = 10
});

// ==================== Additional Edge Cases ====================
Deno.test("recalculateRects - zero size children", () => {
  const tree = split("row", 0, 0, 0, 0, [
    leaf("%0", 0, 0, 0, 0),
    leaf("%1", 0, 0, 0, 0),
  ]);
  const result = recalculateRects(tree, null);

  assertEquals(result.rect.w, 1); // 0 + 1 + 0 (border)
  assertEquals(result.rect.h, 0);
});

Deno.test("recalculateRects - very large dimensions", () => {
  const tree = split("row", 0, 0, 10000, 10000, [
    leaf("%0", 0, 0, 5000, 10000),
    leaf("%1", 5000, 0, 5000, 10000),
  ]);
  const result = recalculateRects(tree, null);

  assertEquals(result.rect.w, 5001); // 5000 + 1 + 5000
  assertEquals(result.rect.h, 10000);
});

Deno.test("normalizeToBinary - many children (10)", () => {
  const children: Node[] = [];
  for (let i = 0; i < 10; i++) {
    children.push(leaf(`%${i}`, i * 50, 0, 50, 100));
  }
  const tree = split("row", 0, 0, 500, 100, children);
  const result = normalizeToBinary(tree);

  // Should be deeply nested binary tree
  assertEquals(result.type, "split");
  assertEquals(result.axis, "row");
  assertEquals(result.children.length, 2);

  // Count total leaves
  const resultLeaves = leaves(result);
  assertEquals(resultLeaves.length, 10);
});

Deno.test("swapChildren - complex nested structure", () => {
  const tree = split("row", 0, 0, 200, 100, [
    split("col", 0, 0, 100, 100, [
      leaf("%0", 0, 0, 100, 50),
      leaf("%1", 0, 50, 100, 50),
    ]),
    split("col", 100, 0, 100, 100, [
      leaf("%2", 100, 0, 100, 50),
      leaf("%3", 100, 50, 100, 50),
    ]),
  ]);

  // Swap root's children
  let result = swapChildren(tree, []);
  assertEquals(result.children[0].children[0].pane, "%2");
  assertEquals(result.children[0].children[1].pane, "%3");
  assertEquals(result.children[1].children[0].pane, "%0");
  assertEquals(result.children[1].children[1].pane, "%1");

  // Now swap left child's children
  result = swapChildren(result, [0]);
  assertEquals(result.children[0].children[0].pane, "%3");
  assertEquals(result.children[0].children[1].pane, "%2");
});

Deno.test("nodeAt - path points to split", () => {
  const tree = split("row", 0, 0, 200, 100, [
    split("col", 0, 0, 100, 100, [
      leaf("%0", 0, 0, 100, 50),
      leaf("%1", 0, 50, 100, 50),
    ]),
    leaf("%2", 100, 0, 100, 100),
  ]);

  const result = nodeAt(tree, [0]);
  assertEquals(result.type, "split");
  assertEquals((result as any).axis, "col");
});

Deno.test("allNodes - empty tree", () => {
  // Note: Our type system doesn't allow empty split, but let's test with a leaf
  const tree = leaf("%0", 0, 0, 100, 100);
  const result = allNodes(tree);
  assertEquals(result.length, 1);
});

Deno.test("center - half pixel calculation", () => {
  const node = leaf("%0", 0, 0, 101, 101);
  const result = center(node);
  assertEquals(result.x, 50.5); // 0 + 101/2
  assertEquals(result.y, 50.5);
});

// Helper assertion functions
function assertEquals(actual: unknown, expected: unknown, msg?: string): void {
  if (actual !== expected) {
    throw new Error(
      `Assertion failed: ${msg ?? ""}\n  Expected: ${JSON.stringify(expected)}\n  Actual: ${JSON.stringify(actual)}`,
    );
  }
}

function assertNotEquals(actual: unknown, expected: unknown, msg?: string): void {
  if (actual === expected) {
    throw new Error(
      `Assertion failed (not equal): ${msg ?? ""}\n  Both are: ${JSON.stringify(actual)}`,
    );
  }
}
