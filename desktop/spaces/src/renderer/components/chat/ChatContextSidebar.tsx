import { Hash, Plus } from 'lucide-react'
import clsx from 'clsx'
import { useChatStore } from '../../stores/chat-store'

/** Column 2 — chat channels when Chat is selected in the main nav. */
export function ChatContextSidebar(): React.ReactElement {
  const channels = useChatStore((s) => s.channels)
  const sidebarSearchQuery = useChatStore((s) => s.sidebarSearchQuery)
  const activeChannelId = useChatStore((s) => s.activeChannelId)
  const setActiveChannel = useChatStore((s) => s.setActiveChannel)
  const createChannel = useChatStore((s) => s.createChannel)

  return (
    <div className="flex min-h-0 flex-1 flex-col overflow-hidden">
      <div className="px-3 py-2">
        <button
          type="button"
          className="library-cta-pill w-full justify-center text-xs"
          onClick={() => {
            const name = window.prompt('Channel name')
            if (name) createChannel(name)
          }}
        >
          <Plus className="h-3.5 w-3.5" />
          New channel
        </button>
      </div>
      <p className="library-section-label">Channels</p>
      <nav className="flex-1 space-y-0.5 overflow-y-auto px-2 pb-2">
        {channels
          .filter((ch) => {
            const q = sidebarSearchQuery.trim().toLowerCase()
            if (!q) return true
            return ch.name.toLowerCase().includes(q) || ch.description.toLowerCase().includes(q)
          })
          .map((ch) => (
          <button
            key={ch.id}
            type="button"
            onClick={() => setActiveChannel(ch.id)}
            className={clsx(
              'library-nav-row w-full text-sm',
              activeChannelId === ch.id && 'library-nav-row-active'
            )}
          >
            <Hash className="h-4 w-4 shrink-0" />
            <span className="truncate">{ch.name}</span>
            {ch.unread > 0 ? (
              <span className="ml-auto rounded-full bg-accent px-1.5 text-[10px] font-semibold text-white">
                {ch.unread}
              </span>
            ) : null}
          </button>
        ))}
      </nav>
    </div>
  )
}
