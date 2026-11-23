# ScienceLearn

| Layer | Tech |
|---|---|
| Student app | Flutter (`mobile/`) |
| Teacher/admin web | React + Vite + TypeScript (`web/`) |
| Database / Auth | Supabase PostgreSQL + RLS (`supabase/migrations`) |
| Media storage | Cloudflare R2, accessed only through presigned URLs (`supabase/functions/r2-presign`) |

## Setup
1. **Supabase**: create a project → run `supabase/migrations/0001_init.sql` (SQL editor or `supabase db push`).
   Promote your teacher account: `update profiles set role='teacher' where id='<uuid>';`
2. **R2**: create a bucket (private). Create an API token (Object Read & Write). Add a CORS rule allowing
   `GET, PUT` from your web origin and `Content-Type` header.
3. **Edge Function**:
   ```
   supabase secrets set R2_ACCOUNT_ID=... R2_ACCESS_KEY_ID=... R2_SECRET_ACCESS_KEY=... R2_BUCKET=...
   supabase functions deploy r2-presign
   ```
4. **Web**: `cd web && cp .env.example .env && npm i && npm run dev`
5. **Mobile**: `cd mobile && flutter create . --platforms=android,ios && flutter pub get`
   `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
   (Android needs `<uses-permission android:name="android.permission.INTERNET"/>`; url_launcher needs queries on Android 11+.)

## Roadmap
1. Auth + roles  2. Lessons + R2 upload  3. Quiz engine (submit_attempt RPC)  4. Pre/Post-test + gain
5. Review Center content  6. Teacher dashboard + reports (CSV export)  7. Offline cache, notifications, polish
