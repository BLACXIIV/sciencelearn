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

  const { action, key, folder = "uploads", filename = "file", contentType } = await req.json();

  if (action === "get") {
    const url = await getSignedUrl(s3, new GetObjectCommand({ Bucket, Key: key }), { expiresIn: 3600 });
    return json({ url });
  }

  if (action === "put") {
    const { data: isTeacher } = await supabase.rpc("is_teacher");
    if (!isTeacher) return json({ error: "forbidden" }, 403);
    const safe = String(filename).replace(/[^\w.\-]/g, "_");
    const newKey = `${folder}/${crypto.randomUUID()}-${safe}`;
    const url = await getSignedUrl(
      s3,
      new PutObjectCommand({ Bucket, Key: newKey, ContentType: contentType }),
      { expiresIn: 600 },
    );
    return json({ url, key: newKey });
  }
  return json({ error: "bad action" }, 400);
});
