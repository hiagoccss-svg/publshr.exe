/**
 * Canonical Spaces views bar — Electron renderer ("web") and macOS IDE must stay in sync.
 * @see shared/spaces/PARITY.md
 * @see mac/publshr/Sources/PublshrApp/Spaces/SpacesViewModes.swift
 */

export const SPACES_VIEW_TAB_IDS = [
  'overview',
  'list',
  'board',
  'whiteboard',
  'calendar',
  'timeline',
  'workload',
  'priority'
] as const

export type SpacesViewTabId = (typeof SPACES_VIEW_TAB_IDS)[number]

export const SPACES_VIEW_TABS: ReadonlyArray<{ id: SpacesViewTabId; label: string }> = [
  { id: 'overview', label: 'Overview' },
  { id: 'list', label: 'List' },
  { id: 'board', label: 'Board' },
  { id: 'whiteboard', label: 'Whiteboard' },
  { id: 'calendar', label: 'Calendar' },
  { id: 'timeline', label: 'Timeline' },
  { id: 'workload', label: 'Workload' },
  { id: 'priority', label: 'Priority' }
]

/** Default view options in Space settings (subset users pick as landing view). */
export const SPACES_DEFAULT_VIEW_OPTIONS: ReadonlyArray<{ id: SpacesViewTabId; label: string }> =
  SPACES_VIEW_TABS.filter((t) => t.id !== 'whiteboard')
