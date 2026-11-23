import { FormEvent, useState } from "react";
import { Link } from "react-router-dom";
import { sendPasswordReset } from "../services/auth";

export default function ForgotPassword() {
  const [email, setEmail] = useState("");
  const [err, setErr] = useState<string | null>(null);
  const [sent, setSent] = useState(false);

  async function submit(e: FormEvent) {
    e.preventDefault();
    try {
      await sendPasswordReset(email);
      setSent(true);
    } catch (error) {
      setErr(error instanceof Error ? error.message : String(error));
    }
  }

  if (sent)
    return (
      <div className="card login">
        <h1>Check your email</h1>
        <p>If an account exists for <strong>{email}</strong>, we sent a password-reset link.</p>
        <Link to="/login">Back to sign in</Link>
      </div>
    );

  return (
    <form className="card login" onSubmit={submit}>
      <h1>ScienceLearn</h1>
      <p>Reset your password</p>
      <label className="field"><span>Email</span>
        <input type="email" autoComplete="email" value={email} onChange={(e) => setEmail(e.target.value)} required />
      </label>
      {err && <p className="err">{err}</p>}
      <button>Send reset link</button>
      <div className="links"><Link to="/login">Back to sign in</Link></div>
    </form>
  );
}
