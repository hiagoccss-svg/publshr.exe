/**
 * ClickUp Spaces Home — shared filtering, grouping, and layout for enterprise surfaces.
 * Mirror logic in `mac/publshr/.../SpacesHomeLogic.swift`.
 */

import { normalizeSpaceType, spaceTypeLabel, type CanonicalSpaceType } from './hierarchy'

export type SpacesHomeLayout = 'grid' | 'list'

export interface SpacesHomeSpace {
  id: string
  name: string
  description: string
  type: string
  status: string
  color: string
  isPinned: boolean
  isFavourite: boolean
  isArchived: boolean
  updatedAt: string
}

export interface SpacesHomeFilters {
  query: string
  typeFilter: CanonicalSpaceType | 'all'
  showArchived: boolean
}

export const DEFAULT_SPACES_HOME_FILTERS: SpacesHomeFilters = {
  query: '',
  typeFilter: 'all',
  showArchived: false
}

export interface SpacesHomeSection {
  id: 'pinned' | 'favorites' | 'all'
  title: string
  spaces: SpacesHomeSpace[]
}

function matchesQuery(space: SpacesHomeSpace, query: string): boolean {
  const q = query.trim().toLowerCase()
  if (!q) return true
  return (
    space.name.toLowerCase().includes(q) ||
    space.description.toLowerCase().includes(q) ||
    spaceTypeLabel(space.type).toLowerCase().includes(q)
  )
}

function matchesType(space: SpacesHomeSpace, typeFilter: SpacesHomeFilters['typeFilter']): boolean {
  if (typeFilter === 'all') return true
  return normalizeSpaceType(space.type) === typeFilter
}

/** Filter spaces for Spaces Home (search, type, archived toggle). */
export function filterSpacesForHome(
  spaces: SpacesHomeSpace[],
  filters: SpacesHomeFilters
): SpacesHomeSpace[] {
  return spaces.filter((s) => {
    if (!filters.showArchived && s.isArchived) return false
    if (!matchesQuery(s, filters.query)) return false
    if (!matchesType(s, filters.typeFilter)) return false
    return true
  })
}

/** ClickUp-style sections: Pinned → Favorites → All Spaces. */
export function groupSpacesForHome(spaces: SpacesHomeSpace[]): SpacesHomeSection[] {
  const pinned = spaces.filter((s) => s.isPinned)
  const favourites = spaces.filter((s) => s.isFavourite && !s.isPinned)
  const rest = spaces.filter((s) => !s.isPinned && !s.isFavourite)
  const sections: SpacesHomeSection[] = []
  if (pinned.length > 0) {
    sections.push({ id: 'pinned', title: 'Pinned', spaces: pinned })
  }
  if (favourites.length > 0) {
    sections.push({ id: 'favorites', title: 'Favorites', spaces: favourites })
  }
  const allPool = rest.length > 0 ? rest : spaces
  if (allPool.length > 0) {
    sections.push({
      id: 'all',
      title: pinned.length > 0 || favourites.length > 0 ? 'All Spaces' : 'Spaces',
      spaces: allPool
    })
  }
  return sections
}

export function buildSpacesHomeSections(
  spaces: SpacesHomeSpace[],
  filters: SpacesHomeFilters
): SpacesHomeSection[] {
  const filtered = filterSpacesForHome(spaces, filters)
  return groupSpacesForHome(filtered)
}

export function spacesHomeCounts(spaces: SpacesHomeSpace[]): {
  total: number
  active: number
  archived: number
  pinned: number
} {
  const archived = spaces.filter((s) => s.isArchived).length
  return {
    total: spaces.length,
    active: spaces.length - archived,
    archived,
    pinned: spaces.filter((s) => s.isPinned && !s.isArchived).length
  }
}
