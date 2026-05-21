import { useEffect, useState } from 'react'
import type { Publication } from '@/types'
import { formatCompactNumber, publicationInitials } from '@/lib/format'

export function PublicationsView() {
  const [publications, setPublications] = useState<Publication[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    window.publshr.getPublications().then((rows) => {
      setPublications(rows as Publication[])
      setLoading(false)
    })
  }, [])

  if (loading) {
    return <div className="p-8 text-content-dim text-sm">Loading publication database…</div>
  }

  return (
    <div className="flex-1 overflow-y-auto p-4">
      <header className="mb-4">
        <h1 className="text-base font-medium text-content">Approved publications</h1>
        <p className="text-xs text-content-dim mt-1">
          {publications.length} verified sources — monitoring searches only these outlets.
        </p>
      </header>
      <div className="grid gap-2">
        {publications.map((pub) => (
          <div
            key={pub.id}
            className="flex items-center gap-3 p-3 rounded-lg border border-border/80 bg-surface-editor hover:bg-surface-highlight/40 transition-colors"
          >
            <div className="w-9 h-9 rounded bg-surface-tabInactive flex items-center justify-center text-xs font-semibold text-content-muted">
              {publicationInitials(pub.name)}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm text-content font-medium">{pub.name}</p>
              <p className="text-2xs text-content-dim truncate">{pub.website} · {pub.category} · {pub.region}</p>
            </div>
            <div className="text-right text-2xs text-content-muted shrink-0">
              <p>Authority {pub.authority_score}</p>
              <p>{formatCompactNumber(pub.estimated_traffic)}/mo</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
