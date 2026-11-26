import { supabase } from "../lib/supabase";
import { SUBJECTS, type Profile, type Role } from "../types";

// Admin user management — requires the "profiles admin write" policy (0004).

export async function fetchProfiles(): Promise<Profile[]> {
  const { data, error } = await supabase
    .from("profiles").select("id, full_name, role").order("full_name");
  if (error) throw error;
  return (data ?? []) as Profile[];
}

export async function setProfileRole(userId: string, role: Role): Promise<void> {
  const { error } = await supabase.from("profiles").update({ role }).eq("id", userId);
  if (error) throw error;
}

/** Stores the avatar's R2 object key on the user's own profile row. */
export async function setAvatarKey(userId: string, key: string): Promise<void> {
  const { error } = await supabase.from("profiles").update({ avatar_url: key }).eq("id", userId);
  if (error) throw error;
}

// ---------- Teacher settings (profiles.settings jsonb) ----------

async function mySettings(): Promise<{ id: string; settings: Record<string, unknown> } | null> {
  const { data } = await supabase.auth.getSession();
  const id = data.session?.user.id;
  if (!id) return null;
  const { data: row } = await supabase
    .from("profiles").select("settings").eq("id", id).maybeSingle();
  return { id, settings: (row?.settings as Record<string, unknown>) ?? {} };
}

/** Teacher's subject list — synced via profiles.settings.subjects so a
 *  subject added on web exists on mobile too. Falls back to SUBJECTS. */
export async function fetchSubjects(): Promise<string[]> {
  const l = (await mySettings().catch(() => null))?.settings?.subjects;
  if (Array.isArray(l) && l.length && l.every((s) => typeof s === "string")) {
    return l as string[];
  }
  return [...SUBJECTS];
}

/** Read-modify-write merge so future settings keys aren't clobbered.
 *  Returns false when the remote write can't happen — callers can say
 *  "saved locally only" instead of silently pretending it synced. */
export async function saveSubjects(list: string[]): Promise<boolean> {
  try {
    const me = await mySettings();
    if (!me) return false;
    const { error } = await supabase.from("profiles")
      .update({ settings: { ...me.settings, subjects: list } })
      .eq("id", me.id);
    return !error;
  } catch {
    return false;
  }
}
