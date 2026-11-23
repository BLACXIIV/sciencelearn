import type { Session, Subscription } from "@supabase/supabase-js";
import { supabase } from "../lib/supabase";
import type { Profile } from "../types";

/** Current persisted session, or null when signed out. */
export const getSession = (): Promise<Session | null> =>
  supabase.auth.getSession().then(({ data }) => data.session);

/** Subscribe to auth changes; returns the subscription to unsubscribe on cleanup. */
export const onAuthStateChange = (cb: (session: Session | null) => void): Subscription =>
  supabase.auth.onAuthStateChange((_event, session) => cb(session)).data.subscription;

export async function fetchProfile(userId: string): Promise<Profile | null> {
  const { data, error } = await supabase
    .from("profiles")
    .select("id, full_name, role")
    .eq("id", userId)
    .single();
  if (error) throw error;
  return data as Profile;
}

/** Resolves on success; rejects with the Supabase auth error on failure. */
export async function signInWithPassword(email: string, password: string): Promise<void> {
  const { error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) throw error;
}

export const signOut = (): Promise<void> => supabase.auth.signOut().then(({ error }) => {
  if (error) throw error;
});
