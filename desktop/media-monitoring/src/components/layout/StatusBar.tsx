import { CheckCircle2, Radio } from 'lucide-react'
import { useMonitoringStore } from '@/store/monitoringStore'
import { cursor } from '@/theme/cursor'

export function StatusBar() {
  const { syncStatus, isMonitoring, streamCount, workspaceName } = useMonitoringStore()

  const syncLabel =
    syncStatus === 'synced'
      ? 'Supabase connected'
      : syncStatus === 'syncing'
        ? 'Syncing…'
        : syncStatus === 'error'
          ? 'Sync error'
          : 'Offline'

  return (
    <footer
      className="flex items-center gap-4 px-3 shrink-0 text-[11px]"
      style={{
        height: cursor.statusBarHeight,
        backgroundColor: cursor.statusBar,
        color: cursor.statusBarFg
      }}
    >
      <span className="flex items-center gap-1.5 opacity-95">
        <CheckCircle2 size={10} />
        {syncLabel}
      </span>
      {workspaceName && <span className="opacity-90 truncate max-w-[140px]">{workspaceName}</span>}
      <span className="flex items-center gap-1 opacity-90">
        <Radio size={10} className={isMonitoring ? 'animate-pulse-soft' : ''} />
        {isMonitoring ? 'Live' : 'Idle'} · {streamCount} articles
      </span>
      <span className="flex-1" />
      <span className="opacity-80">Media Monitoring</span>
      <span className="opacity-80">UTF-8</span>
    </footer>
  )
}
