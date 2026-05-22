import { useEffect, useState } from 'react'
import { formatCurrency } from '@/lib/format'
import { useActiveMonitor } from '@/hooks/useMonitoring'

interface Stats {
  monitors: number
  articles: number
  saved: number
  totalPrValue: number
}

export function DashboardView() {
  const [stats, setStats] = useState<Stats | null>(null)
  const { activeMonitor, startLive } = useActiveMonitor()

  useEffect(() => {
    window.publshr.getStats().then(setStats)
  }, [])

  return (
    <div className="flex-1 overflow-y-auto p-6">
      <h1 className="text-lg font-medium text-content mb-1">Dashboard</h1>
      <p className="text-sm text-content-dim mb-6">Media intelligence overview for your workspace.</p>

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3 mb-8">
        <StatCard label="Active monitors" value={String(stats?.monitors ?? 0)} />
        <StatCard label="Coverage found" value={String(stats?.articles ?? 0)} />
        <StatCard label="Saved articles" value={String(stats?.saved ?? 0)} />
        <StatCard
          label="Total PR value"
          value={formatCurrency(stats?.totalPrValue ?? 0)}
        />
      </div>

      {activeMonitor && (
        <div className="rounded-lg border border-border p-4 bg-surface-highlight/30">
          <h2 className="text-sm font-medium text-content">Active monitor</h2>
          <p className="text-content-muted text-sm mt-1">{activeMonitor.name}</p>
          <p className="text-2xs text-content-dim mt-1">{activeMonitor.keywords}</p>
          <button type="button" className="btn-primary mt-3" onClick={() => startLive()}>
            Start live monitoring
          </button>
        </div>
      )}
    </div>
  )
}

function StatCard({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-lg border border-border p-4 bg-surface-workspace">
      <p className="text-2xs uppercase tracking-wide text-content-header">{label}</p>
      <p className="text-xl font-medium text-content mt-1">{value}</p>
    </div>
  )
}
