/**
 * Operations sidebar sections (Spaces shell).
 * Mirror in `mac/publshr/.../SpacesEnterpriseSection.swift` and
 * `desktop/spaces/src/shared/types.ts` (`SidebarSection`).
 */
export const SPACES_SIDEBAR_SECTIONS = [
  { id: 'dashboard', label: 'Dashboard' },
  { id: 'spaces', label: 'Spaces' },
  { id: 'planner', label: 'Planner' },
  { id: 'chat', label: 'Chat' },
  { id: 'documents', label: 'Documents' },
  { id: 'whiteboard', label: 'Whiteboard' },
  { id: 'approvals', label: 'Approvals' },
  { id: 'reports', label: 'Reports' },
  { id: 'clients', label: 'Clients' },
  { id: 'campaigns', label: 'Campaigns' },
  { id: 'team', label: 'Team' },
  { id: 'media', label: 'Media Monitoring' },
  { id: 'files', label: 'Files' },
  { id: 'settings', label: 'Settings' }
] as const

export type SpacesSidebarSectionId = (typeof SPACES_SIDEBAR_SECTIONS)[number]['id']
