import { formatDistanceToNow } from 'date-fns'
import { X } from 'lucide-react'
import { useSpacesStore } from '../../stores/spaces-store'

/** Slide-over notifications — opened from titlebar bell. */
export function NotificationsPanel(): React.ReactElement | null {
  const open = useSpacesStore((s) => s.notificationsOpen)
  const setNotificationsOpen = useSpacesStore((s) => s.setNotificationsOpen)
  const notifications = useSpacesStore((s) => s.notifications)

  if (!open) return null

  return (
    <>
      <button
        type="button"
        className="fixed inset-0 z-40 bg-black/20"
        aria-label="Close notifications"
        onClick={() => setNotificationsOpen(false)}
      />
      <aside className="dt-glass-panel fixed right-0 top-12 z-50 flex max-h-[calc(100%-3rem)] w-[360px] flex-col border-l border-black/5 shadow-xl">
        <div className="dt-divider-h flex items-center justify-between px-4 py-3">
          <h2 className="text-sm font-semibold text-ink">Notifications</h2>
          <button
            type="button"
            onClick={() => setNotificationsOpen(false)}
            className="rounded p-1 text-ink-muted hover:bg-surface-muted"
          >
            <X className="h-4 w-4" />
          </button>
        </div>
        <ul className="flex-1 overflow-y-auto p-2">
          {notifications.length === 0 ? (
            <li className="px-2 py-6 text-center text-sm text-ink-muted">No notifications yet.</li>
          ) : (
            notifications.map((n) => (
              <li
                key={n.id}
                className={
                  n.read
                    ? 'mb-1 rounded-lg px-3 py-2 text-sm text-ink-secondary'
                    : 'mb-1 rounded-lg bg-accent-soft/40 px-3 py-2 text-sm'
                }
              >
                <p className="font-medium text-ink">{n.title}</p>
                {n.body ? <p className="mt-0.5 text-xs text-ink-muted">{n.body}</p> : null}
                <p className="mt-1 text-[10px] text-ink-muted">
                  {formatDistanceToNow(new Date(n.createdAt), { addSuffix: true })}
                </p>
              </li>
            ))
          )}
        </ul>
      </aside>
    </>
  )
}
