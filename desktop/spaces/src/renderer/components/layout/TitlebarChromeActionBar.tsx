import { Bell, Command, Settings } from 'lucide-react'
import clsx from 'clsx'

/** Trailing titlebar actions — matches macOS `TitlebarChromeActionBar` (bell, command, settings). */
export function TitlebarChromeActionBar({
  unreadCount = 0,
  onNotifications,
  onCommand,
  onSettings
}: {
  unreadCount?: number
  onNotifications: () => void
  onCommand: () => void
  onSettings: () => void
}): React.ReactElement {
  return (
    <div
      className="titlebar-chrome-actions flex shrink-0 items-center gap-0.5"
      role="toolbar"
      aria-label="Window actions"
    >
      <TitlebarIconButton title="Notifications" onClick={onNotifications} badge={unreadCount}>
        <Bell className="h-4 w-4" />
      </TitlebarIconButton>
      <TitlebarIconButton title="Command palette (⌘K)" onClick={onCommand}>
        <Command className="h-4 w-4" />
      </TitlebarIconButton>
      <TitlebarIconButton title="Settings" onClick={onSettings}>
        <Settings className="h-4 w-4" />
      </TitlebarIconButton>
    </div>
  )
}

function TitlebarIconButton({
  title,
  onClick,
  badge,
  children
}: {
  title: string
  onClick: () => void
  badge?: number
  children: React.ReactNode
}): React.ReactElement {
  return (
    <button
      type="button"
      title={title}
      onClick={onClick}
      className={clsx(
        'relative rounded-lg p-1.5 text-ink-secondary',
        'hover:bg-surface-muted hover:text-ink'
      )}
    >
      {children}
      {badge != null && badge > 0 ? (
        <span className="absolute -right-0.5 -top-0.5 flex h-4 min-w-4 items-center justify-center rounded-full bg-accent px-1 text-[9px] font-semibold text-white">
          {badge > 99 ? '99+' : badge}
        </span>
      ) : null}
    </button>
  )
}
