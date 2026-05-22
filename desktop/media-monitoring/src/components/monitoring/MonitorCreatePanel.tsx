import { X } from 'lucide-react'
import { useState } from 'react'
import { useMonitoringStore } from '@/store/monitoringStore'
import { cursor } from '@/theme/cursor'

const REGIONS = ['Global', 'Europe', 'Americas', 'Middle East', 'Asia Pacific']
const LANGUAGES = ['en', 'ar', 'fr', 'de', 'es']

interface Props {
  onCreated: () => void
}

export function MonitorCreatePanel({ onCreated }: Props) {
  const { showCreatePanel, setShowCreatePanel, setActiveMonitor } = useMonitoringStore()
  const [name, setName] = useState('')
  const [keywords, setKeywords] = useState('')
  const [exclusions, setExclusions] = useState('')
  const [regions, setRegions] = useState<string[]>([])
  const [languages, setLanguages] = useState<string[]>(['en'])
  const [client, setClient] = useState('')
  const [campaign, setCampaign] = useState('')
  const [saving, setSaving] = useState(false)

  if (!showCreatePanel) return null

  const toggle = (list: string[], value: string, setter: (v: string[]) => void) => {
    setter(list.includes(value) ? list.filter((x) => x !== value) : [...list, value])
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!name.trim() || !keywords.trim()) return
    setSaving(true)
    try {
      const monitor = await window.publshr.createMonitor({
        name: name.trim(),
        keywords: keywords.trim(),
        exclusions: exclusions.trim() || undefined,
        regions: regions.length ? regions : undefined,
        language_filters: languages,
        linked_client: client.trim() || undefined,
        linked_campaign: campaign.trim() || undefined
      })
      setActiveMonitor((monitor as { id: string }).id)
      await window.publshr.startMonitoring((monitor as { id: string }).id)
      useMonitoringStore.setState({ isMonitoring: true, syncStatus: 'syncing' })
      setShowCreatePanel(false)
      onCreated()
      setName('')
      setKeywords('')
      setExclusions('')
    } finally {
      setSaving(false)
    }
  }

  return (
    <div
      className="absolute inset-y-0 right-0 z-20 flex flex-col border-l animate-fade-in"
      style={{
        width: 340,
        backgroundColor: cursor.sideBar,
        borderColor: cursor.border
      }}
    >
      <div
        className="flex items-center justify-between px-3 py-2 border-b"
        style={{ borderColor: cursor.border }}
      >
        <h2 className="text-[13px] font-medium text-content">New monitoring profile</h2>
        <button type="button" className="btn-ghost p-1" onClick={() => setShowCreatePanel(false)} aria-label="Close">
          <X size={15} />
        </button>
      </div>

      <form onSubmit={handleSubmit} className="flex-1 overflow-y-auto px-3 py-3 space-y-3 text-[12px]">
        <Field label="Monitor name" required>
          <input className="input-field" value={name} onChange={(e) => setName(e.target.value)} placeholder="e.g. Publshr brand tracking" />
        </Field>

        <Field label="Keywords" required hint='Boolean: "Apple AND Vision Pro", "Tesla NOT stock"'>
          <textarea
            className="input-field min-h-[72px] resize-none"
            value={keywords}
            onChange={(e) => setKeywords(e.target.value)}
            placeholder="Publshr OR Publishr"
          />
        </Field>

        <Field label="Exclusions" hint="Terms to exclude from results">
          <input className="input-field" value={exclusions} onChange={(e) => setExclusions(e.target.value)} placeholder="NOT stock, NOT rumor" />
        </Field>

        <Field label="Regions">
          <div className="flex flex-wrap gap-1">
            {REGIONS.map((r) => (
              <Chip key={r} active={regions.includes(r)} onClick={() => toggle(regions, r, setRegions)}>
                {r}
              </Chip>
            ))}
          </div>
        </Field>

        <Field label="Languages">
          <div className="flex flex-wrap gap-1">
            {LANGUAGES.map((l) => (
              <Chip key={l} active={languages.includes(l)} onClick={() => toggle(languages, l, setLanguages)}>
                {l.toUpperCase()}
              </Chip>
            ))}
          </div>
        </Field>

        <Field label="Linked client">
          <input className="input-field" value={client} onChange={(e) => setClient(e.target.value)} />
        </Field>

        <Field label="Linked campaign">
          <input className="input-field" value={campaign} onChange={(e) => setCampaign(e.target.value)} />
        </Field>

        <p className="text-[10px] text-content-dim leading-relaxed">
          Monitoring searches approved publications only — wire services, trade press, and verified media from your publication database.
        </p>
      </form>

      <div className="px-3 py-2 border-t flex gap-2" style={{ borderColor: cursor.border }}>
        <button type="button" className="btn-ghost flex-1" onClick={() => setShowCreatePanel(false)}>
          Cancel
        </button>
        <button type="button" className="btn-primary flex-1" disabled={saving} onClick={() => void handleSubmit({ preventDefault: () => {} } as React.FormEvent)}>
          {saving ? 'Creating…' : 'Create & start'}
        </button>
      </div>
    </div>
  )
}

function Field({
  label,
  required,
  hint,
  children
}: {
  label: string
  required?: boolean
  hint?: string
  children: React.ReactNode
}) {
  return (
    <label className="block">
      <span className="text-[11px] text-content-muted">
        {label}
        {required && <span className="text-sentiment-negative ml-0.5">*</span>}
      </span>
      {hint && <p className="text-[10px] text-content-dim mt-0.5 mb-1">{hint}</p>}
      <div className="mt-1">{children}</div>
    </label>
  )
}

function Chip({
  children,
  active,
  onClick
}: {
  children: React.ReactNode
  active: boolean
  onClick: () => void
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={active ? 'cursor-chip-active' : 'cursor-chip-inactive'}
    >
      {children}
    </button>
  )
}
