# Manual QA — Quiz builder flow (Step 2)

Pre-flight: apply `supabase/migrations/0032_builder.sql` per `docs/runbooks/0032-live.md`.
Items marked **[pre-migration]** are the expected behavior *before* the
migration lands (graceful degradation); re-check them with the migration
applied — the graceful state must disappear and the feature must work.

Legend: ✅ expected pass · ⛔ expected blocked/error state (must be friendly, never a crash).

---

## 1. Create

| # | Platform | Steps | Expected |
|---|----------|-------|----------|
| 1.1 | Web | `/teacher/c/:classId/quiz` → pick a lesson → "New activity": title + description → Create | Card appears in the lesson's list: title, `0 parts · 0 questions`, Draft chip, Instant scores chip |
| 1.2 | Mobile | Create Quiz tab → pick a lesson → "New activity" card → Create | Same; row shows title + `0 parts · 0 questions` |
| 1.3 | Web | Open the new activity | Builder loads: navy header (title, `0 parts · 0 questions`, release chip, Draft switch), empty parts outline, "Add questions to publish" hint |
| 1.4 | Mobile | Tap the activity card | Builder loads: navy header with same fields, "Add part" dashed chip, sticky bottom bar (Preview outline + Add question) |

## 2. Publish guard (requires 0032)

| # | Platform | Steps | Expected |
|---|----------|-------|----------|
| 2.1 | Web | Activity with **0 questions** → click the Draft switch | ⛔ Switch does not flip; teacher sees "Add questions to publish" |
| 2.2 | Mobile | Same via the teal switch in the header | ⛔ Same — plus the switch is disabled while the count is 0 |
| 2.3 | Web | Add 1 question → flip the switch | ✅ Publishes; chip reads Published |
| 2.4 | Web | While published: rename, toggle release mode, unpublish, re-publish | ✅ All pass — the guard only fires on false→true with 0 questions |
| 2.5 | Both | **[pre-migration]** try to publish at 0 questions | Switch flips locally (no trigger) — acceptable pre-migration; no crash |

## 3. All 8 question types

For each type: create → save → confirm the row shows the right type chip,
prompt excerpt and answer hint; then answer it in Preview.

| # | Type | Editor contents | Expected answer hint on the row |
|---|------|-----------------|----------------------------------|
| 3.1 | Multiple Choice | prompt, ≥2 choices, radio-correct | `Answer: <correct text>` |
| 3.2 | Multi-Select | prompt, ≥2 choices, tick ≥1 correct, min/max, partial toggle | `N correct` |
| 3.3 | True or False | prompt, True/False pill | `Answer: True/False` |
| 3.4 | Fill in the Blank | prompt with `[blank]` inserted via the button, options + radio-correct | `Answer: <correct option>` |
| 3.5 | Identification | prompt, ≥1 accepted answer | `Answer: <first>` (+n) |
| 3.6 | Enumeration | prompt, ≥2 items, ordered + partial toggles | `N items` |
| 3.7 | Classification | optional context, ≥2 zones, ≥2 items each mapped to a zone | `N zones` |
| 3.8 | Ordering | ≥2 items in correct order, shuffle toggle | `N steps` |

Validation to spot-check (both platforms): MC with <2 choices → "Add at
least two choices."; fill_blank without `[blank]` → "Insert [blank] where
the gap is."; enumeration with 1 item → blocked. Errors must keep the
editor open and show the message — never a raw exception or a silent close.

## 4. Preview (read-only)

| # | Platform | Steps | Expected |
|---|----------|-------|----------|
| 4.1 | Web | Builder → Preview (or `...` → Preview on a card) | `/teacher/c/:classId/quiz/preview/:id` opens the student runner UI with a banner: **"Preview — answers are not saved"** |
| 4.2 | Mobile | Builder bottom bar → Preview | Runner opens in preview mode with the same banner |
| 4.3 | Both | Answer questions, navigate parts | ✅ Answering works locally; **no submit button anywhere** — Exit preview instead |
| 4.4 | Both | Answer everything, check for a submit path | ⛔ None — preview never writes attempts/answers |
| 4.5 | Both | Preview an activity whose parts/questions span multiple parts | Part sections render in part-position order with titles/directions — same as the student runner |
| 4.6 | Web | **[pre-migration]** open Preview | "Preview is not available yet" — friendly empty state, no crash/blank screen |
| 4.7 | Mobile | **[pre-migration]** same | `_previewUnavailable` state, same copy |
| 4.8 | Web | As a **student**, hit the preview URL directly | ⛔ RPC returns Not allowed → friendly message (teacher-gated) |
| 4.9 | Web | Teacher A previews teacher B's assessment id | ⛔ "Not allowed" (RPC-side `teaches_class` gate) |

## 5. Reorder

