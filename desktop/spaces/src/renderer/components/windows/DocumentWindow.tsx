import { useCallback, useEffect, useState } from 'react'
import { getSpacesAPI } from '../../lib/api'

export function DocumentWindow({ documentId }: { documentId: string }): React.ReactElement {
  const [title, setTitle] = useState('')
  const [content, setContent] = useState('')
  const [loading, setLoading] = useState(true)
  const [saveState, setSaveState] = useState<'idle' | 'saving' | 'saved'>('idle')

  useEffect(() => {
    let cancelled = false
    void getSpacesAPI()
      .getDocument(documentId)
      .then((doc) => {
        if (cancelled || !doc) return
        setTitle(doc.title)
        setContent(doc.content)
      })
      .finally(() => {
        if (!cancelled) setLoading(false)
      })
    return () => {
      cancelled = true
    }
  }, [documentId])

  const save = useCallback(async () => {
    setSaveState('saving')
    await getSpacesAPI().updateDocument(documentId, { title, content })
    setSaveState('saved')
    setTimeout(() => setSaveState('idle'), 2000)
  }, [documentId, title, content])

  useEffect(() => {
    if (loading) return
    const t = setTimeout(() => {
      void save()
    }, 1200)
    return () => clearTimeout(t)
  }, [title, content, loading, save])

  if (loading) {
    return (
      <div className="flex h-full items-center justify-center bg-white">
        <p className="text-sm text-ink-muted">Loading document…</p>
      </div>
    )
  }

  return (
    <div className="flex h-full flex-col bg-white">
      <header className="drag-region border-b border-surface-border px-6 py-4">
        <p className="no-drag text-xs text-ink-muted">
          Document · {documentId.slice(0, 8)}
          {saveState === 'saving' && ' · Saving…'}
          {saveState === 'saved' && ' · Saved'}
        </p>
        <input
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          className="no-drag mt-1 w-full bg-transparent text-lg font-semibold text-ink outline-none"
          placeholder="Document title"
        />
      </header>
      <div className="no-drag flex-1 overflow-auto p-6">
        <textarea
          value={content}
          onChange={(e) => setContent(e.target.value)}
          className="min-h-[400px] w-full resize-none rounded-lg border border-surface-border p-4 text-sm leading-relaxed text-ink focus:outline-none focus:ring-2 focus:ring-accent/10"
          placeholder="Start writing…"
        />
      </div>
    </div>
  )
}
