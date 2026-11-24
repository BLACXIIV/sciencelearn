import { FormEvent, useState } from "react";
import { Link } from "react-router-dom";
import { sendPasswordReset } from "../services/auth";
import { AuthLayout } from "./auth/AuthLayout";
import loginArt from "../assets/illustrations/login.svg";
import { Button, Icon, TextField } from "../design-system";

export default function ForgotPassword() {
  const [email, setEmail] = useState("");
  const [err, setErr] = useState<string | null>(null);
  const [sent, setSent] = useState(false);
  const [busy, setBusy] = useState(false);

  async function submit(e: FormEvent) {
    e.preventDefault();
    setBusy(true);
    try {
      await sendPasswordReset(email);
      setSent(true);
    } catch (error) {
      setErr(error instanceof Error ? error.message : String(error));
    } finally {
      setBusy(false);
    }
  }

  if (sent)
    return (
      <AuthLayout
        art={loginArt}
        title="Check your email"
        subtitle={<>If an account exists for <strong>{email}</strong>, we sent a password-reset link.</>}
        footer={<Link to="/login" className="a-link">Back to sign in</Link>}
      >
        <p className="a-success" style={{ margin: 0 }}>
          <Icon name="mailVerified" size={56} />
        </p>
      </AuthLayout>
    );

  return (
    <AuthLayout
      art={loginArt}
      title="Reset your password"
      subtitle="Enter your account email and we'll send a reset link."
      footer={<Link to="/login" className="a-link">Back to sign in</Link>}
    >
      <form onSubmit={submit} className="a-form">
        <TextField
          label="Email"
          type="email"
          autoComplete="email"
          placeholder="Enter your email or username"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          required
          disabled={busy}
        />
        {err && (
          <p className="a-err" role="alert">
            <Icon name="alert" size={16} />
            {err}
          </p>
        )}
        <Button type="submit" fullWidth loading={busy}>Send reset link</Button>
      </form>
    </AuthLayout>
  );
}