| # | Platform | Steps | Expected |
|---|----------|-------|----------|
| 5.1 | Web | Drag a question row by its grip handle up/down | Row moves; positions persist dense (`0..n-1`) after reload |
| 5.2 | Web | `...` on a row → Move up / Move down (keyboard fallback) | Same result — required for keyboard users |
| 5.3 | Mobile | Long-press a row's grip → drag | Same; dense positions after reload |
| 5.4 | Both | Move the first row up / last row down | ⛔ No-op (edge clamped), no errors |
| 5.5 | Web | Reorder **parts** (outline column) | Parts re-rank; question columns follow their part |
| 5.6 | Both | Reload the page | Order exactly as left — positions persisted |

## 6. Move to part

| # | Platform | Steps | Expected |
|---|----------|-------|----------|
| 6.1 | Web | Open a question → change its Part dropdown → save | Question leaves its scope, lands at the **end** of the target part's list; source positions re-densify |
| 6.2 | Mobile | Same via the Part select at the top of the question sheet | Same |
| 6.3 | Both | Move a question to "Ungrouped" | It leaves the part and shows under the ungrouped section ("pick a Part inside each item to file it") |
| 6.4 | Both | Ungrouped item → assign a part | Files into that part's list |

## 7. Rename

| # | Platform | Steps | Expected |
|---|----------|-------|----------|
| 7.1 | Web | Builder header pencil → new title/description → save | Header + picker card update |
| 7.2 | Mobile | Header pencil → rename sheet → save | Same |
| 7.3 | Both | Empty title → save | ⛔ "Enter a title." — no write |

## 8. Release settings

| # | Platform | Steps | Expected |
|---|----------|-------|----------|
| 8.1 | Web | Builder header release dropdown | Three entries visible: "Instant scores", "Manual release", and (manual + unreleased only) "Release scores now" |
| 8.2 | Web | Card `...` → Release settings | Same choices — identical control |
| 8.3 | Mobile | Tap the release chip in the header | Bottom sheet: Instant scores / Manual release radios; "Release scores now" button only when manual + not yet released |
| 8.4 | Mobile | Card `...` → Release settings | Same sheet |
| 8.5 | Both | Pick "Release scores now" | Confirm dialog first ("students who already took this will see scores right away") → chip flips to "Scores released"; the button disappears |
| 8.6 | Both | Manual + unreleased: verify student runner | Student who submitted sees "scores not yet released" state, not their score |
| 8.7 | Both | Instant mode: verify | Score visible immediately after submit |

## 9. Delete guards (requires 0032)

| # | Platform | Steps | Expected |
|---|----------|-------|----------|
| 9.1 | Web | Activity **with attempts** → delete (card `...` or builder) | ⛔ "Students already took this. Unpublish it instead." — row survives |
| 9.2 | Mobile | Same | ⛔ Pre-check shows "Can't delete this — students already took this, unpublish instead" modal **before** the confirm (no delete attempted) |
| 9.3 | Both | Activity with 0 attempts → confirm → delete | ✅ Gone from the picker |
| 9.4 | Both | Delete a **part** with questions → confirm | Confirm copy names the part + its question count; part and questions gone |
| 9.5 | Both | Delete a single question | Row gone, positions re-densify |
| 9.6 | Web | Delete a **lesson** that has activities | ⛔ Friendly block (FK RESTRICT) — no raw Postgres error text |
| 9.7 | Web | Delete a **class** that has activities | ⛔ Same friendly handling |

## 10. Danger zone (Students screen)

| # | Platform | Steps | Expected |
|---|----------|-------|----------|
| 10.1 | Web | `/teacher/c/:classId/students` → Danger zone | Copy reads: "Deleting removes the class and its lessons. A class that still has activities cannot be deleted yet." |
| 10.2 | Web | Class with ≥1 activity | Delete-class button **disabled** with the explanation/tooltip |
| 10.3 | Web | Class with 0 activities | Button enabled; delete proceeds |
| 10.4 | Web | If the delete still fails (race) | Friendly message, not a raw FK error |

## 11. Menus & polish

| # | Platform | Steps | Expected |
|---|----------|-------|----------|
| 11.1 | Web | Open a `...` popover near the viewport bottom | Menu **flips upward** instead of clipping off-screen |
| 11.2 | Web | Popover open → click outside / press Escape | Closes |
| 11.3 | Both | Old link `lessons/:lessonId/activities` | Redirects to the picker (web) preserving the lesson |
| 11.4 | Both | Resize / rotate | No overflow; mobile rows keep ≥44px targets |
| 11.5 | Both | Switch class then reopen the builder | No stale data — providers are class-scoped |

## 12. Regression spot-checks

- Student runner still works end-to-end for a published activity (answer → submit → score).
- Attempt paper sheet (manual scoring view) still renders.
- `node scripts/check-design.mjs` and `dart run tool/check_design.dart` remain at 0 violations.
