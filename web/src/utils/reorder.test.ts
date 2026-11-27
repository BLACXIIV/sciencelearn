import { describe, expect, it } from "vitest";
import { moveBetween, moveInList, numOr } from "./reorder";

describe("moveInList", () => {
  const list = ["a", "b", "c", "d"];

  it("moves an item down one slot", () => {
    expect(moveInList(list, 0, 1)).toEqual(["b", "a", "c", "d"]);
  });

  it("moves an item up one slot", () => {
    expect(moveInList(list, 3, 2)).toEqual(["a", "b", "d", "c"]);
  });

  it("moves across the whole list", () => {
    expect(moveInList(list, 0, 3)).toEqual(["b", "c", "d", "a"]);
    expect(moveInList(list, 3, 0)).toEqual(["d", "a", "b", "c"]);
  });

  it("is a no-op at the edges (first up / last down)", () => {
    expect(moveInList(list, 0, -1)).toEqual(["a", "b", "c", "d"]);
    expect(moveInList(list, 3, 99)).toEqual(["a", "b", "c", "d"]);
    expect(moveInList(list, 2, 2)).toEqual(["a", "b", "c", "d"]);
  });

  it("clamps out-of-range indexes instead of throwing", () => {
    expect(moveInList(list, -5, 1)).toEqual(["b", "a", "c", "d"]);
    expect(moveInList(list, 0, 50)).toEqual(["b", "c", "d", "a"]);
  });

  it("never mutates the input", () => {
    const src = ["x", "y", "z"];
    moveInList(src, 0, 2);
    expect(src).toEqual(["x", "y", "z"]);
  });

  it("handles empty and single-item lists", () => {
    expect(moveInList([], 0, 0)).toEqual([]);
    expect(moveInList(["only"], 0, 0)).toEqual(["only"]);
  });
});

describe("moveBetween", () => {
  it("moves an id to the end of the target list", () => {
    expect(moveBetween(["a", "b"], ["c"], "a"))
      .toEqual({ from: ["b"], to: ["c", "a"] });
  });

  it("is idempotent when the id is already in the target", () => {
    expect(moveBetween(["a"], ["b", "a"], "a"))
      .toEqual({ from: [], to: ["b", "a"] });
  });

  it("does not duplicate when the id exists in both lists", () => {
    expect(moveBetween(["a", "b"], ["b", "c"], "b"))
      .toEqual({ from: ["a"], to: ["c", "b"] });
  });
});

describe("numOr", () => {
  it("parses normal numbers", () => {
    expect(numOr("3", -1)).toBe(3);
    expect(numOr("0", -1)).toBe(0);
    expect(numOr("2.5", -1)).toBe(2.5);
  });

  it("falls back on empty/blank input (the NaN bug)", () => {
    expect(numOr("", -1)).toBe(-1);
    expect(numOr("   ", -1)).toBe(-1);
  });

  it("falls back on garbage input", () => {
    expect(numOr("abc", -1)).toBe(-1);
    expect(numOr("1e999", -1)).toBe(-1); // Infinity is not finite
  });
});
