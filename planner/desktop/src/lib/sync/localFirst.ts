import { v4 as uuidv4 } from 'uuid'
import type { PlannerItem } from '@/types/planner'

function getApi() {
  if (!window.planner) throw new Error('Planner API not available (run inside Electron)')
  return window.planner
}

export async function loadPlannerItemsFromCache(workspaceId: string): Promise<PlannerItem[]> {
  const raw = await getApi().getPlannerItemsCache(workspaceId)
  return raw as PlannerItem[]
}

export async function savePlannerItemLocally(
  item: PlannerItem,
  syncStatus: 'synced' | 'pending' = 'pending'
): Promise<void> {
  await getApi().upsertPlannerItemCache({ ...item, _syncStatus: syncStatus })
}

export async function enqueuePlannerItemSync(
  item: PlannerItem,
  operation: 'insert' | 'update' | 'delete'
): Promise<void> {
  await getApi().enqueueSync({
    id: uuidv4(),
    tableName: 'planner_items',
    recordId: item.id,
    operation,
    payload: JSON.stringify(item)
  })
}

export async function processSyncQueue(
  push: (tableName: string, operation: string, payload: Record<string, unknown>) => Promise<void>
): Promise<{ synced: number; failed: number }> {
  const queue = (await getApi().getSyncQueue()) as {
    id: string
    table_name: string
    operation: string
    payload: string
  }[]
  let synced = 0
  let failed = 0
  for (const entry of queue) {
    try {
      const payload = JSON.parse(entry.payload) as Record<string, unknown>
      await push(entry.table_name, entry.operation, payload)
      await getApi().dequeueSync(entry.id)
      synced++
    } catch {
      failed++
    }
  }
  return { synced, failed }
}
