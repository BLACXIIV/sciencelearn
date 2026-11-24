import { FormEvent, useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { updatePassword } from "../services/auth";
import { AuthLayout } from "./auth/AuthLayout";
import loginArt from "../assets/illustrations/login.svg";
import { Button, Icon, PasswordField } from "../design-system";

export default function ResetPassword() {
  const nav = useNavigate();
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const [err, setErr] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  // Expired/invalid recovery links arrive with #error=...&error_description=...
  useEffect(() => {
    const p = new URLSearchParams(window.location.hash.slice(1));
    if (p.get("error")) setErr(p.get("error_description")?.replace(/\+/g, " ") ?? "Invalid reset link");
  }, []);

  async function submit(e: FormEvent) {
    e.preventDefault();
    if (password !== confirm) return setErr("Passwords don't match");
    setBusy(true);
    try {
      await updatePassword(password);
      nav("/");
    } catch (error) {
      setErr(error instanceof Error ? error.message : String(error));
      setBusy(false);
    }
  }

  return (
    <AuthLayout
      art={loginArt}
      title="Choose a new password"
      subtitle="Enter a new password for your account."
      footer={<Link to="/login" className="a-link">Back to sign in</Link>}
    >
      <form onSubmit={submit} className="a-form">
        <PasswordField
          label="New password"
          minLength={6}
          autoComplete="new-password"
          placeholder="Create a password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          required
          disabled={busy}
        />
        <PasswordField
          label="Confirm new password"
          autoComplete="new-password"
          placeholder="Re-enter your password"
          value={confirm}
          onChange={(e) => setConfirm(e.target.value)}
          required
          disabled={busy}
        />
        {err && (
          <p className="a-err" role="alert">
            <Icon name="alert" size={16} />
            {err}
          </p>
        )}
        <Button type="submit" fullWidth loading={busy}>Update password</Button>
      </form>
    </AuthLayout>
  );
}
