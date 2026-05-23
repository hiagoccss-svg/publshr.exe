import { useEffect } from 'react'
import { format } from 'date-fns'
import {
  Briefcase,
  Cloud,
  CloudOff,
  ExternalLink,
  FileText,
  Megaphone,
  Plus,
} from 'lucide-react'
import clsx from 'clsx'
import { useSpacesStore } from '../../stores/spaces-store'
import { getSpacesAPI } from '../../lib/api'
import type { Approval, SidebarSection, Space } from '../../../shared/types'
import { MediaMonitoringWorkspace } from './MediaMonitoringWorkspace'
import { PlannerWorkspace } from './PlannerWorkspace'
import { ReportsWorkspace } from './ReportsWorkspace'

export function EnterpriseSectionView({ section }: { section: SidebarSection }): React.ReactElement {
  switch (section) {
    case 'dashboard':
      return <ChatRedirectSection />
    case 'documents':
      return <DocumentsSection />
    case 'approvals':
      return <ApprovalsSection />
    case 'files':
      return <FilesSection />
    case 'clients':
      return <SpacesByTypeSection type="client" title="Clients" icon={Briefcase} />
    case 'campaigns':
      return <SpacesByTypeSection type="campaign" title="Campaigns" icon={Megaphone} />
    case 'team':
      return <TeamSection />
    case 'reports':
      return <ReportsWorkspace />
    case 'chat':
      return <ChatRedirectSection />
    case 'planner':
      return <PlannerWorkspace />
    case 'media':
      return <MediaMonitoringWorkspace />
    case 'whiteboard':
      return <WhiteboardHubSection />
    case 'settings':
      return <SettingsSection />
    default:
      return <ChatRedirectSection />
  }
}

function ChatRedirectSection(): React.ReactElement {
  const selectEnterpriseNav = useSpacesStore((s) => s.selectEnterpriseNav)

  useEffect(() => {
    selectEnterpriseNav('chat')
  }, [selectEnterpriseNav])

  return (
    <div className="flex h-full items-center justify-center p-6">
      <p className="text-sm text-ink-muted">Opening Chat…</p>
    </div>
  )
}

function DocumentsSection(): React.ReactElement {
  const documents = useSpacesStore((s) => s.workspaceDocuments)
  const spaces = useSpacesStore((s) => s.spaces)
  const createDocument = useSpacesStore((s) => s.createDocument)

  return (
    <div className="space-y-4 p-6">
      <SectionHeader
        title="Documents"
        description="Briefs and drafts across all Spaces. Opens in a dedicated editor window."
        action={
          <button
            type="button"
            className="library-cta-pill text-xs"
            onClick={() => {
              const title = window.prompt('Document title')
              if (title) void createDocument(title)
            }}
            disabled={spaces.length === 0}
          >
            <Plus className="h-3.5 w-3.5" />
            New document
          </button>
        }
      />
      <EntityList
        empty="No documents yet. Create one to start writing."
        items={documents}
        render={(d) => (
          <button
            type="button"
            className="flex w-full items-center justify-between rounded-lg border border-surface-border px-3 py-2 text-left text-sm hover:bg-surface-muted"
            onClick={() => getSpacesAPI().openDocumentWindow(d.id, d.title)}
          >
            <span className="flex items-center gap-2 font-medium text-ink">
              <FileText className="h-4 w-4 text-ink-muted" />
              {d.title}
            </span>
            <span className="text-xs text-ink-muted">
              {d.spaceName} · {format(new Date(d.updatedAt), 'MMM d')}
            </span>
          </button>
        )}
      />
    </div>
  )
}

function ApprovalsSection(): React.ReactElement {
  const approvals = useSpacesStore((s) => s.workspaceApprovals)
  const spaces = useSpacesStore((s) => s.spaces)
  const setActiveSpace = useSpacesStore((s) => s.setActiveSpace)

  const spaceName = (spaceId: string): string => spaces.find((s) => s.id === spaceId)?.name ?? 'Space'

  return (
    <div className="space-y-4 p-6">
      <SectionHeader title="Approvals" description="Document, task, and campaign approval requests." />
      <EntityList
        empty="No approval requests."
        items={approvals}
        render={(a) => (
          <button
            type="button"
            className="flex w-full items-center justify-between rounded-lg border border-surface-border px-3 py-2 text-left text-sm hover:bg-surface-muted"
            onClick={() => void setActiveSpace(a.spaceId)}
          >
            <span className="font-medium text-ink">{a.title}</span>
            <ApprovalBadge status={a.status} spaceName={spaceName(a.spaceId)} />
          </button>
        )}
      />
    </div>
  )
}

