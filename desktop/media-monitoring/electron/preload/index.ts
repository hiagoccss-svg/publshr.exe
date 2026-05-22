import { contextBridge, ipcRenderer } from 'electron'

export interface MonitorCreateInput {
  name: string
  keywords: string
  exclusions?: string
  regions?: string[]
  language_filters?: string[]
  linked_client?: string
  linked_campaign?: string
}

export interface ResultFilterOptions {
  limit?: number
  offset?: number
  sentiment?: string
  savedOnly?: boolean
  search?: string
  sort?: string
  days?: number
}

const api = {
  restoreSession: () => ipcRenderer.invoke('auth:restore'),
  reconcileCloud: () => ipcRenderer.invoke('auth:reconcile-cloud'),
  signIn: (email: string, password: string) => ipcRenderer.invoke('auth:sign-in', email, password),
  signUp: (email: string, password: string, displayName: string) =>
    ipcRenderer.invoke('auth:sign-up', email, password, displayName),
  verifyOtp: (email: string, token: string) => ipcRenderer.invoke('auth:verify-otp', email, token),
  resendOtp: (email: string) => ipcRenderer.invoke('auth:resend-otp', email),
  signOut: () => ipcRenderer.invoke('auth:sign-out'),
  getAuthState: () => ipcRenderer.invoke('auth:get-state'),
  getProfile: () => ipcRenderer.invoke('auth:get-profile'),
  biometricStatus: () => ipcRenderer.invoke('auth:biometric-status'),
  biometricEnable: () => ipcRenderer.invoke('auth:biometric-enable'),
  biometricUnlock: () => ipcRenderer.invoke('auth:biometric-unlock'),
  biometricDisable: () => ipcRenderer.invoke('auth:biometric-disable'),
  pullSync: () => ipcRenderer.invoke('sync:pull'),
  getSyncStatus: () => ipcRenderer.invoke('sync:status'),
  onSyncStatus: (callback: (payload: unknown) => void) => {
    const handler = (_: unknown, payload: unknown) => callback(payload)
    ipcRenderer.on('sync:status', handler)
    return () => {
      ipcRenderer.removeListener('sync:status', handler)
    }
  },
  onRemoteArticle: (callback: (row: unknown) => void) => {
    const handler = (_: unknown, row: unknown) => callback(row)
    ipcRenderer.on('sync:remote-article', handler)
    return () => {
      ipcRenderer.removeListener('sync:remote-article', handler)
    }
  },
  getPublications: (filters?: { region?: string; language?: string }) =>
    ipcRenderer.invoke('db:get-publications', filters),
  getMonitors: () => ipcRenderer.invoke('db:get-monitors'),
  createMonitor: (input: MonitorCreateInput) => ipcRenderer.invoke('db:create-monitor', input),
  updateMonitor: (id: string, updates: Record<string, unknown>) =>
    ipcRenderer.invoke('db:update-monitor', id, updates),
  deleteMonitor: (id: string) => ipcRenderer.invoke('db:delete-monitor', id),
  getResults: (monitorId: string, options?: ResultFilterOptions) =>
    ipcRenderer.invoke('db:get-results', monitorId, options),
  getSavedCoverage: () => ipcRenderer.invoke('db:get-saved-coverage'),
  getArticle: (id: string) => ipcRenderer.invoke('db:get-article', id),
  getStats: () => ipcRenderer.invoke('db:get-stats'),
  getReportAnalytics: (options?: { days?: number; savedOnly?: boolean }) =>
    ipcRenderer.invoke('db:get-report-analytics', options),
  getWorkspaceClippings: (options?: ResultFilterOptions & { days?: number }) =>
    ipcRenderer.invoke('db:get-workspace-clippings', options),
  getActivity: (resultId: string) => ipcRenderer.invoke('db:get-activity', resultId),
  saveCoverage: (resultId: string, data?: { notes?: string; tags?: string[] }) =>
    ipcRenderer.invoke('db:save-coverage', resultId, data),
  updateSentiment: (resultId: string, sentiment: string) =>
    ipcRenderer.invoke('db:update-sentiment', resultId, sentiment),
  startMonitoring: (monitorId: string) => ipcRenderer.invoke('monitoring:start', monitorId),
  stopMonitoring: (monitorId: string) => ipcRenderer.invoke('monitoring:stop', monitorId),
  getSession: (monitorId: string) => ipcRenderer.invoke('monitoring:session', monitorId),
  openArticleWindow: (articleId: string) => ipcRenderer.invoke('window:open-article', articleId),
  openExternal: (url: string) => ipcRenderer.invoke('app:open-external', url),
  onMonitoringStream: (callback: (event: unknown) => void) => {
    const handler = (_: unknown, event: unknown) => callback(event)
    ipcRenderer.on('monitoring:stream', handler)
    return () => {
      ipcRenderer.removeListener('monitoring:stream', handler)
    }
  }
}

contextBridge.exposeInMainWorld('publshr', api)

export type PublshrAPI = typeof api
