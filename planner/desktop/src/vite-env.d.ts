/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_SUPABASE_URL: string
  readonly VITE_SUPABASE_PUBLISHABLE_KEY: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}

import type { Session } from '@supabase/supabase-js'

interface PlannerAPI {
  getAuthSession: () => Promise<Session | null>
  signIn: (email: string, password: string) => Promise<Session>
  signUp: (email: string, password: string, displayName?: string) => Promise<Session | null>
  signOut: () => Promise<boolean>
  setAuthSession: (session: Session) => Promise<boolean>
  clearAuthSession: () => Promise<boolean>
  refreshAuthSession: () => Promise<Session | null>
  getPreference: (key: string) => Promise<string | null>
  setPreference: (key: string, value: string) => Promise<boolean>
  getPlannerItemsCache: (workspaceId: string) => Promise<unknown[]>
  upsertPlannerItemCache: (item: Record<string, unknown>) => Promise<boolean>
  deletePlannerItemCache: (id: string) => Promise<boolean>
  getWorkspacesCache: () => Promise<unknown[]>
  upsertWorkspaceCache: (workspace: Record<string, unknown>) => Promise<boolean>
  enqueueSync: (entry: {
    id: string
    tableName: string
    recordId: string
    operation: string
    payload: string
  }) => Promise<boolean>
  getSyncQueue: () => Promise<unknown[]>
  dequeueSync: (id: string) => Promise<boolean>
  openEditorWindow: (documentId: string, plannerItemId: string) => Promise<boolean>
  getEditorDraftCache: (documentId: string) => Promise<unknown | null>
  upsertEditorDraftCache: (draft: Record<string, unknown>) => Promise<boolean>
  openExternal: (url: string) => Promise<void>
  showNotification: (payload: { title: string; body: string }) => Promise<void>
  platform: NodeJS.Platform
  isEditorWindow: boolean
  editorDocumentId: string | null
  plannerItemId: string | null
}

interface Window {
  planner: PlannerAPI
}
