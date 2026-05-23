import { Bell, Pencil } from 'lucide-react'
import { useEffect, useState } from 'react'
import { useMonitoringStore } from '@/store/monitoringStore'
import type { MonitorProfile } from '@/types'
import { shell } from '@/theme/shellTheme'

export interface AlertSettings {
  desktop?: boolean
  min_relevance?: number
  sentiment?: string[]
}

function parseAlerts(raw: MonitorProfile['alert_settings']): AlertSettings {
  if (!raw) return { desktop: true, min_relevance: 0, sentiment: [] }
  try {
    const v = typeof raw === 'string' ? JSON.parse(raw) : raw
    return {
      desktop: v.desktop !== false,
      min_relevance: typeof v.min_relevance === 'number' ? v.min_relevance : 0,
      sentiment: Array.isArray(v.sentiment) ? v.sentiment : []
    }
  } catch {
    return { desktop: true, min_relevance: 0, sentiment: [] }
  }
}

export function AlertsView() {
  const { monitors, setMonitors } = useMonitoringStore()
  const [editingId, setEditingId] = useState<string | null>(null)
  const [draft, setDraft] = useState<AlertSettings>({ desktop: true, min_relevance: 0, sentiment: [] })
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    void window.publshr.getMonitors().then((rows) => setMonitors(rows as MonitorProfile[]))
  }, [setMonitors])

  const startEdit = (m: MonitorProfile) => {
    setEditingId(m.id)
    setDraft(parseAlerts(m.alert_settings))
  }

  const save = async (id: string) => {
    setSaving(true)
    try {
      await window.publshr.updateMonitor(id, {
        alert_settings: {
          desktop: draft.desktop !== false,
          min_relevance: draft.min_relevance ?? 0,
          sentiment: draft.sentiment ?? []
        }
      })
      const rows = (await window.publshr.getMonitors()) as MonitorProfile[]
      setMonitors(rows)
      setEditingId(null)
    } finally {
      setSaving(false)
    }
  }

  if (monitors.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center h-full px-8 text-center text-[12px] text-content-dim">
        <Bell size={28} className="mb-3 opacity-60" />
        <p className="text-content">No monitors yet</p>
        <p className="text-[11px] mt-2 max-w-sm">
          Create a monitoring profile first, then configure desktop alerts and relevance thresholds here.
        </p>
      </div>
    )
  }

  return (
    <div className="flex-1 overflow-y-auto p-4 space-y-3 max-w-2xl">
      <header>
        <h1 className="text-[15px] font-medium text-content">Alert rules</h1>
        <p className="text-[11px] text-content-dim mt-1">
          Control desktop notifications and filters per monitor — aligned with Media Eye–style coverage alerts.
        </p>
      </header>

      {monitors.map((m) => {
        const alerts = parseAlerts(m.alert_settings)
        const isEditing = editingId === m.id
        return (
          <article
            key={m.id}
            className="rounded-lg border p-3"
            style={{ borderColor: shell.border, backgroundColor: shell.sideBar }}
          >
            <div className="flex items-start justify-between gap-2">
              <div>
                <h2 className="text-[13px] font-medium text-content">{m.name}</h2>
                <p className="text-[10px] text-content-dim mt-0.5 font-mono truncate">{m.keywords}</p>
              </div>
              {!isEditing && (
                <button type="button" className="btn-ghost p-1.5" onClick={() => startEdit(m)} aria-label="Edit rules">
                  <Pencil size={14} />
                </button>
              )}
            </div>

            {isEditing ? (
              <div className="mt-3 space-y-2 text-[12px]">
                <label className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    checked={draft.desktop !== false}
                    onChange={(e) => setDraft((d) => ({ ...d, desktop: e.target.checked }))}
                  />
                  Desktop notifications for new coverage
                </label>
                <label className="block">
                  <span className="text-[11px] text-content-muted">Minimum relevance score (0–100)</span>
                  <input
                    type="number"
                    min={0}
                    max={100}
                    className="input-field mt-1 w-24"
                    value={draft.min_relevance ?? 0}
                    onChange={(e) =>
                      setDraft((d) => ({ ...d, min_relevance: Number(e.target.value) || 0 }))
                    }
                  />
                </label>
                <label className="block">
                  <span className="text-[11px] text-content-muted">Alert on sentiment (leave empty = all)</span>
                  <div className="flex flex-wrap gap-1 mt-1">
                    {(['positive', 'neutral', 'negative', 'mixed'] as const).map((s) => (
                      <button
                        key={s}
                        type="button"
                        className={draft.sentiment?.includes(s) ? 'shell-chip-active' : 'shell-chip-inactive'}
                        onClick={() =>
                          setDraft((d) => {
                            const cur = d.sentiment ?? []
                            const next = cur.includes(s) ? cur.filter((x) => x !== s) : [...cur, s]
                            return { ...d, sentiment: next }
                          })
                        }
                      >
                        {s}
                      </button>
                    ))}
                  </div>
                </label>
                <div className="flex gap-2 pt-1">
                  <button type="button" className="btn-ghost flex-1" onClick={() => setEditingId(null)}>
                    Cancel
                  </button>
                  <button type="button" className="btn-primary flex-1" disabled={saving} onClick={() => void save(m.id)}>
                    {saving ? 'Saving…' : 'Save rules'}
                  </button>
                </div>
              </div>
            ) : (
              <ul className="mt-2 text-[11px] text-content-muted space-y-1">
                <li>Desktop alerts: {alerts.desktop !== false ? 'On' : 'Off'}</li>
                <li>Min relevance: {alerts.min_relevance ?? 0}</li>
                <li>
                  Sentiment filter:{' '}
                  {alerts.sentiment?.length ? alerts.sentiment.join(', ') : 'All'}
                </li>
              </ul>
            )}
          </article>
        )
      })}
    </div>
  )
}
