import { Card, EmptyState } from "../../design-system";
import "../teacher.css";

/** Placeholder for nav routes with no screen yet (Review Content, Reports,
 *  teacher Account). No backend — just a friendly dead end. */
export default function ComingSoon() {
  return (
    <Card variant="white">
      <EmptyState
        icon="tip"
        title="Coming soon"
        body="This section is on the way — check back after the next update."
      />
    </Card>
  );
}
