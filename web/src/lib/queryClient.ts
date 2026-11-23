import { QueryClient } from "@tanstack/react-query";

// Central react-query configuration; import this instead of constructing ad-hoc clients.
export const queryClient = new QueryClient();
