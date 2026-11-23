import { useQuery } from "@tanstack/react-query";
import { getR2Url } from "../services/storage";

/** User avatar — R2 photo when avatar_url is set, initial letter otherwise. */
export default function Avatar({ name, avatarKey, size = 34 }: { name: string; avatarKey: string | null; size?: number }) {
  const url = useQuery({
    queryKey: ["r2-url", avatarKey],
    queryFn: () => getR2Url(avatarKey!),
    enabled: !!avatarKey,
    staleTime: 5 * 60 * 1000,
  });
  if (avatarKey && url.data)
    return <img className="avatar photo" src={url.data} alt={name} style={{ width: size, height: size }} />;
  return (
    <span className="avatar" style={{ width: size, height: size }}>
      {(name || "?")[0].toUpperCase()}
    </span>
  );
}
