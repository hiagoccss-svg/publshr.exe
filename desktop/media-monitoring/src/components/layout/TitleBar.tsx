import { Search } from 'lucide-react'
import { useMonitoringStore } from '@/store/monitoringStore'
import { shell } from '@/theme/shellTheme'

export function TitleBar() {
  const { searchQuery, setSearchQuery, displayName, userEmail } = useMonitoringStore()

  return (
    <header
      className="glass-toolbar-dark flex shrink-0 items-center gap-3 border-b px-3 app-drag"
      style={{ height: shell.titleBarHeight }}
    >
      <div className="w-[70px] shrink-0 app-no-drag" />
      <div
        className="flex-1 flex items-center gap-2 max-w-2xl mx-auto rounded-sm px-2.5 py-1 app-no-drag"
        style={{ backgroundColor: `${shell.input}80` }}
      >
        <Search size={12} style={{ color: shell.foregroundMuted }} />
        <input
          type="search"
          placeholder="Search coverage, publications, journalists…"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          className="flex-1 bg-transparent text-[12px] outline-none"
          style={{ color: shell.foreground }}
        />
      </div>
      <span
        className="text-[11px] truncate max-w-[160px] app-no-drag"
        style={{ color: shell.foregroundMuted }}
      >
        {displayName ?? userEmail ?? ''}
      </span>
    </header>
  )
}
