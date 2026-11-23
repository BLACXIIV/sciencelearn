import { FormEvent, useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { updatePassword } from "../services/auth";

export default function ResetPassword() {
  const nav = useNavigate();
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [err, setErr] = useState<string | null>(null);

  // Expired/invalid recovery links arrive with #error=...&error_description=...
  useEffect(() => {
    const p = new URLSearchParams(window.location.hash.slice(1));
    if (p.get("error")) setErr(p.get("error_description")?.replace(/\+/g, " ") ?? "Invalid reset link");
  }, []);

  async function submit(e: FormEvent) {
    e.preventDefault();
    if (password !== confirm) return setErr("Passwords don't match");
    try {
      await updatePassword(password);
      nav("/");
    } catch (error) {
      setErr(error instanceof Error ? error.message : String(error));
    }
  }

  return (
    <form className="card login" onSubmit={submit}>
      <h1>ScienceLearn</h1>
      <p>Choose a new password</p>
      <label className="field"><span>New password</span>
        <input type="password" minLength={6} autoComplete="new-password" value={password} onChange={(e) => setPassword(e.target.value)} required />
      </label>
      <label className="field"><span>Confirm new password</span>
        <input type="password" autoComplete="new-password" value={confirm} onChange={(e) => setConfirm(e.target.value)} required />
      </label>
      {err && <p className="err">{err}</p>}
      <button>Update password</button>
      <div className="links"><Link to="/login">Back to sign in</Link></div>
    </form>
  );
}
