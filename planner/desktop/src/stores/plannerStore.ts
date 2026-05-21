import { create } from 'zustand'
import { v4 as uuidv4 } from 'uuid'
import { getSupabase } from '@/lib/supabase'
import {
  enqueuePlannerItemSync,
  loadPlannerItemsFromCache,
  processSyncQueue,
  savePlannerItemLocally
} from '@/lib/sync/localFirst'
import type {
  PlannerItem,
  PlannerItemStatus,
  PlannerItemType,
  PlannerView,
  Priority
} from '@/types/planner'

export type PlannerFilters = {
  types: PlannerItemType[]
  statuses: PlannerItemStatus[]
  ownerId: string | null
  clientId: string | null
  campaignId: string | null
  overdueOnly: boolean
  assignedToMe: boolean
}

interface PlannerState {
  items: PlannerItem[]
  selectedId: string | null
  view: PlannerView
  filters: PlannerFilters
  syncStatus: 'idle' | 'syncing' | 'offline' | 'error'
  loading: boolean
  createPanelOpen: boolean
  contextPanelOpen: boolean
  timelineZoom: 'week' | 'month' | 'quarter'
  calendarMode: 'day' | 'week' | 'month' | 'agenda'
  setView: (view: PlannerView) => void
  setSelectedId: (id: string | null) => void
  setCreatePanelOpen: (open: boolean) => void
  setContextPanelOpen: (open: boolean) => void
  setTimelineZoom: (zoom: 'week' | 'month' | 'quarter') => void
  setCalendarMode: (mode: 'day' | 'week' | 'month' | 'agenda') => void
  setFilters: (filters: Partial<PlannerFilters>) => void
  loadItems: (workspaceId: string) => Promise<void>
  syncToCloud: (workspaceId: string) => Promise<void>
  createItem: (input: Partial<PlannerItem> & { title: string; type: PlannerItemType }, workspaceId: string, userId: string) => Promise<PlannerItem>
  updateItem: (id: string, patch: Partial<PlannerItem>) => Promise<void>
  moveItemStatus: (id: string, status: PlannerItemStatus) => Promise<void>
  rescheduleItem: (id: string, startDate: string | null, dueDate: string | null) => Promise<void>
}

const defaultFilters: PlannerFilters = {
  types: [],
  statuses: [],
  ownerId: null,
  clientId: null,
  campaignId: null,
  overdueOnly: false,
  assignedToMe: false
}

function applyFilters(items: PlannerItem[], filters: PlannerFilters, userId?: string): PlannerItem[] {
  return items.filter((item) => {
    if (filters.types.length && !filters.types.includes(item.type)) return false
    if (filters.statuses.length && !filters.statuses.includes(item.status)) return false
    if (filters.ownerId && item.owner_id !== filters.ownerId) return false
    if (filters.clientId && item.client_id !== filters.clientId) return false
    if (filters.campaignId && item.campaign_id !== filters.campaignId) return false
    if (filters.overdueOnly && item.due_date) {
      if (new Date(item.due_date) >= new Date()) return false
      if (item.status === 'completed' || item.status === 'published') return false
    }
    if (filters.assignedToMe && item.owner_id !== userId) return false
    return true
  })
}

