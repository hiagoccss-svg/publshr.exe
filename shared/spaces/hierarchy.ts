/**
 * ClickUp-aligned work hierarchy for Publshr Spaces.
 * @see https://help.clickup.com/hc/en-us/articles/6309466958103-Intro-to-Spaces
 * @see desktop/spaces/docs/CLICKUP_SPACES_PARITY.md
 *
 * We use **Space** for every top-level operational area (departments, clients, campaigns).
 * **Folders** group related work inside a Space (ClickUp uses folders for projects).
 * **Lists** hold tasks — do not add a separate top-level "Project" entity.
 */

export const SPACES_HIERARCHY_LEVELS = [
  { id: 'workspace', label: 'Workspace', description: 'Your company or organization' },
  { id: 'space', label: 'Space', description: 'Team, department, client, or initiative' },
  { id: 'folder', label: 'Folder', description: 'Project, campaign group, or workstream inside a Space' },
  { id: 'list', label: 'List', description: 'Phase, sprint, or category of tasks' },
  { id: 'task', label: 'Task', description: 'Action item with status, assignee, and dates' }
] as const

export type SpacesHierarchyLevelId = (typeof SPACES_HIERARCHY_LEVELS)[number]['id']

/** Breadcrumb-style chain shown in Spaces Home and onboarding. */
export const SPACES_HIERARCHY_CHAIN = 'Workspace → Space → Folder → List → Task'

/** Short hint under Spaces Home title. */
export const SPACES_HOME_TAGLINE =
  'One Space per team or client — use folders and lists for projects and deliverables (ClickUp-style).'

/** UI copy when creating a folder (maps to ClickUp "project in a folder"). */
export const SPACES_NEW_FOLDER_PROMPT = 'Folder name'
export const SPACES_NEW_FOLDER_PLACEHOLDER = 'e.g. Q2 launch'

/** Legacy space `type` values stored as `project` are shown as initiative spaces. */
export function normalizeSpaceType(type: string): string {
  const t = type.trim().toLowerCase()
  if (t === 'project') return 'initiative'
  return t || 'general'
}

export function spaceTypeLabel(type: string): string {
  const key = normalizeSpaceType(type)
  const found = SPACE_TYPE_OPTIONS.find((o) => o.value === key)
  return found?.label ?? key.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase())
}

/** Canonical space types — no separate `project` type (use folders inside a Space). */
export const SPACE_TYPE_OPTIONS = [
  { value: 'general', label: 'General' },
  { value: 'department', label: 'Department' },
  { value: 'client', label: 'Client' },
  { value: 'campaign', label: 'Campaign' },
  { value: 'initiative', label: 'Initiative' },
  { value: 'editorial', label: 'Editorial' },
  { value: 'operation', label: 'Operation' },
  { value: 'launch', label: 'Launch' },
  { value: 'event', label: 'Event' },
  { value: 'retainer', label: 'Retainer' },
  { value: 'publication', label: 'Publication' }
] as const

export type CanonicalSpaceType = (typeof SPACE_TYPE_OPTIONS)[number]['value']
