import { useAuth } from "../../hooks/useAuth";
import { signOut } from "../../services/auth";

export default function StudentAccount() {
  const { profile } = useAuth();
  return (
    <>
      <div className="card account-brand">
        <h2>⚗ ScienceLearn</h2>
        <p>Learn • Explore • Excel</p>
        {profile && <p><strong>{profile.full_name}</strong> — {profile.role}</p>}
      </div>
      <div className="card"><strong>Developed by</strong><p>Regym R. Medina</p></div>
      <div className="card"><strong>With the support of</strong><p>The Notre Dame of Isulan, Inc.</p></div>
      <div className="card"><strong>References</strong><p>DepEd MATATAG Curriculum, Trusted Scientific Resources</p></div>
      <button className="secondary" onClick={signOut}>Sign out</button>
    </>
  );
}
