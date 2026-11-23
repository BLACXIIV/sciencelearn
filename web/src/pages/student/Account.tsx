import { useRef, useState, type ChangeEvent } from "react";
import Avatar from "../../components/Avatar";
import { E } from "../../components/icons";
import { useAuth } from "../../hooks/useAuth";
import { signOut } from "../../services/auth";
import { uploadToR2 } from "../../services/storage";
import { setAvatarKey } from "../../services/users";

export default function StudentAccount() {
  const { session, profile, refreshProfile } = useAuth();
  const fileRef = useRef<HTMLInputElement>(null);
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  async function pick(e: ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file || !session) return;
    setBusy(true);
    setErr(null);
    try {
      const key = await uploadToR2(file, "avatars");
      await setAvatarKey(session.user.id, key);
      await refreshProfile();
    } catch (error) {
      setErr(String(error));
    } finally {
      setBusy(false);
    }
  }

  return (
    <>
      <div className="card account-brand">
        <Avatar name={profile?.full_name ?? ""} avatarKey={profile?.avatar_url ?? null} size={72} />
        <h2 style={{ display: "flex", alignItems: "center", gap: 8 }}>
          <E name="science" size={28} />ScienceLearn
        </h2>
        <p>Learn • Explore • Excel</p>
        {profile && <p><strong>{profile.full_name}</strong> · {profile.role}</p>}
        <input ref={fileRef} type="file" accept="image/*" hidden onChange={pick} />
        <button className="secondary" onClick={() => fileRef.current?.click()} disabled={busy}>
          {busy ? "Uploading…" : "Change photo"}
        </button>
        {err && <p className="err">{err}</p>}
      </div>
      <div className="card"><strong>Developed by</strong><p>Regym R. Medina</p></div>
      <div className="card"><strong>With the support of</strong><p>The Notre Dame of Isulan, Inc.</p></div>
      <div className="card"><strong>References</strong><p>DepEd MATATAG Curriculum, Trusted Scientific Resources</p></div>
      <p className="empty"><em>Together for a Brighter Future</em></p>
      <button className="secondary" onClick={signOut}>Sign out</button>
    </>
  );
}