function FilesSection(): React.ReactElement {
  const files = useSpacesStore((s) => s.workspaceFiles)
  const spaces = useSpacesStore((s) => s.spaces)
  const createFileLink = useSpacesStore((s) => s.createFileLink)

  return (
    <div className="space-y-4 p-6">
      <SectionHeader
        title="Files"
        description="Workspace file links and assets."
        action={
          <button
            type="button"
            className="library-cta-pill text-xs"
            disabled={spaces.length === 0}
            onClick={() => {
              const fileName = window.prompt('File name')
              const fileUrl = window.prompt('File URL')
              if (fileName && fileUrl) void createFileLink(fileName, fileUrl)
            }}
          >
            <Plus className="h-3.5 w-3.5" />
            Add link
          </button>
        }
      />
      <EntityList
        empty="No files yet. Add a link to an asset or upload URL."
        items={files}
        render={(f) => (
          <a
            href={f.fileUrl}
            target="_blank"
            rel="noreferrer"
            className="flex items-center justify-between rounded-lg border border-surface-border px-3 py-2 text-sm hover:bg-surface-muted"
          >
            <span className="font-medium text-ink">{f.fileName}</span>
            <ExternalLink className="h-3.5 w-3.5 text-accent" />
          </a>
        )}
      />
    </div>
  )
}

