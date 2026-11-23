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
    .select("id, full_name, role, avatar_url")
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

/** Creates an account (DB trigger assigns role=student).
 *  Returns true when a session was issued (email confirmation disabled),
 *  false when the user must confirm their email first. */
export async function signUp(email: string, password: string, fullName: string, role: string): Promise<boolean> {
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: { data: { full_name: fullName, role }, emailRedirectTo: window.location.origin },
  });
  if (error) throw error;
  return data.session !== null;
}

/** Emails a password-reset link that lands on /reset-password. */
export async function sendPasswordReset(email: string): Promise<void> {
  const { error } = await supabase.auth.resetPasswordForEmail(email, {
    redirectTo: `${window.location.origin}/reset-password`,
  });
  if (error) throw error;
}

/** Called from /reset-password once the recovery link has established a session. */
export async function updatePassword(newPassword: string): Promise<void> {
  const { error } = await supabase.auth.updateUser({ password: newPassword });
  if (error) throw error;
}
