import { ArticleCard } from './ArticleCard'
import { useMonitoringStore } from '@/store/monitoringStore'
import { Radio, Plus } from 'lucide-react'

export function ArticleFeed() {
  const { results, isMonitoring, searchQuery, setShowCreatePanel, activeMonitorId, monitors } =
    useMonitoringStore()

  const filtered = results.filter((r) => {
    if (!searchQuery.trim()) return true
    const q = searchQuery.toLowerCase()
    return (
      r.title.toLowerCase().includes(q) ||
      (r.publication_name?.toLowerCase().includes(q) ?? false) ||
      (r.author?.toLowerCase().includes(q) ?? false)
    )
  })

  if (!activeMonitorId && monitors.length === 0) {
    return <EmptyState onCreate={() => setShowCreatePanel(true)} />
  }

  if (!activeMonitorId) {
    return (
      <div className="flex flex-col items-center justify-center h-full text-content-dim text-sm">
        Select a monitoring profile to view coverage.
      </div>
    )
  }

  if (filtered.length === 0 && !isMonitoring) {
    return (
      <div className="flex flex-col items-center justify-center h-full gap-4 px-8 text-center">
        <Radio size={32} className="text-content-dim" />
        <div>
          <p className="text-content text-sm font-medium">No coverage found yet.</p>
          <p className="text-content-dim text-xs mt-1 max-w-sm">
            Start live monitoring to discover press coverage from approved publications.
          </p>
        </div>
        <button type="button" className="btn-primary" onClick={() => useMonitoringStore.getState().setShowCreatePanel(false)}>
          Use Start Live in the toolbar
        </button>
      </div>
    )
  }

  return (
    <div className="flex flex-col gap-2 p-4 overflow-y-auto h-full">
      {isMonitoring && (
        <div className="flex items-center gap-2 text-xs text-accent mb-1 animate-fade-in">
          <span className="w-1.5 h-1.5 rounded-full bg-accent animate-pulse-soft" />
          Discovering coverage from approved sources…
        </div>
      )}
      {filtered.map((article, i) => (
        <ArticleCard key={article.id} article={article} index={i} />
      ))}
    </div>
  )
}

function EmptyState({ onCreate }: { onCreate: () => void }) {
  return (
    <div className="flex flex-col items-center justify-center h-full gap-6 px-8 text-center max-w-md mx-auto">
      <div className="w-14 h-14 rounded-2xl bg-surface-highlight flex items-center justify-center">
        <Radio size={28} className="text-accent" />
      </div>
      <div>
        <h2 className="text-content text-base font-medium">Track media coverage professionally</h2>
        <p className="text-content-dim text-sm mt-2 leading-relaxed">
          Create a monitoring profile to start tracking brands, campaigns, competitors, and keywords
          across approved publications.
        </p>
      </div>
      <div className="flex flex-wrap gap-2 justify-center">
        <button type="button" className="btn-primary" onClick={onCreate}>
          <Plus size={14} className="inline mr-1" />
          Create monitor
        </button>
        <button type="button" className="btn-ghost border border-border">Track brand</button>
      </div>
    </div>
  )
}
