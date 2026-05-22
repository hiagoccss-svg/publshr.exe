import { Fragment } from 'react'

export function highlightKeywords(text: string, keywords: string[]): React.ReactNode {
  if (!keywords.length) return text

  const pattern = new RegExp(
    `(${keywords.map((k) => k.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')).join('|')})`,
    'gi'
  )
  const parts = text.split(pattern)

  return parts.map((part, i) =>
    pattern.test(part) ? (
      <mark key={i} className="keyword-highlight">
        {part}
      </mark>
    ) : (
      <Fragment key={i}>{part}</Fragment>
    )
  )
}

export function parseKeywordMatches(raw?: string): string[] {
  if (!raw) return []
  try {
    const parsed = JSON.parse(raw)
    return Array.isArray(parsed) ? parsed : []
  } catch {
    return []
  }
}
