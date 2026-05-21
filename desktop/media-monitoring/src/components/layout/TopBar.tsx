import {
  Search,
  Plus,
  Calendar,
  SlidersHorizontal,
  RefreshCw,
  Radio,
  Bell,
  Sparkles,
  User,
  Wifi,
  WifiOff
} from 'lucide-react'
import clsx from 'clsx'
import { useMonitoringStore } from '@/store/monitoringStore'
import { useActiveMonitor } from '@/hooks/useMonitoring'

export function TopBar() {
  const {
    topBarMode,
    searchQuery,
    setSearchQuery,
    isMonitoring,
    streamCount,
    syncStatus,
    setShowCreatePanel,
    results
  } = useMonitoringStore()
  const { activeMonitor, startLive, stopLive } = useActiveMonitor()

  return (
    <header className="h-topbar flex items-center gap-3 px-4 bg-surface-title border-b border-border shrink-0">
      {/* Left */}
      <div className="flex items-center gap-2 min-w-0 shrink-0">
        <div className="w-6 h-6 rounded bg-accent/20 flex items-center justify-center text-accent text-xs font-bold">
          P
        </div>
        <div className="hidden sm:block min-w-0">
          <p className="text-2xs text-content-dim leading-none">Acme Communications</p>
          <p className="text-sm text-content truncate leading-tight">
            Media Monitoring
            {activeMonitor && (
              <span className="text-content-muted"> · {activeMonitor.name}</span>
            )}
          </p>
        </div>
      </div>

      {/* Center */}
      <div className="flex-1 flex items-center gap-2 max-w-3xl mx-auto">
        <div className="flex-1 flex items-center gap-2 bg-surface-input/60 rounded px-2.5 py-1 border border-transparent focus-within:border-accent/40">
          <Search size={13} className="text-content-dim shrink-0" />
          <input
            type="search"
            placeholder="Search coverage, publications, journalists…"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="flex-1 bg-transparent text-sm text-content placeholder:text-content-dim outline-none"
          />
        </div>
        <button type="button" className="btn-ghost flex items-center gap-1" onClick={() => setShowCreatePanel(true)}>
          <Plus size={14} />
          <span className="hidden md:inline">Monitor</span>
        </button>
        <button type="button" className="btn-ghost hidden lg:flex items-center gap-1">
          <Calendar size={14} />
          <span>Last 7 days</span>
        </button>
        <button type="button" className="btn-ghost p-1.5" aria-label="Filters">
          <SlidersHorizontal size={14} />
        </button>
      </div>

      {/* Right — mode-specific */}
      <div className="flex items-center gap-2 shrink-0">
        {topBarMode === 'live' && (
          <>
            <div className="hidden md:flex items-center gap-1.5 text-xs text-content-muted px-2">
              <Radio size={12} className={clsx(isMonitoring && 'text-accent animate-pulse-soft')} />
              <span>{isMonitoring ? 'Live' : 'Idle'}</span>
              <span className="text-content-dim">·</span>
              <span className="text-content">{streamCount} articles</span>
            </div>
            <button
              type="button"
              className={clsx('btn-ghost flex items-center gap-1', isMonitoring && 'text-accent')}
              onClick={() => (isMonitoring ? stopLive() : startLive())}
            >
              <RefreshCw size={14} className={clsx(isMonitoring && 'animate-spin')} />
            </button>
          </>
        )}

        <div className="flex items-center gap-1 text-2xs text-content-muted" title="Sync status">
          {syncStatus === 'offline' ? <WifiOff size={12} /> : <Wifi size={12} />}
          <span className="hidden lg:inline capitalize">{syncStatus}</span>
        </div>

        <button type="button" className="btn-ghost relative p-1.5" aria-label="Notifications">
          <Bell size={14} />
          {results.length > 0 && (
            <span className="absolute top-0 right-0 w-1.5 h-1.5 bg-accent rounded-full" />
          )}
        </button>
        <button type="button" className="btn-ghost p-1.5 text-accent" aria-label="AI assistant">
          <Sparkles size={14} />
        </button>
        <button type="button" className="btn-ghost p-1.5" aria-label="Profile">
          <User size={14} />
        </button>
      </div>
    </header>
  )
}
