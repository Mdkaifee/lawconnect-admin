import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/admin/acts')({
  component: RouteComponent,
})

function RouteComponent() {
  return <div>Hello "/admin/acts"!</div>
}
