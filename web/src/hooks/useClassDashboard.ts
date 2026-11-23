import { useMemo } from "react";
import { useQuery } from "@tanstack/react-query";
import { fetchClassDashboard } from "../services/dashboard";
import { computeClassStats } from "../utils/stats";

/** Class dashboard data plus its derived stat cards. */
export function useClassDashboard() {
  const query = useQuery({ queryKey: ["class-dashboard"], queryFn: fetchClassDashboard });
  const stats = useMemo(
    () => computeClassStats(query.data?.students ?? [], query.data?.completedLessons ?? 0),
    [query.data],
  );
  return { ...query, stats };
}
