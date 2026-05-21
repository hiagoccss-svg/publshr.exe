import { useState } from 'react'
import { X } from 'lucide-react'
import { usePlannerStore } from '@/stores/plannerStore'
import { useWorkspaceStore } from '@/stores/workspaceStore'
import { useAuthStore } from '@/stores/authStore'
import { PLANNER_ITEM_TYPE_LABELS, type PlannerItemType } from '@/types/planner'
import { v4 as uuidv4 } from 'uuid'
import { getSupabase } from '@/lib/supabase'

const TYPES = Object.keys(PLANNER_ITEM_TYPE_LABELS) as PlannerItemType[]

export default function CreateItemPanel() {
  const setCreatePanelOpen = usePlannerStore((s) => s.setCreatePanelOpen)
  const createItem = usePlannerStore((s) => s.createItem)
  const workspace = useWorkspaceStore((s) => s.currentWorkspace)
  const user = useAuthStore((s) => s.user)
  const [title, setTitle] = useState('')
  const [type, setType] = useState<PlannerItemType>('press_release')
  const [dueDate, setDueDate] = useState('')
  const [description, setDescription] = useState('')
  const [createDraft, setCreateDraft] = useState(false)
  const [saving, setSaving] = useState(false)

  const close = () => setCreatePanelOpen(false)

  const submit = async () => {
    if (!title.trim() || !workspace || !user) return
    setSaving(true)
    try {
      let editorDocumentId: string | null = null
      if (createDraft) {
        editorDocumentId = uuidv4()
        const supabase = getSupabase()
        await supabase.from('editor_documents').insert({
          id: editorDocumentId,
          workspace_id: workspace.id,
          title: title.trim(),
          subtitle: null,
          content_json: { type: 'doc', content: [{ type: 'paragraph' }] },
          content_html: '<p></p>',
          status: 'draft',
          created_by: user.id,
          updated_by: user.id
        })
        if (window.planner) {
          await window.planner.upsertEditorDraftCache({
            id: editorDocumentId,
            planner_item_id: null,
            title: title.trim(),
            content_html: '<p></p>',
            _syncStatus: 'pending'
          })
        }
      }

      const item = await createItem(
        {
          title: title.trim(),
          type,
          description: description || null,
          due_date: dueDate || null,
          editor_document_id: editorDocumentId
        },
        workspace.id,
        user.id
      )

      if (createDraft && editorDocumentId) {
        const supabase = getSupabase()
        await supabase
          .from('editor_documents')
          .update({ planner_item_id: item.id })
          .eq('id', editorDocumentId)
        await usePlannerStore.getState().updateItem(item.id, { editor_document_id: editorDocumentId })
      }

      close()
    } finally {
      setSaving(false)
    }
  }

  return (
    <>
      <div className="fixed inset-0 z-40 bg-ink/10 backdrop-blur-[2px]" onClick={close} />
      <aside className="fixed right-0 top-12 z-50 flex h-[calc(100%-3rem)] w-[400px] flex-col border-l border-surface-border bg-surface-raised shadow-panel">
        <div className="flex items-center justify-between border-b border-surface-border px-4 py-3">
          <h2 className="text-sm font-semibold text-ink">New planner item</h2>
          <button type="button" onClick={close} className="rounded-lg p-1 text-ink-muted hover:bg-surface-muted">
            <X className="h-4 w-4" />
          </button>
        </div>
        <div className="flex-1 space-y-4 overflow-y-auto p-4">
          <Field label="Title">
            <input
              autoFocus
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className="field-input"
              placeholder="Q3 product launch press release"
            />
          </Field>
          <Field label="Type">
            <select value={type} onChange={(e) => setType(e.target.value as PlannerItemType)} className="field-input">
              {TYPES.map((t) => (
                <option key={t} value={t}>
                  {PLANNER_ITEM_TYPE_LABELS[t]}
                </option>
              ))}
            </select>
          </Field>
          <Field label="Deadline">
            <input type="date" value={dueDate} onChange={(e) => setDueDate(e.target.value)} className="field-input" />
          </Field>
          <Field label="Description">
            <textarea
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              rows={4}
              className="field-input resize-none"
              placeholder="Brief, goals, audience…"
            />
          </Field>
          <label className="flex items-center gap-2 text-sm text-ink-secondary">
            <input
              type="checkbox"
              checked={createDraft}
              onChange={(e) => setCreateDraft(e.target.checked)}
              className="rounded border-surface-border"
            />
            Create linked editor draft
          </label>
        </div>
        <div className="border-t border-surface-border p-4">
          <button
            type="button"
            disabled={!title.trim() || saving}
            onClick={() => void submit()}
            className="w-full rounded-lg bg-ink py-2 text-sm font-medium text-white disabled:opacity-50"
          >
            {saving ? 'Creating…' : 'Create item'}
          </button>
        </div>
      </aside>
    </>
  )
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div>
      <label className="text-xs font-medium text-ink-secondary">{label}</label>
      <div className="mt-1">{children}</div>
    </div>
  )
}
