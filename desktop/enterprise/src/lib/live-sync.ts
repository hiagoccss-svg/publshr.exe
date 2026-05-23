import { fetchCloudWorkspaceSnapshot } from '@spaces/lib/cloud-live-sync'
import { applyCloudToLocalStore } from '@spaces/lib/local-spaces-api'
import { isTauriDesktop } from '@shared/desktop/platform'
import { getSupabase, isCloudConfigured } from '@/lib/supabase'
import { useChatStore } from '@spaces/stores/chat-store'
import { useSpacesStore } from '@spaces/stores/spaces-store'

/** Pull Supabase workspace into UI (and local browser store when not on Tauri). */
export async function runEnterpriseLiveSync(
  userId: string,
  displayName: string
): Promise<{ ok: boolean; error?: string }> {
  if (!isCloudConfigured()) {
    return { ok: false, error: 'Supabase not configured — add desktop/enterprise/.env' }
  }

  try {
    const supabase = getSupabase()
    const {
      data: { session }
    } = await supabase.auth.getSession()
    if (!session) {
      return { ok: false, error: 'No active cloud session' }
    }

    const snapshot = await fetchCloudWorkspaceSnapshot(supabase, userId, displayName)
    if (!snapshot) {
      return { ok: false, error: 'Could not load workspace from cloud' }
    }

    if (!isTauriDesktop()) {
      applyCloudToLocalStore({
        workspaceId: snapshot.workspaceId,
        workspaceName: snapshot.workspaceName,
        spaces: snapshot.spaces,
        workspaceTasks: snapshot.workspaceTasks,
        syncStatus: 'online'
      })
    }

    useSpacesStore.getState().applyCloudSnapshot(snapshot, userId, displayName)
    useChatStore.getState().applyCloudSnapshot(snapshot.channels, snapshot.messages)

    window.dispatchEvent(new CustomEvent('spaces:refresh'))
    return { ok: true }
  } catch (e) {
    return {
      ok: false,
      error: e instanceof Error ? e.message : 'Live sync failed'
    }
  }
}
