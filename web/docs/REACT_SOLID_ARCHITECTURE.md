# ScienceLearn Web — React SOLID Architecture

Teacher/admin portal: React 18 + Vite + TypeScript, Supabase (PostgreSQL + RLS) backend,
Cloudflare R2 media via the `r2-presign` edge function. The Flutter student app (`mobile/`)
and everything under `supabase/` are out of scope for frontend changes.

## Folder structure

```
src/
├── lib/            Infrastructure clients (no domain knowledge)
│   ├── supabase.ts     Supabase client singleton — the ONLY place env vars are read
│   └── queryClient.ts  React Query client configuration
├── types/          Domain contracts shared by every layer (mirror the DB schema)
├── services/       Data access + external gateways; the ONLY layer that talks to lib/
│   ├── auth.ts         session, profile fetch, sign-in/out
│   ├── storage.ts      R2 presigned upload/download via edge function
│   ├── lessons.ts      lessons CRUD
│   └── dashboard.ts    class-dashboard aggregate queries
├── hooks/          Reusable stateful logic (React Query bindings, auth context)
│   ├── useAuth.tsx     AuthProvider + useAuth (session + profile)
│   ├── useLessons.ts   lesson list query + create/publish mutations
│   └── useClassDashboard.ts  dashboard query + derived stats
├── utils/          Pure functions (computeClassStats)
├── components/     Presentational building blocks + route guard + shell
│   ├── RequireTeacher.tsx  route protection (reads auth, renders <Outlet/> or redirects)
│   ├── AppLayout.tsx       sidebar/header shell (rendered inside the guard)
│   ├── StatCards.tsx       config-driven stat grid
│   ├── StudentProgressList.tsx
│   ├── LessonForm.tsx      owns its field state; resets on successful create
│   └── LessonList.tsx
├── pages/          Thin route targets: wire hooks to components, nothing else
├── App.tsx         Route table only
└── main.tsx        Provider composition only
```

## Layers and dependency flow

```
pages ──► components ──► hooks ──► services ──► lib (supabase client, query client)
              │             │
              └─────────────┴──► types, utils  (pure, no side effects)
```

Rules:

- Components/pages never import `lib/supabase` — all data access goes through `services/`.
- Services never import React — they are plain async functions returning domain types.
- `types/` mirrors `supabase/migrations/0001_init.sql`; update it when the schema changes.
- `utils/` holds pure transformations only — no I/O, no React.

## SOLID mapping

- **SRP** — each module has one job: pages compose, components render, hooks own
  query/mutation state, services own data access, `utils/stats.ts` owns derived math.
- **OCP** — stat cards are data-driven (`StatItem[]`), sidebar entries come from
  `NAV_ITEMS`, subjects come from the `SUBJECTS` constant. Adding a stat, nav entry,
  or subject is a data change, not a markup change.
- **LSP** — every service function honors one contract: resolve with domain types on
  success, reject with the underlying error on failure. No silent `?? []` fallbacks
  and no `any` — a `Lesson` is a `Lesson` everywhere.
- **ISP** — services are split per domain (`auth`, `storage`, `lessons`, `dashboard`);
  hooks expose narrow surfaces (`useLessons` vs `useClassDashboard`); components take
  only the props they render.
- **DIP** — components depend on hook/service abstractions, never on the Supabase
  client. Auth session/profile details live behind `services/auth.ts`; R2 behind
  `services/storage.ts`. Swapping the backend means changing services, not UI.

## Backend contracts that must not change

- Tables/views used: `profiles`, `lessons`, `lesson_progress`, `v_student_progress`.
- Edge function: `r2-presign` with `{action:"put"|"get", ...}` bodies.
- Auth: `signInWithPassword`, session listener, RLS does the real authorization —
  `RequireTeacher` is a UX gate, not a security boundary.

## Adding a new module (recipe)

1. Add its domain types to `types/` (or a new `types/<domain>.ts` if it grows).
2. Create `services/<domain>.ts` with plain async functions over `lib/supabase`.
3. Create `hooks/use<Domain>.ts` exposing `useQuery`/`useMutation` wrappers.
4. Build a presentational component in `components/`; keep state in hooks, not markup.
5. Compose them in a page; add a route in `App.tsx` (inside `RequireTeacher` if protected)
   and a `NAV_ITEMS` entry in `AppLayout.tsx` if it belongs in the sidebar.

## Known limitations

- No test framework or linter is configured yet. `utils/stats.ts` and the services are
  deliberately pure/narrow so they are cheap to unit test (e.g. Vitest) when added.
- `LessonForm` file inputs keep the previously picked `File` object on failed submit,
  matching pre-refactor behavior.
