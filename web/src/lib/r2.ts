import { supabase } from "./supabase";

/** Upload a file to Cloudflare R2 via a presigned PUT URL. Returns the R2 object key. */
export async function uploadToR2(file: File, folder: "thumbnails" | "lessons" | "avatars"): Promise<string> {
  const { data, error } = await supabase.functions.invoke("r2-presign", {
    body: { action: "put", folder, filename: file.name, contentType: file.type },
  });
  if (error) throw error;
  const res = await fetch(data.url, { method: "PUT", body: file, headers: { "Content-Type": file.type } });
  if (!res.ok) throw new Error(`R2 upload failed (${res.status})`);
  return data.key as string; // store this in lessons.thumbnail_key / content_key
}

/** Signed GET URL for display/download. */
export async function getR2Url(key: string): Promise<string> {
  const { data, error } = await supabase.functions.invoke("r2-presign", { body: { action: "get", key } });
  if (error) throw error;
  return data.url as string;
}
// NOTE: configure a CORS rule on the R2 bucket allowing PUT/GET from your web origin.
