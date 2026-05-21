import { create } from 'zustand'
import { getSupabase } from '@/lib/supabase'
import type { Workspace, WorkspaceMember } from '@/types/planner'

interface WorkspaceState {
  workspaces: Workspace[]
  currentWorkspace: Workspace | null
  membership: WorkspaceMember | null
  loading: boolean
  loadWorkspaces: () => Promise<void>
  setCurrentWorkspace: (workspace: Workspace) => Promise<void>
}

export const useWorkspaceStore = create<WorkspaceState>((set, get) => ({
  workspaces: [],
  currentWorkspace: null,
  membership: null,
  loading: false,

  loadWorkspaces: async () => {
    set({ loading: true })
    try {
      if (window.planner) {
        const cached = (await window.planner.getWorkspacesCache()) as Workspace[]
        if (cached.length) set({ workspaces: cached })
      }

      const supabase = getSupabase()
      const { data, error } = await supabase.from('workspaces').select('*').order('name')
      if (error) throw error
      const workspaces = (data ?? []) as Workspace[]
      for (const w of workspaces) {
        await window.planner?.upsertWorkspaceCache(w as unknown as Record<string, unknown>)
      }
      set({ workspaces })
      if (!get().currentWorkspace && workspaces[0]) {
        await get().setCurrentWorkspace(workspaces[0])
      }
    } finally {
      set({ loading: false })
    }
  },

  setCurrentWorkspace: async (workspace) => {
    set({ currentWorkspace: workspace })
    await window.planner?.setPreference('current_workspace_id', workspace.id)
    const supabase = getSupabase()
    const { data: { user } } = await supabase.auth.getUser()
    if (user) {
      const { data } = await supabase
        .from('workspace_members')
        .select('*')
        .eq('workspace_id', workspace.id)
        .eq('user_id', user.id)
        .maybeSingle()
      set({ membership: (data as WorkspaceMember) ?? null })
    }
  }
}))
