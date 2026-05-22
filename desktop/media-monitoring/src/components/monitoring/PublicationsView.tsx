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
    return <div className="p-4 text-content-dim text-[12px]">Loading publication database…</div>
  }

  return (
    <div className="flex-1 overflow-hidden flex flex-col">
      <header className="px-4 py-3 border-b border-border shrink-0">
        <h1 className="text-[13px] font-medium text-content">Approved publications</h1>
        <p className="text-[11px] text-content-dim mt-0.5">
          {publications.length} verified sources — monitoring searches only these outlets.
        </p>
      </header>
      <div className="cursor-list flex-1 overflow-y-auto">
        {publications.map((pub) => (
          <div key={pub.id} className="cursor-list-row hover:bg-surface-highlight/40">
            <div className="w-8 h-8 rounded-sm bg-surface-tabInactive flex items-center justify-center text-[10px] font-semibold text-content-muted shrink-0">
              {publicationInitials(pub.name)}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-[13px] text-content">{pub.name}</p>
              <p className="text-[10px] text-content-dim truncate">
                {pub.website} · {pub.category} · {pub.region}
              </p>
            </div>
            <div className="text-right text-[10px] text-content-muted shrink-0 tabular-nums">
              <p>Authority {pub.authority_score}</p>
              <p>{formatCompactNumber(pub.estimated_traffic)}/mo</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
