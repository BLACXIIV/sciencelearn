import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { fetchProfiles, setProfileRole } from "../services/users";
import { useAuth } from "../hooks/useAuth";
import type { Role } from "../types";

const ROLES: Role[] = ["student", "teacher", "admin"];

/** Admin: list every profile and change its role (profiles admin write policy, 0004). */
export default function Users() {
  const { profile } = useAuth();
  const qc = useQueryClient();
  const users = useQuery({ queryKey: ["profiles"], queryFn: fetchProfiles });
  const setRole = useMutation({
    mutationFn: ({ id, role }: { id: string; role: Role }) => setProfileRole(id, role),
    onSuccess: () => qc.invalidateQueries({ queryKey: ["profiles"] }),
  });

  if (profile?.role !== "admin") return <p className="empty">Admins only.</p>;
  if (users.isLoading) return <p>Loading users…</p>;
  if (users.error) return <p className="err">{String(users.error)}</p>;

  return (
    <div className="card">
      <h3>Users</h3>
      {setRole.error && <p className="err">{String(setRole.error)}</p>}
      {users.data?.map((u) => (
        <div key={u.id} className="perf">
          <span>{u.full_name || "(no name)"}</span>
          <small>{u.id.slice(0, 8)}…</small>
          <select
            className="role-select"
            value={u.role}
            onChange={(e) => setRole.mutate({ id: u.id, role: e.target.value as Role })}
            disabled={u.id === profile.id || setRole.isPending}
          >
            {ROLES.map((r) => <option key={r} value={r}>{r}</option>)}
          </select>
        </div>
      ))}
      {users.data?.length === 0 && <p className="empty">No users yet.</p>}
    </div>
  );
}
