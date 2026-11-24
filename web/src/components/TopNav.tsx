import { useQuery } from "@tanstack/react-query";
import { Avatar, Card } from "../design-system";
import { useAuth } from "../hooks/useAuth";
import { getR2Url } from "../services/storage";
import "./shell.css";

/** Top bar: profile block on the right (name, role, avatar).
 *  Chrome is a flat DS Card; layout lives in shell.css (.sh-top). */
export default function TopNav() {
  const { profile } = useAuth();
  const avatarKey = profile?.avatar_url ?? null;
  // Same R2 signed-URL lookup the old Avatar component ran.
  const url = useQuery({
    queryKey: ["r2-url", avatarKey],
    queryFn: () => getR2Url(avatarKey!),
    enabled: !!avatarKey,
    staleTime: 5 * 60 * 1000,
  });
  return (
    <Card variant="flat" className="sh-top">
      <div className="sh-user">
        <div className="sh-who">
          <div className="sh-nm">{profile?.full_name ?? "…"}</div>
          <div className="sh-rl">{profile?.role ?? ""}</div>
        </div>
        <Avatar name={profile?.full_name ?? ""} src={url.data} size={38} />
      </div>
    </Card>
  );
}
