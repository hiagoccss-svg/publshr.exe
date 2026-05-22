import type { SidebarSection } from '../../../shared/types'

const COPY: Partial<Record<SidebarSection, { title: string; body: string }>> = {
  dashboard: {
    title: 'Dashboard',
    body: 'Cross-space operational summary — Phase 2.'
  },
  planner: { title: 'Planner', body: 'Linked planner items across Spaces.' },
  chat: { title: 'Chat', body: 'Space threads, mentions, and voice notes.' },
  documents: { title: 'Documents', body: 'Briefs and drafts open in dedicated desktop windows.' },
  approvals: { title: 'Approvals', body: 'Document, task, and campaign approval flows — Phase 3.' },
  reports: { title: 'Reports', body: 'Coverage and operational reporting.' },
  clients: { title: 'Clients', body: 'Client-safe Spaces and deliverable visibility.' },
  campaigns: { title: 'Campaigns', body: 'Campaign operations linked to Spaces.' },
  team: { title: 'Team', body: 'Roles, workload, and presence.' },
  media: { title: 'Media Monitoring', body: 'Coverage feeds tied to Spaces.' },
  files: { title: 'Files', body: 'Uploads, folders, and asset versioning — Phase 2.' },
  settings: { title: 'Settings', body: 'Notifications, sync, and workspace preferences.' }
}

export function PlaceholderSection({ section }: { section: SidebarSection }): React.ReactElement {
  const info = COPY[section] ?? { title: section, body: '' }
  return (
    <main className="flex flex-1 flex-col items-center justify-center p-8 text-center">
      <h1 className="text-lg font-semibold text-ink">{info.title}</h1>
      <p className="mt-2 max-w-sm text-sm text-ink-muted">{info.body}</p>
    </main>
  )
}
