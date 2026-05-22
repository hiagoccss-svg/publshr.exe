import { useEffect, useState } from 'react'
import type { MonitorResult } from '@/types'
import { ArticleCard } from './ArticleCard'
import { useMonitoringStore } from '@/store/monitoringStore'

export function CoverageView() {
  const [items, setItems] = useState<MonitorResult[]>([])
  const { setSelectedArticle, setSection } = useMonitoringStore()

  useEffect(() => {
    window.publshr.getSavedCoverage().then((rows) => setItems(rows as MonitorResult[]))
  }, [])

  const handleSelect = (id: string) => {
    setSelectedArticle(id)
    setSection('monitoring')
  }

  if (items.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center h-full text-center px-8">
        <p className="text-content text-[13px] font-medium">No saved coverage yet</p>
        <p className="text-content-dim text-[11px] mt-2 max-w-sm">
          Save articles from the monitoring feed to build reports and client exports.
        </p>
      </div>
    )
  }

  return (
    <div className="flex-1 overflow-hidden flex flex-col">
      <div className="px-4 py-2 border-b border-border shrink-0">
        <p className="text-[11px] text-content-muted">{items.length} saved articles</p>
      </div>
      <div className="shell-list flex-1 overflow-y-auto">
        {items.map((article, i) => (
          <div key={article.id} onClick={() => handleSelect(article.id)}>
            <ArticleCard article={article} index={i} />
          </div>
        ))}
      </div>
    </div>
  )
}
