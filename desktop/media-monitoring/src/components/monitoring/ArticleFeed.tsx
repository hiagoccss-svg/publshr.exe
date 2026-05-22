import { ArticleCard } from './ArticleCard'
import { useMonitoringStore } from '@/store/monitoringStore'
import { Radio, Plus } from 'lucide-react'

export function ArticleFeed() {
  const { results, isMonitoring, setShowCreatePanel, activeMonitorId, monitors } =
    useMonitoringStore()

  if (!activeMonitorId && monitors.length === 0) {
    return <EmptyState onCreate={() => setShowCreatePanel(true)} />
  }

  if (!activeMonitorId) {
    return (
      <div className="flex flex-col items-center justify-center h-full text-content-dim text-[12px]">
        Select a monitoring profile to view coverage.
      </div>
    )
  }

  if (results.length === 0 && !isMonitoring) {
    return (
      <div className="flex flex-col items-center justify-center h-full gap-3 px-8 text-center">
        <Radio size={28} className="text-content-dim" strokeWidth={1.25} />
        <div>
          <p className="text-content text-[13px] font-medium">No coverage found yet.</p>
          <p className="text-content-dim text-[11px] mt-1 max-w-sm">
            Start live monitoring to discover press coverage from approved publications.
          </p>
        </div>
        <button type="button" className="btn-primary text-[11px]">
          Use Start Live in the toolbar
        </button>
      </div>
    )
  }

  return (
    <div className="flex flex-col h-full overflow-hidden">
      {isMonitoring && (
        <div className="flex items-center gap-2 px-3 py-2 text-[11px] text-accent border-b border-border shrink-0">
          <span className="w-1.5 h-1.5 rounded-full bg-accent animate-pulse-soft" />
          Discovering coverage from approved sources…
        </div>
      )}
      <div className="shell-list flex-1 overflow-y-auto">
        {results.map((article, i) => (
          <ArticleCard key={article.id} article={article} index={i} />
        ))}
      </div>
    </div>
  )
}

function EmptyState({ onCreate }: { onCreate: () => void }) {
  return (
    <div className="flex flex-col items-center justify-center h-full gap-5 px-8 text-center max-w-md mx-auto">
      <Radio size={32} className="text-accent" strokeWidth={1.25} />
      <div>
        <h2 className="text-content text-[14px] font-medium">Track media coverage professionally</h2>
        <p className="text-content-dim text-[12px] mt-2 leading-relaxed">
          Create a monitoring profile to start tracking brands, campaigns, competitors, and keywords
          across approved publications.
        </p>
      </div>
      <div className="flex flex-wrap gap-2 justify-center">
        <button type="button" className="btn-primary" onClick={onCreate}>
          <Plus size={14} className="inline mr-1" />
          Create monitor
        </button>
        <button type="button" className="btn-ghost">Track brand</button>
      </div>
    </div>
  )
}
