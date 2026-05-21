import { Cloud, CloudOff } from 'lucide-react'
import { useMonitoringStore } from '@/store/monitoringStore'

interface Props {
  onSignIn: () => void
}

export function SyncBanner({ onSignIn }: Props) {
  const { syncStatus, userEmail, workspaceName } = useMonitoringStore()

  if (syncStatus === 'synced' && userEmail) {
    return (
      <div className="flex items-center gap-2 px-4 py-1.5 bg-accent/10 border-b border-accent/20 text-2xs text-content-muted shrink-0">
        <Cloud size={12} className="text-accent" />
        <span>
          Cloud sync active · {workspaceName ?? 'Workspace'} · {userEmail}
        </span>
      </div>
    )
  }

  return (
    <div className="flex items-center justify-between gap-2 px-4 py-1.5 bg-surface-tabInactive border-b border-border text-2xs shrink-0">
      <span className="flex items-center gap-2 text-content-muted">
        <CloudOff size={12} />
        Running locally — monitors and coverage saved on this device. Sign in to sync with your team.
      </span>
      <button type="button" className="btn-primary text-2xs py-0.5 px-2" onClick={onSignIn}>
        Connect cloud
      </button>
    </div>
  )
}
