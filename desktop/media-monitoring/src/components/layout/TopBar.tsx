import {
  Search,
  Plus,
  RefreshCw,
  Radio,
  Bell,
  Sparkles,
  Wifi,
  WifiOff,
  LogOut
} from 'lucide-react'
import clsx from 'clsx'
import { useMonitoringStore } from '@/store/monitoringStore'
import { useActiveMonitor } from '@/hooks/useMonitoring'

interface Props {
  onSignIn?: () => void
}

export function TopBar({ onSignIn }: Props) {
  const {
    searchQuery,
    setSearchQuery,
    isMonitoring,
    streamCount,
    syncStatus,
    setShowCreatePanel,
    workspaceName,
    userEmail,
    setSyncStatus
  } = useMonitoringStore()
  const { activeMonitor, startLive, stopLive } = useActiveMonitor()

  const handleSync = async () => {
    setSyncStatus('syncing')
    try {
      await window.publshr.pullSync()
      setSyncStatus('synced')
    } catch {
      setSyncStatus('error')
    }
  }

  const handleSignOut = async () => {
    await window.publshr.signOut()
    window.location.reload()
  }

  return (
    <header className="h-topbar flex items-center gap-3 px-4 bg-surface-title border-b border-border shrink-0">
      <div className="flex items-center gap-2 min-w-0 shrink-0">
        <div className="w-6 h-6 rounded bg-accent/20 flex items-center justify-center text-accent text-xs font-bold">
          P
        </div>
        <div className="hidden sm:block min-w-0">
          <p className="text-2xs text-content-dim leading-none">{workspaceName ?? 'Workspace'}</p>
          <p className="text-sm text-content truncate leading-tight">
            Media Monitoring
            {activeMonitor && <span className="text-content-muted"> · {activeMonitor.name}</span>}
          </p>
        </div>
      </div>

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
      </div>

      <div className="flex items-center gap-2 shrink-0">
        <div className="hidden md:flex items-center gap-1.5 text-xs text-content-muted px-2">
          <Radio size={12} className={clsx(isMonitoring && 'text-accent animate-pulse-soft')} />
          <span>{isMonitoring ? 'Live' : 'Idle'}</span>
          <span className="text-content-dim">·</span>
          <span className="text-content">{streamCount}</span>
        </div>
        <button
          type="button"
          className={clsx('btn-ghost flex items-center gap-1', isMonitoring && 'text-accent')}
          onClick={() => (isMonitoring ? stopLive() : startLive())}
          title={isMonitoring ? 'Stop monitoring' : 'Start live monitoring'}
        >
          <RefreshCw size={14} className={clsx(isMonitoring && 'animate-spin')} />
        </button>
        <button
          type="button"
          className="btn-ghost p-1.5"
          onClick={() => void handleSync()}
          title="Sync with Supabase"
        >
          {syncStatus === 'offline' || syncStatus === 'error' ? (
            <WifiOff size={14} className="text-sentiment-negative" />
          ) : (
            <Wifi size={14} className={syncStatus === 'syncing' ? 'animate-pulse-soft text-accent' : ''} />
          )}
        </button>
        <button type="button" className="btn-ghost p-1.5" aria-label="Notifications">
          <Bell size={14} />
        </button>
        <button type="button" className="btn-ghost p-1.5 text-accent" aria-label="AI assistant">
          <Sparkles size={14} />
        </button>
        {userEmail ? (
          <>
            <span className="hidden lg:inline text-2xs text-content-dim max-w-[120px] truncate" title={userEmail}>
              {userEmail}
            </span>
            <button type="button" className="btn-ghost p-1.5" onClick={() => void handleSignOut()} title="Sign out">
              <LogOut size={14} />
            </button>
          </>
        ) : (
          <button type="button" className="btn-ghost text-2xs px-2" onClick={onSignIn}>
            Sign in
          </button>
        )}
      </div>
    </header>
  )
}
