import { useEffect, useState, useCallback } from 'react'
import { Sparkles, Send, PanelLeft } from 'lucide-react'
import { getSupabase } from '@/lib/supabase'
import type { EditorDocument } from '@/types/planner'

export default function EditorWindow() {
  const documentId = window.planner?.editorDocumentId
  const plannerItemId = window.planner?.plannerItemId
  const [doc, setDoc] = useState<EditorDocument | null>(null)
  const [title, setTitle] = useState('')
  const [body, setBody] = useState('')
  const [saveState, setSaveState] = useState<'saved' | 'saving' | 'idle'>('idle')
  const [sourceOpen, setSourceOpen] = useState(true)

  useEffect(() => {
    if (!documentId) return
    const load = async () => {
      if (window.planner) {
        const cached = (await window.planner.getEditorDraftCache(documentId)) as EditorDocument | null
        if (cached) {
          setDoc(cached)
          setTitle(cached.title)
          setBody(cached.content_html ?? '')
        }
      }
      try {
        const supabase = getSupabase()
        const { data } = await supabase.from('editor_documents').select('*').eq('id', documentId).single()
        if (data) {
          const d = data as EditorDocument
          setDoc(d)
          setTitle(d.title)
          setBody(d.content_html ?? '')
        }
      } catch {
        /* offline */
      }
    }
    void load()
  }, [documentId])

  const save = useCallback(async () => {
    if (!documentId) return
    setSaveState('saving')
    const patch = {
      id: documentId,
      planner_item_id: plannerItemId,
      title,
      content_html: body,
      updated_at: new Date().toISOString(),
      _syncStatus: 'pending'
    }
    await window.planner?.upsertEditorDraftCache(patch)
    try {
      const supabase = getSupabase()
      await supabase
        .from('editor_documents')
        .update({ title, content_html: body, updated_at: new Date().toISOString() })
        .eq('id', documentId)
    } catch {
      /* queued */
    }
    setSaveState('saved')
    setTimeout(() => setSaveState('idle'), 2000)
  }, [documentId, plannerItemId, title, body])

  useEffect(() => {
    const t = setTimeout(() => {
      if (title || body) void save()
    }, 1500)
    return () => clearTimeout(t)
  }, [title, body, save])

  return (
    <div className="flex h-screen flex-col bg-[#faf9f7]">
      <header className="drag-region flex h-12 items-center gap-4 border-b border-surface-border px-4">
        {window.planner?.platform === 'darwin' && <div className="w-14" />}
        <div className="no-drag min-w-0 flex-1">
          <input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            className="w-full bg-transparent text-sm font-semibold text-ink outline-none"
            placeholder="Document title"
          />
          {plannerItemId && (
            <p className="text-[10px] text-ink-muted">Linked planner item · {plannerItemId.slice(0, 8)}</p>
          )}
        </div>
        <span className="no-drag text-[10px] text-ink-muted">
          {saveState === 'saving' ? 'Saving…' : saveState === 'saved' ? 'Saved' : 'Autosave'}
        </span>
        <span className="no-drag rounded-full bg-surface-muted px-2 py-0.5 text-[10px] capitalize text-ink-secondary">
          {doc?.status ?? 'draft'}
        </span>
        <button type="button" className="no-drag rounded-lg bg-ink px-3 py-1 text-xs font-medium text-white">
          Publish
        </button>
        <button type="button" className="no-drag rounded-lg p-1.5 text-ink-muted hover:bg-accent-soft hover:text-accent">
          <Sparkles className="h-4 w-4" />
        </button>
      </header>

      <div className="flex min-h-0 flex-1">
        {sourceOpen && (
          <aside className="w-56 shrink-0 border-r border-surface-border bg-surface-raised/50 p-3">
            <button
              type="button"
              onClick={() => setSourceOpen(false)}
              className="mb-3 flex items-center gap-1 text-[10px] text-ink-muted"
            >
              <PanelLeft className="h-3 w-3" /> Hide sources
            </button>
            <SourceSection title="Brief" placeholder="Paste client brief…" />
            <SourceSection title="PR email" placeholder="Original pitch email…" />
            <SourceSection title="Attachments" placeholder="Drag files here (Phase 3)" />
          </aside>
        )}

        <main className="flex min-w-0 flex-1 flex-col items-center overflow-y-auto px-8 py-10">
          {!sourceOpen && (
            <button
              type="button"
              onClick={() => setSourceOpen(true)}
              className="mb-4 self-start text-xs text-ink-muted hover:text-ink"
            >
              Show source material
            </button>
          )}
          <div className="w-full max-w-2xl">
            <input
              placeholder="Subtitle (optional)"
              className="mb-6 w-full bg-transparent text-lg text-ink-secondary outline-none"
            />
            <div
              contentEditable
              suppressContentEditableWarning
              onInput={(e) => setBody(e.currentTarget.innerHTML)}
              dangerouslySetInnerHTML={{ __html: body }}
              className="min-h-[60vh] text-base leading-relaxed text-ink outline-none [&_h2]:mb-4 [&_h2]:mt-8 [&_h2]:text-xl [&_h2]:font-semibold [&_p]:mb-4"
            />
            <p className="mt-8 text-[10px] text-ink-muted">
              Type / for commands · Select text for AI rewrite (Phase 5)
            </p>
          </div>
        </main>

        <aside className="w-64 shrink-0 border-l border-surface-border bg-surface-raised/50 p-3">
          <h3 className="text-[10px] font-semibold uppercase tracking-wider text-ink-muted">Comments</h3>
          <div className="mt-3 flex gap-2">
            <input
              placeholder="Add comment…"
              className="flex-1 rounded-lg border border-surface-border px-2 py-1 text-xs"
            />
            <button type="button" className="text-accent">
              <Send className="h-3.5 w-3.5" />
            </button>
          </div>
          <h3 className="mt-6 text-[10px] font-semibold uppercase tracking-wider text-ink-muted">Publishing</h3>
          <p className="mt-2 text-xs text-ink-muted">Schedule and channels — Phase 5.</p>
        </aside>
      </div>
    </div>
  )
}

function SourceSection({ title, placeholder }: { title: string; placeholder: string }) {
  return (
    <div className="mb-4">
      <p className="mb-1 text-[10px] font-medium text-ink-secondary">{title}</p>
      <textarea
        rows={2}
        placeholder={placeholder}
        className="w-full resize-none rounded-lg border border-surface-border bg-surface px-2 py-1.5 text-[11px] outline-none"
      />
    </div>
  )
}
