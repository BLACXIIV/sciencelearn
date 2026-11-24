import { useRef, useState, type ChangeEvent } from "react";
import { useQuery } from "@tanstack/react-query";
import { Avatar, Button, Card, Divider } from "../../design-system";
import { useAuth } from "../../hooks/useAuth";
import { signOut } from "../../services/auth";
import { getR2Url, uploadToR2 } from "../../services/storage";
import { setAvatarKey } from "../../services/users";
import "./student.css";

const ABOUT: { label: string; value: string }[] = [
  { label: "Developed by", value: "Regym R. Medina" },
  { label: "With the support of", value: "The Notre Dame of Isulan, Inc." },
  { label: "References", value: "DepEd MATATAG Curriculum, Trusted Scientific Resources" },
];

export default function StudentAccount() {
  const { session, profile, refreshProfile } = useAuth();
  const fileRef = useRef<HTMLInputElement>(null);
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  const avatarKey = profile?.avatar_url ?? null;
  const url = useQuery({
    queryKey: ["r2-url", avatarKey],
    queryFn: () => getR2Url(avatarKey!),
    enabled: !!avatarKey,
    staleTime: 5 * 60 * 1000,
  });

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
    <div className="sd-stack">
      <Card>
        <div className="sd-center">
          <Avatar name={profile?.full_name ?? ""} src={url.data} size={72} />
          <h2 className="ds-h2 sd-brand">
            <img src="/logo.png" alt="" width={28} height={28} />
            ScienceLearn
          </h2>
          <p className="ds-body-sm sd-tagline">Learn • Explore • Excel</p>
          {profile && (
            <p className="ds-body">
              <strong>{profile.full_name}</strong> · {profile.role}
            </p>
          )}
          <input ref={fileRef} type="file" accept="image/*" hidden onChange={pick} />
          <Button
            variant="outline"
            leadingIcon="camera"
            loading={busy}
            onClick={() => fileRef.current?.click()}
          >
            {busy ? "Uploading…" : "Change photo"}
          </Button>
          {err && <p className="sd-err">{err}</p>}
        </div>
      </Card>

      <Card>
        {ABOUT.map((a, i) => (
          <div key={a.label}>
            {i > 0 && <Divider />}
            <div className="sd-about">
              <span className="ds-label">{a.label}</span>
              <span className="ds-body-sm">{a.value}</span>
            </div>
          </div>
        ))}
      </Card>

      <p className="sd-dim sd-center-text"><em>Together for a brighter future</em></p>
      <Button variant="outline" leadingIcon="signOut" onClick={signOut}>Sign out</Button>
    </div>
  );
}