export const usePlannerStore = create<PlannerState>((set, get) => ({
  items: [],
  selectedId: null,
  view: 'timeline',
  filters: defaultFilters,
  syncStatus: 'idle',
  loading: false,
  createPanelOpen: false,
  contextPanelOpen: true,
  timelineZoom: 'month',
  calendarMode: 'week',

  setView: (view) => set({ view }),
  setSelectedId: (id) => set({ selectedId: id, contextPanelOpen: id !== null }),
  setCreatePanelOpen: (open) => set({ createPanelOpen: open }),
  setContextPanelOpen: (open) => set({ contextPanelOpen: open }),
  setTimelineZoom: (zoom) => set({ timelineZoom: zoom }),
  setCalendarMode: (mode) => set({ calendarMode: mode }),
  setFilters: (partial) => set({ filters: { ...get().filters, ...partial } }),

  loadItems: async (workspaceId) => {
    set({ loading: true })
    try {
      const cached = await loadPlannerItemsFromCache(workspaceId)
      if (cached.length) set({ items: cached, loading: false })

      const supabase = getSupabase()
      const { data, error } = await supabase
        .from('planner_items')
        .select('*')
        .eq('workspace_id', workspaceId)
        .order('due_date', { ascending: true, nullsFirst: false })

      if (!error && data) {
        const items = (data as PlannerItem[]).map((i) => ({
          ...i,
          tags: Array.isArray(i.tags) ? i.tags : []
        }))
        for (const item of items) {
          await savePlannerItemLocally(item, 'synced')
        }
        set({ items, syncStatus: 'idle' })
      } else if (!cached.length) {
        set({ syncStatus: 'offline' })
      }
    } catch {
      set({ syncStatus: 'offline' })
    } finally {
      set({ loading: false })
    }
  },

  syncToCloud: async (workspaceId) => {
    set({ syncStatus: 'syncing' })
    const supabase = getSupabase()
    const result = await processSyncQueue(async (tableName, operation, payload) => {
      if (tableName !== 'planner_items') return
      if (operation === 'delete') {
        await supabase.from('planner_items').delete().eq('id', payload.id as string)
      } else {
        const row = { ...payload, workspace_id: workspaceId } as Record<string, unknown>
        delete row._syncStatus
        await supabase.from('planner_items').upsert(row)
      }
    })
    set({ syncStatus: result.failed ? 'error' : 'idle' })
    await get().loadItems(workspaceId)
  },

  createItem: async (input, workspaceId, userId) => {
    const now = new Date().toISOString()
    const item: PlannerItem = {
      id: uuidv4(),
      workspace_id: workspaceId,
      project_id: input.project_id ?? null,
      client_id: input.client_id ?? null,
      campaign_id: input.campaign_id ?? null,
      title: input.title,
      type: input.type,
      status: input.status ?? 'idea',
      priority: (input.priority as Priority) ?? 'medium',
      owner_id: input.owner_id ?? userId,
      description: input.description ?? null,
      start_date: input.start_date ?? null,
      due_date: input.due_date ?? null,
      publish_date: input.publish_date ?? null,
      tags: input.tags ?? [],
      created_by: userId,
      created_at: now,
      updated_at: now,
      editor_document_id: input.editor_document_id ?? null,
      _syncStatus: 'pending'
    }
    set({ items: [item, ...get().items], selectedId: item.id })
    await savePlannerItemLocally(item, 'pending')
    await enqueuePlannerItemSync(item, 'insert')
    void get().syncToCloud(workspaceId)
    return item
  },

  updateItem: async (id, patch) => {
    const items = get().items.map((i) =>
      i.id === id ? { ...i, ...patch, updated_at: new Date().toISOString(), _syncStatus: 'pending' as const } : i
    )
    const item = items.find((i) => i.id === id)!
    set({ items })
    await savePlannerItemLocally(item, 'pending')
    await enqueuePlannerItemSync(item, 'update')
  },

  moveItemStatus: async (id, status) => {
    await get().updateItem(id, { status })
  },

  rescheduleItem: async (id, startDate, dueDate) => {
    await get().updateItem(id, { start_date: startDate, due_date: dueDate })
  }
}))

export function useFilteredItems(userId?: string): PlannerItem[] {
  const items = usePlannerStore((s) => s.items)
  const filters = usePlannerStore((s) => s.filters)
  return applyFilters(items, filters, userId)
}

export function useSelectedItem(): PlannerItem | null {
  const items = usePlannerStore((s) => s.items)
  const selectedId = usePlannerStore((s) => s.selectedId)
  return items.find((i) => i.id === selectedId) ?? null
}
