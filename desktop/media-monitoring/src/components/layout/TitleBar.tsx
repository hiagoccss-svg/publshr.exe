import { Search } from 'lucide-react'
import { useMonitoringStore } from '@/store/monitoringStore'
import { cursor } from '@/theme/cursor'

export function TitleBar() {
  const { searchQuery, setSearchQuery, displayName, userEmail } = useMonitoringStore()

  return (
    <header
      className="flex items-center gap-3 px-3 shrink-0 border-b app-drag"
      style={{
        height: cursor.titleBarHeight,
        backgroundColor: cursor.titleBar,
        borderColor: cursor.border
      }}
    >
      <div className="w-[70px] shrink-0 app-no-drag" />
      <div
        className="flex-1 flex items-center gap-2 max-w-2xl mx-auto rounded-sm px-2.5 py-1 app-no-drag"
        style={{ backgroundColor: `${cursor.input}80` }}
      >
        <Search size={12} style={{ color: cursor.foregroundMuted }} />
        <input
          type="search"
          placeholder="Search coverage, publications, journalists…"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="flex-1 bg-transparent text-[12px] outline-none"
          style={{ color: cursor.foreground }}
        />
      </div>
      <span
        className="text-[11px] truncate max-w-[160px] app-no-drag"
        style={{ color: cursor.foregroundMuted }}
      >
        {displayName ?? userEmail ?? ''}
      </span>
    </header>
  )
}
