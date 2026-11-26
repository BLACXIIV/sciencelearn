// Deploy: supabase functions deploy r2-presign
// Secrets: supabase secrets set R2_ACCOUNT_ID=... R2_ACCESS_KEY_ID=... R2_SECRET_ACCESS_KEY=... R2_BUCKET=...
import { S3Client, PutObjectCommand, GetObjectCommand } from "npm:@aws-sdk/client-s3@3";
import { getSignedUrl } from "npm:@aws-sdk/s3-request-presigner@3";
import { createClient } from "npm:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};
const json = (b: unknown, status = 200) =>
  new Response(JSON.stringify(b), { status, headers: { ...cors, "Content-Type": "application/json" } });

const s3 = new S3Client({
  region: "auto",
  endpoint: `https://${Deno.env.get("R2_ACCOUNT_ID")}.r2.cloudflarestorage.com`,
  credentials: {
    accessKeyId: Deno.env.get("R2_ACCESS_KEY_ID")!,
    secretAccessKey: Deno.env.get("R2_SECRET_ACCESS_KEY")!,
  },
});
const Bucket = Deno.env.get("R2_BUCKET")!;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } } },
  );
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return json({ error: "unauthorized" }, 401);

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ error: "bad json" }, 400);
  }
  const { action, key, folder = "uploads", filename = "file", contentType } = body;

  if (action === "get") {
    const k = String(key ?? "");
    // Keys are folder/uuid-filename; anything else can't be one of ours, and
    // rejecting it also keeps the .or() filter below injection-proof.
    if (!/^[\w\-./]+$/.test(k)) return json({ error: "bad key" }, 400);
    // Avatars render for any signed-in user (roster, teacher names on cards).
    // Other objects only sign when a lesson referencing the key is visible
    // under the caller's own RLS — this client carries their JWT, so a zero-row
    // result means they may not read the file either.
    let allowed = k.startsWith("avatars/");
    if (!allowed) {
      const { data: lesson } = await supabase
        .from("lessons")
        .select("id")
        .or(`thumbnail_key.eq."${k}",content_key.eq."${k}"`)
        .limit(1);
      allowed = (lesson?.length ?? 0) > 0;
    }
    if (!allowed) return json({ error: "forbidden" }, 403);
    const url = await getSignedUrl(s3, new GetObjectCommand({ Bucket, Key: k }), { expiresIn: 3600 });
    return json({ url });
  }

  if (action === "put") {
    // avatars/ is open to every signed-in user (profile photos are self-owned);
    // all other folders stay teacher-only.
    const safeFolder = String(folder).replace(/[^\w-]/g, "_");
    if (safeFolder !== "avatars") {
      const { data: isTeacher } = await supabase.rpc("is_teacher");
      if (!isTeacher) return json({ error: "forbidden" }, 403);
    } else if (contentType && !String(contentType).startsWith("image/")) {
      return json({ error: "avatars must be images" }, 400);
    }
    const safe = String(filename).replace(/[^\w.\-]/g, "_");
    const newKey = safeFolder === "avatars"
      ? `avatars/${user.id}/${crypto.randomUUID()}-${safe}`
      : `${safeFolder}/${crypto.randomUUID()}-${safe}`;
    const url = await getSignedUrl(
      s3,
      new PutObjectCommand({ Bucket, Key: newKey, ContentType: contentType }),
      { expiresIn: 600 },
    );
    return json({ url, key: newKey });
  }
  return json({ error: "bad action" }, 400);
});