function SpacesByTypeSection({
  type,
  title,
  icon: Icon
}: {
  type: Space['type']
  title: string
  icon: React.ComponentType<{ className?: string }>
}): React.ReactElement {
  const spaces = useSpacesStore((s) => s.spaces.filter((sp) => sp.type === type && !sp.isArchived))
  const setActiveSpace = useSpacesStore((s) => s.setActiveSpace)
  const setActiveSection = useSpacesStore((s) => s.setActiveSection)

  return (
    <div className="space-y-4 p-6">
      <SectionHeader title={title} description={`${title} Spaces in this workspace.`} />
      {spaces.length === 0 ? (
        <p className="text-sm text-ink-muted">No {title.toLowerCase()} spaces yet.</p>
      ) : (
        <ul className="space-y-2">
          {spaces.map((s) => (
            <li key={s.id}>
              <button
                type="button"
                className="flex w-full items-center gap-3 rounded-lg border border-surface-border px-3 py-2 text-left hover:bg-surface-muted"
                onClick={() => {
                  setActiveSection('spaces')
                  void setActiveSpace(s.id)
                }}
              >
                <Icon className="h-4 w-4 text-accent" />
                <div>
                  <p className="text-sm font-medium text-ink">{s.name}</p>
                  <p className="text-xs text-ink-muted capitalize">{s.status}</p>
                </div>
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}

function TeamSection(): React.ReactElement {
  const members = useSpacesStore((s) => s.workspaceMembers)

  return (
    <div className="space-y-4 p-6">
      <SectionHeader title="Team" description="Members across all Spaces." />
      {members.length === 0 ? (
        <p className="text-sm text-ink-muted">No team members yet.</p>
      ) : (
        <ul className="grid gap-2 sm:grid-cols-2">
          {members.map((m) => (
            <li
              key={m.userId}
              className="flex items-center gap-3 rounded-lg border border-surface-border px-3 py-2"
            >
              <span
                className="flex h-8 w-8 items-center justify-center rounded-full text-xs font-semibold text-white"
                style={{ backgroundColor: m.avatarColor }}
              >
                {m.name[0]?.toUpperCase()}
              </span>
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-medium text-ink">
                  {m.name}
                  {m.isOnline && (
                    <span className="ml-2 inline-block h-1.5 w-1.5 rounded-full bg-status-approved" />
                  )}
                </p>
                <p className="truncate text-xs text-ink-muted">
                  {m.role} · {m.spaceCount} space{m.spaceCount === 1 ? '' : 's'}
                </p>
              </div>
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}

function WhiteboardHubSection(): React.ReactElement {
  const spaces = useSpacesStore((s) => s.spaces)
  const setActiveSpace = useSpacesStore((s) => s.setActiveSpace)
  const selectEnterpriseNav = useSpacesStore((s) => s.selectEnterpriseNav)

  return (
    <div className="space-y-4 p-6">
      <SectionHeader
        title="Whiteboard"
        description="Open a Space to use the tldraw canvas. Boards sync when Supabase is connected."
      />
      {spaces.length === 0 ? (
        <p className="text-sm text-ink-muted">Create a Space first, then open its Whiteboard view.</p>
      ) : (
        <ul className="space-y-2">
          {spaces.map((s) => (
            <li key={s.id}>
              <button
                type="button"
                className="flex w-full items-center justify-between rounded-lg border border-surface-border px-3 py-2 text-left text-sm hover:bg-surface-muted"
                onClick={() => {
                  void setActiveSpace(s.id)
                  selectEnterpriseNav('whiteboard')
                }}
              >
                <span className="font-medium text-ink">{s.name}</span>
                <span className="text-xs text-ink-muted">Open canvas</span>
              </button>
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}

function SettingsSection(): React.ReactElement {
  const workspace = useSpacesStore((s) => s.workspace)
  const syncStatus = useSpacesStore((s) => s.syncStatus)
  const loadWorkspaceData = useSpacesStore((s) => s.loadWorkspaceData)

  const SyncIcon = syncStatus === 'online' || syncStatus === 'syncing' ? Cloud : CloudOff

  return (
    <div className="max-w-lg space-y-6 p-6">
      <SectionHeader title="Settings" description="Workspace preferences and sync." />
      <div className="library-card space-y-4 p-4">
        <div>
          <p className="text-xs font-medium uppercase text-ink-muted">Workspace</p>
          <p className="mt-1 text-sm font-medium text-ink">{workspace?.name ?? '—'}</p>
          <p className="text-xs text-ink-muted">{workspace?.id}</p>
        </div>
        <div className="flex items-center gap-2">
          <SyncIcon className="h-4 w-4 text-ink-muted" />
          <span className="text-sm capitalize text-ink">Sync: {syncStatus}</span>
        </div>
        <button
          type="button"
          className="rounded-lg border border-surface-border px-3 py-1.5 text-xs text-ink-secondary hover:bg-surface-muted"
          onClick={() => void loadWorkspaceData()}
        >
          Refresh workspace data
        </button>
      </div>
    </div>
  )
}

function SectionHeader({
  title,
  description,
  action,
  icon: Icon
}: {
  title: string
  description: string
  action?: React.ReactNode
  icon?: React.ComponentType<{ className?: string }>
}): React.ReactElement {
  return (
    <header className="flex flex-wrap items-start justify-between gap-3">
      <div>
        <h1 className="flex items-center gap-2 text-xl font-semibold text-ink">
          {Icon && <Icon className="h-5 w-5 text-accent" />}
          {title}
        </h1>
        <p className="mt-1 max-w-2xl text-sm text-ink-secondary">{description}</p>
      </div>
      {action}
    </header>
  )
}

function EntityList<T>({
  items,
  empty,
  render
}: {
  items: T[]
  empty: string
  render: (item: T) => React.ReactNode
}): React.ReactElement {
  if (items.length === 0) return <p className="text-sm text-ink-muted">{empty}</p>
  return <ul className="space-y-2">{items.map((item, i) => <li key={i}>{render(item)}</li>)}</ul>
}

function ApprovalBadge({
  status,
  spaceName
}: {
  status: Approval['status']
  spaceName: string
}): React.ReactElement {
  return (
    <span className="flex items-center gap-2 text-xs">
      <span
        className={clsx(
          'rounded px-1.5 py-0.5 capitalize',
          status === 'approved' && 'bg-status-approved/15 text-status-approved',
          status === 'rejected' && 'bg-status-blocked/15 text-status-blocked',
          (status === 'requested' || status === 'in_review') && 'bg-accent-soft text-accent'
        )}
      >
        {status.replace(/_/g, ' ')}
      </span>
      <span className="text-ink-muted">{spaceName}</span>
    </span>
  )
}
