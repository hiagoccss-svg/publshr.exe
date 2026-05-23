import { formatDistanceToNow } from 'date-fns'
import { Send } from 'lucide-react'
import { useEffect } from 'react'
import { useChatStore } from '../../stores/chat-store'
import { useSpacesStore } from '../../stores/spaces-store'

/** Column 3 — enterprise chat thread and composer. */
export function ChatWorkspace(): React.ReactElement {
  const hydrate = useChatStore((s) => s.hydrate)
  const hydrated = useChatStore((s) => s.hydrated)
  const channels = useChatStore((s) => s.channels)
  const messages = useChatStore((s) => s.messages)
  const activeChannelId = useChatStore((s) => s.activeChannelId)
  const draft = useChatStore((s) => s.draft)
  const setDraft = useChatStore((s) => s.setDraft)
  const sendMessage = useChatStore((s) => s.sendMessage)
  const currentUserId = useSpacesStore((s) => s.currentUserId)
  const currentUserName = useSpacesStore((s) => s.currentUserName)

  useEffect(() => {
    if (!hydrated) hydrate()
  }, [hydrated, hydrate])

  const channel = channels.find((c) => c.id === activeChannelId)
  const thread = messages.filter((m) => m.channelId === activeChannelId)

  return (
    <div className="flex h-full min-h-0 flex-col">
      <header className="dt-divider-h shrink-0 px-6 py-4">
        <h1 className="text-lg font-semibold text-ink">#{channel?.name ?? 'chat'}</h1>
        <p className="text-sm text-ink-muted">{channel?.description ?? 'Team messaging'}</p>
      </header>

      <div className="min-h-0 flex-1 overflow-y-auto px-6 py-4">
        {thread.length === 0 ? (
          <p className="text-sm text-ink-muted">No messages yet. Say hello to the team.</p>
        ) : (
          <ul className="space-y-4">
            {thread.map((m) => (
              <li key={m.id} className="flex gap-3">
                <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-accent-soft text-xs font-semibold text-accent">
                  {m.authorName.slice(0, 1).toUpperCase()}
                </div>
                <div className="min-w-0 flex-1">
                  <div className="flex items-baseline gap-2">
                    <span className="text-sm font-semibold text-ink">{m.authorName}</span>
                    <span className="text-[10px] text-ink-muted">
                      {formatDistanceToNow(new Date(m.createdAt), { addSuffix: true })}
                    </span>
                  </div>
                  <p className="mt-0.5 whitespace-pre-wrap text-sm text-ink-secondary">{m.body}</p>
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>

      <form
        className="dt-divider-h shrink-0 px-6 py-4"
        onSubmit={(e) => {
          e.preventDefault()
          sendMessage(currentUserId || 'local-user', currentUserName || 'You')
        }}
      >
        <div className="flex gap-2">
          <input
            value={draft}
            onChange={(e) => setDraft(e.target.value)}
            placeholder={`Message #${channel?.name ?? 'general'}`}
            className="dt-content-input min-w-0 flex-1 rounded-lg px-3 py-2 text-sm text-ink placeholder:text-ink-muted focus:outline-none focus:ring-2 focus:ring-accent/15"
          />
          <button
            type="submit"
            disabled={!draft.trim()}
            className="flex items-center gap-1 rounded-lg bg-accent px-3 py-2 text-sm font-medium text-white hover:bg-accent-hover disabled:opacity-40"
          >
            <Send className="h-4 w-4" />
            Send
          </button>
        </div>
      </form>
    </div>
  )
}
