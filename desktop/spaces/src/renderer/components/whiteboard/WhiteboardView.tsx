import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { Tldraw, type Editor, getSnapshot, loadSnapshot } from 'tldraw'
import 'tldraw/tldraw.css'
import { LayoutGrid, Plus } from 'lucide-react'
import { useSpacesStore } from '../../stores/spaces-store'
import {
  createWhiteboard,
  listWhiteboards,
  saveWhiteboardSnapshot,
  whiteboardApiEnabled
} from '../../lib/whiteboard-api'
import type { Whiteboard } from '../../../shared/types'

export function WhiteboardView(): React.ReactElement {
  const workspace = useSpacesStore((s) => s.workspace)
  const activeSpaceId = useSpacesStore((s) => s.activeSpaceId)
  const currentUserId = useSpacesStore((s) => s.currentUserId)
  const [boards, setBoards] = useState<Whiteboard[]>([])
  const [activeId, setActiveId] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const saveTimer = useRef<ReturnType<typeof setTimeout> | null>(null)
  const editorRef = useRef<Editor | null>(null)

  const activeBoard = useMemo(
    () => boards.find((b) => b.id === activeId) ?? null,
    [boards, activeId]
  )

  const reload = useCallback(async () => {
    if (!activeSpaceId) return
    setLoading(true)
    setError(null)
    try {
      const list = await listWhiteboards(activeSpaceId)
      setBoards(list)
      if (list.length > 0 && !activeId) {
        setActiveId(list[0].id)
      }
      if (list.length === 0) {
        setActiveId(null)
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Could not load whiteboards')
    } finally {
      setLoading(false)
    }
  }, [activeSpaceId, activeId])

  useEffect(() => {
    void reload()
  }, [reload])

  const scheduleSave = useCallback(
    (editor: Editor) => {
      if (!activeId || !currentUserId) return
      if (saveTimer.current) clearTimeout(saveTimer.current)
      saveTimer.current = setTimeout(() => {
        const snapshot = getSnapshot(editor.store)
        void saveWhiteboardSnapshot(activeId, snapshot as unknown as Record<string, unknown>, currentUserId).catch(
          (e) => setError(e instanceof Error ? e.message : 'Save failed')
        )
      }, 1200)
    },
    [activeId, currentUserId]
  )

  const onMount = useCallback((editor: Editor) => {
    editorRef.current = editor
  }, [])

  useEffect(() => {
    const editor = editorRef.current
    if (!editor || !activeBoard) return
    try {
      if (activeBoard.snapshot && Object.keys(activeBoard.snapshot).length > 0) {
        loadSnapshot(editor.store, activeBoard.snapshot as never)
      } else {
        editor.store.clear()
      }
    } catch {
      editor.store.clear()
    }
    const unsub = editor.store.listen(() => scheduleSave(editor), { source: 'user', scope: 'document' })
    return () => {
      unsub()
      if (saveTimer.current) clearTimeout(saveTimer.current)
    }
  }, [activeBoard?.id, activeBoard, scheduleSave])

  if (!whiteboardApiEnabled()) {
    return (
      <div className="flex h-full min-h-[360px] flex-col items-center justify-center gap-2 p-8 text-center">
        <LayoutGrid className="h-10 w-10 text-ink-muted" />
        <p className="text-sm font-medium text-ink">Connect Supabase to use whiteboards</p>
        <p className="max-w-md text-xs text-ink-muted">
          Copy <code className="rounded bg-surface-muted px-1">desktop/spaces/.env.example</code> to{' '}
          <code className="rounded bg-surface-muted px-1">.env</code> and apply migration{' '}
          <code className="rounded bg-surface-muted px-1">20260522140000_whiteboards_enterprise.sql</code>.
        </p>
      </div>
    )
  }

  if (!activeSpaceId || !workspace) {
    return (
      <p className="p-8 text-sm text-ink-muted">Select a space to open whiteboards.</p>
    )
  }

  return (
    <div className="flex h-full min-h-0 flex-1 overflow-hidden">
      <aside className="dt-divider-r flex w-52 shrink-0 flex-col gap-1 p-2">
        <button
          type="button"
          className="flex items-center gap-2 rounded-lg bg-accent px-2 py-1.5 text-xs font-medium text-white hover:bg-accent-hover"
          onClick={() => {
            void (async () => {
              try {
                const board = await createWhiteboard({
                  workspaceId: workspace.id,
                  spaceId: activeSpaceId,
                  name: `Whiteboard ${boards.length + 1}`,
                  createdBy: currentUserId || workspace.id
                })
                setBoards((prev) => [board, ...prev])
                setActiveId(board.id)
              } catch (e) {
                setError(e instanceof Error ? e.message : 'Create failed')
              }
            })()
          }}
        >
          <Plus className="h-3.5 w-3.5" />
          New board
        </button>
        {loading && <p className="px-2 text-xs text-ink-muted">Loading…</p>}
        {error && <p className="px-2 text-xs text-red-600">{error}</p>}
        {boards.map((b) => (
          <button
            key={b.id}
            type="button"
            onClick={() => setActiveId(b.id)}
            className={
              b.id === activeId
                ? 'rounded-lg bg-accent-soft px-2 py-1.5 text-left text-xs font-medium text-accent'
                : 'rounded-lg px-2 py-1.5 text-left text-xs text-ink-secondary hover:bg-surface-muted'
            }
          >
            {b.name}
          </button>
        ))}
      </aside>
      <div className="relative min-h-0 min-w-0 flex-1 bg-white">
        {activeBoard ? (
          <Tldraw key={activeBoard.id} onMount={onMount} />
        ) : (
          <div className="flex h-full items-center justify-center text-sm text-ink-muted">
            Create a whiteboard to start drawing.
          </div>
        )}
      </div>
    </div>
  )
}
