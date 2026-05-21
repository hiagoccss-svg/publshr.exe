import { useEffect } from 'react'
import { useAuthStore } from '@/stores/authStore'
import { useWorkspaceStore } from '@/stores/workspaceStore'
import { usePlannerStore } from '@/stores/plannerStore'
import { isSupabaseConfigured } from '@/lib/supabase'
import AuthScreen from '@/components/auth/AuthScreen'
import PlannerShell from '@/components/layout/PlannerShell'
import EditorWindow from '@/components/editor/EditorWindow'
import SetupScreen from '@/components/auth/SetupScreen'

export default function App() {
  const { user, loading, initialize } = useAuthStore()
  const { currentWorkspace, loadWorkspaces } = useWorkspaceStore()
  const loadItems = usePlannerStore((s) => s.loadItems)
  const syncToCloud = usePlannerStore((s) => s.syncToCloud)

  const isEditor = window.planner?.isEditorWindow ?? false

  useEffect(() => {
    if (isSupabaseConfigured()) void initialize()
    else useAuthStore.setState({ loading: false })
  }, [initialize])

  useEffect(() => {
    if (user) void loadWorkspaces()
  }, [user, loadWorkspaces])

  useEffect(() => {
    if (currentWorkspace) {
      void loadItems(currentWorkspace.id)
      const interval = setInterval(() => void syncToCloud(currentWorkspace.id), 30000)
      return () => clearInterval(interval)
    }
  }, [currentWorkspace, loadItems, syncToCloud])

  if (isEditor) {
    return <EditorWindow />
  }

  if (!isSupabaseConfigured()) {
    return <SetupScreen />
  }

  if (loading) {
    return (
      <div className="flex h-screen items-center justify-center bg-surface">
        <p className="text-sm text-ink-muted">Loading Planner…</p>
      </div>
    )
  }

  if (!user) {
    return <AuthScreen />
  }

  return <PlannerShell />
}
