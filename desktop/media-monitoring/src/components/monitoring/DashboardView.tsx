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
    <div className="flex-1 overflow-y-auto">
      <div className="px-4 py-3 border-b border-border">
        <h1 className="text-[13px] font-medium text-content">Dashboard</h1>
        <p className="text-[11px] text-content-dim mt-0.5">Media intelligence overview for your workspace.</p>
      </div>

      <div className="cursor-metric-row">
        <MetricCell label="Active monitors" value={String(stats?.monitors ?? 0)} />
        <MetricCell label="Coverage found" value={String(stats?.articles ?? 0)} />
        <MetricCell label="Saved articles" value={String(stats?.saved ?? 0)} />
        <MetricCell label="Total PR value" value={formatCurrency(stats?.totalPrValue ?? 0)} />
      </div>

      {activeMonitor && (
        <section className="px-4 py-4 border-b border-border">
          <p className="cursor-section-header mb-2">Active monitor</p>
          <p className="text-[13px] text-content">{activeMonitor.name}</p>
          <p className="text-[11px] text-content-dim mt-1 font-mono">{activeMonitor.keywords}</p>
          <button type="button" className="btn-primary mt-3 text-[11px]" onClick={() => startLive()}>
            Start live monitoring
          </button>
        </section>
      )}
    </div>
  )
}

function MetricCell({ label, value }: { label: string; value: string }) {
  return (
    <div className="cursor-metric-cell">
      <p className="cursor-section-header">{label}</p>
      <p className="text-lg font-medium text-content mt-1 tabular-nums">{value}</p>
    </div>
  )
}
