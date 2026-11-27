import { describe, expect, it } from "vitest";
import { isAnswered, sortQuestionsByPart } from "./quiz";
import type { AssessmentPart, QuizQuestion } from "../types";

const part = (id: string, position: number): AssessmentPart => ({
  id, assessment_id: "a1", title: id, directions: "",
  mode: "multiple_choice", scored: true, points: 1, position,
});

const q = (id: string, partId: string | null, position: number): QuizQuestion => ({
  id, assessment_id: "a1", part_id: partId, qtype: "multiple_choice",
  prompt: id, choices: null, meta: {}, position,
});

describe("sortQuestionsByPart", () => {
  const p1 = part("p1", 0);
  const p2 = part("p2", 1);

  it("groups questions by part position, then question position", () => {
    // Flat position order interleaves parts — this is the legacy bug.
    const input = [
      q("q-b0", "p2", 0), q("q-a0", "p1", 0),
      q("q-a1", "p1", 1), q("q-b1", "p2", 1),
    ];
    expect(sortQuestionsByPart(input, [p1, p2]).map((x) => x.id))
      .toEqual(["q-a0", "q-a1", "q-b0", "q-b1"]);
  });

  it("puts ungrouped questions last", () => {
    const input = [q("q-free", null, 0), q("q-a0", "p1", 0)];
    expect(sortQuestionsByPart(input, [p1, p2]).map((x) => x.id))
      .toEqual(["q-a0", "q-free"]);
  });

  it("tolerates questions pointing at a missing part (goes last)", () => {
    const input = [q("q-ghost", "gone", 0), q("q-a0", "p1", 5)];
    expect(sortQuestionsByPart(input, [p1]).map((x) => x.id))
      .toEqual(["q-a0", "q-ghost"]);
  });

  it("keeps colliding positions stable by id", () => {
    const input = [q("q2", "p1", 0), q("q1", "p1", 0)];
    expect(sortQuestionsByPart(input, [p1]).map((x) => x.id))
      .toEqual(["q1", "q2"]);
  });
});

describe("isAnswered — multi_select min/max", () => {
  const ms = (min: unknown): QuizQuestion => ({
    ...q("ms", null, 0), qtype: "multi_select",
    choices: ["a", "b", "c"],
    meta: { min: min as number, max: 2 },
  });

  it("requires at least meta.min picks", () => {
    expect(isAnswered(ms(2), { sel: [0] })).toBe(false);
    expect(isAnswered(ms(2), { sel: [0, 1] })).toBe(true);
  });

  it("defaults to 1 when meta.min is missing", () => {
    expect(isAnswered(ms(undefined), { sel: [0] })).toBe(true);
    expect(isAnswered(ms(undefined), { sel: [] })).toBe(false);
  });

  it("falls back to 1 when meta.min is NaN (legacy save bug)", () => {
    expect(isAnswered(ms(NaN), { sel: [0] })).toBe(true);
    expect(isAnswered(ms(NaN), { sel: [] })).toBe(false);
  });
});

describe("isAnswered — other types", () => {
  const of = (qtype: QuizQuestion["qtype"], choices: string[] | null = null,
    meta: QuizQuestion["meta"] = {}): QuizQuestion =>
    ({ ...q("x", null, 0), qtype, choices, meta });

  it("text answers need a non-blank string", () => {
    expect(isAnswered(of("identification"), { t: "  " })).toBe(false);
    expect(isAnswered(of("identification"), { t: "volt" })).toBe(true);
  });

  it("enumeration needs at least one filled item", () => {
    expect(isAnswered(of("enumeration"), { items: ["", ""] })).toBe(false);
    expect(isAnswered(of("enumeration"), { items: ["a", ""] })).toBe(true);
  });

  it("classification needs every item placed in a zone", () => {
    const cls = of("classification", ["a", "b"], { buckets: ["x", "y"] });
    expect(isAnswered(cls, { z: [0, -1] })).toBe(false);
    expect(isAnswered(cls, { z: [0, 1] })).toBe(true);
  });

  it("ordering needs all steps placed", () => {
    const ord = of("ordering", ["a", "b"]);
    expect(isAnswered(ord, { o: [1] })).toBe(false);
    expect(isAnswered(ord, { o: [1, 0] })).toBe(true);
  });

  it("single-pick answers are answered by construction", () => {
    expect(isAnswered(of("multiple_choice"), { i: 2 })).toBe(true);
    expect(isAnswered(of("true_false"), { b: false })).toBe(true);
    expect(isAnswered(of("multiple_choice"), undefined)).toBe(false);
  });
});
