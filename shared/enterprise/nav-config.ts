/**
 * Enterprise primary navigation (column 1).
 * Keep aligned with `SpacesEnterpriseSection.swift` and `sidebar-sections.ts`.
 */
import type { SpacesSidebarSectionId } from './sidebar-sections'

export type EnterpriseNavSectionId = SpacesSidebarSectionId | 'whiteboard'

export interface EnterpriseNavItem {
  id: EnterpriseNavSectionId
  label: string
  /** Lucide icon component name — resolved in renderer */
  icon: string
}

/** Primary bar menu — matches product shell first column. */
export const ENTERPRISE_MAIN_NAV: EnterpriseNavItem[] = [
  { id: 'dashboard', label: 'Dashboard', icon: 'LayoutDashboard' },
  { id: 'spaces', label: 'Spaces', icon: 'FolderKanban' },
  { id: 'planner', label: 'Planner', icon: 'Calendar' },
  { id: 'chat', label: 'Chat', icon: 'MessageSquare' },
  { id: 'documents', label: 'Documents', icon: 'FileText' },
  { id: 'whiteboard', label: 'Whiteboard', icon: 'PenLine' },
  { id: 'approvals', label: 'Approvals', icon: 'CheckCircle2' },
  { id: 'reports', label: 'Reports', icon: 'BarChart3' },
  { id: 'clients', label: 'Clients', icon: 'Briefcase' },
  { id: 'campaigns', label: 'Campaigns', icon: 'Megaphone' },
  { id: 'team', label: 'Team', icon: 'Users' },
  { id: 'media', label: 'Media Monitoring', icon: 'Radio' },
  { id: 'files', label: 'Files', icon: 'Archive' }
]
