import { supabase } from "../lib/supabase";
import type { Profile, Role } from "../types";

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
