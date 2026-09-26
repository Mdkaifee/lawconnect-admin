import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/admin/updates')({
  component: RouteComponent,
})

function RouteComponent() {
  return <div>Hello "/admin/updates"!</div>
}
