import clsx from 'clsx'
import { useSpacesStore } from '../../stores/spaces-store'
import type { SidebarSection } from '../../../shared/types'

const SECTION_LINKS: Partial<
  Record<SidebarSection, { id: string; label: string; section?: SidebarSection }[]>
> = {
  documents: [{ id: 'all', label: 'All documents' }],
  approvals: [
    { id: 'pending', label: 'Pending' },
    { id: 'in_review', label: 'In review' },
    { id: 'approved', label: 'Approved' }
  ],
  planner: [
    { id: 'week', label: 'This week' },
    { id: 'overdue', label: 'Overdue' }
  ],
  team: [{ id: 'members', label: 'Members' }],
  files: [{ id: 'all', label: 'All files' }],
  reports: [{ id: 'summary', label: 'Summary' }],
  clients: [{ id: 'client', label: 'Client spaces' }],
  campaigns: [{ id: 'campaign', label: 'Campaign spaces' }],
  media: [{ id: 'coverage', label: 'Coverage feed' }]
}

/** Column 2 navigation for enterprise modules (dashboard, documents, …). */
export function ModuleContextNav({ section }: { section: SidebarSection }): React.ReactElement {
  const searchQuery = useSpacesStore((s) => s.searchQuery)
  const setSearchQuery = useSpacesStore((s) => s.setSearchQuery)
  const workspaceDocuments = useSpacesStore((s) => s.workspaceDocuments)
  const workspaceApprovals = useSpacesStore((s) => s.workspaceApprovals)
  const workspaceTasks = useSpacesStore((s) => s.workspaceTasks)
  const workspaceMembers = useSpacesStore((s) => s.workspaceMembers)
  const workspaceFiles = useSpacesStore((s) => s.workspaceFiles)
  const spaces = useSpacesStore((s) => s.spaces)

  const links = SECTION_LINKS[section] ?? [{ id: 'main', label: 'Browse' }]
  const q = searchQuery.trim().toLowerCase()

  const counts: Record<string, number> = {
    all: workspaceDocuments.length,
    pending: workspaceApprovals.filter((a) => a.status === 'requested').length,
    in_review: workspaceApprovals.filter((a) => a.status === 'in_review').length,
    approved: workspaceApprovals.filter((a) => a.status === 'approved').length,
    week: workspaceTasks.length,
    overdue: workspaceTasks.filter((t) => t.dueDate).length,
    members: workspaceMembers.length,
    client: spaces.filter((s) => s.type === 'client').length,
    campaign: spaces.filter((s) => s.type === 'campaign').length
  }

  if (section === 'documents' && workspaceDocuments.length > 0) {
    return (
      <div className="flex min-h-0 flex-1 flex-col overflow-hidden">
        <p className="library-section-label">Documents</p>
        <nav className="flex-1 space-y-0.5 overflow-y-auto px-2 pb-2">
          {workspaceDocuments
            .filter((d) => !q || d.title.toLowerCase().includes(q))
            .slice(0, 24)
            .map((doc) => (
              <button
                key={doc.id}
                type="button"
                className="library-nav-row w-full text-sm"
                onClick={() => setSearchQuery(doc.title)}
              >
                <span className="truncate">{doc.title}</span>
              </button>
            ))}
        </nav>
      </div>
    )
  }

  if (section === 'files' && workspaceFiles.length > 0) {
    return (
      <div className="flex min-h-0 flex-1 flex-col overflow-hidden">
        <p className="library-section-label">Files</p>
        <nav className="flex-1 space-y-0.5 overflow-y-auto px-2 pb-2">
          {workspaceFiles
            .filter((f) => !q || f.fileName.toLowerCase().includes(q))
            .map((file) => (
              <button key={file.id} type="button" className="library-nav-row w-full text-sm">
                <span className="truncate">{file.fileName}</span>
              </button>
            ))}
        </nav>
      </div>
    )
  }

  return (
    <div className="flex min-h-0 flex-1 flex-col overflow-hidden">
      <p className="library-section-label">{sectionLabel(section)}</p>
      <nav className="flex-1 space-y-0.5 overflow-y-auto px-2 pb-2">
        {links.map((link) => {
          const count = counts[link.id]
          return (
            <button
              key={link.id}
              type="button"
              className={clsx('library-nav-row w-full text-sm', searchQuery === link.label && 'library-nav-row-active')}
              onClick={() => setSearchQuery(link.label)}
            >
              <span className="truncate">{link.label}</span>
              {count !== undefined && count > 0 ? (
                <span className="ml-auto text-[10px] text-ink-muted">{count}</span>
              ) : null}
            </button>
          )
        })}
      </nav>
    </div>
  )
}

function sectionLabel(section: SidebarSection): string {
  const map: Record<string, string> = {
    documents: 'Documents',
    approvals: 'Approvals',
    planner: 'Planner',
    team: 'Team',
    files: 'Files',
    reports: 'Reports',
    clients: 'Clients',
    campaigns: 'Campaigns',
    media: 'Media Monitoring'
  }
  return map[section] ?? 'Workspace'
}
