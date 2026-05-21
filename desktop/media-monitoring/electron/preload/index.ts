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

const api = {
  getPublications: (filters?: { region?: string; language?: string }) =>
    ipcRenderer.invoke('db:get-publications', filters),
  getMonitors: () => ipcRenderer.invoke('db:get-monitors'),
  createMonitor: (input: MonitorCreateInput) => ipcRenderer.invoke('db:create-monitor', input),
  updateMonitor: (id: string, updates: Record<string, unknown>) =>
    ipcRenderer.invoke('db:update-monitor', id, updates),
  deleteMonitor: (id: string) => ipcRenderer.invoke('db:delete-monitor', id),
  getResults: (monitorId: string, options?: { limit?: number; offset?: number }) =>
    ipcRenderer.invoke('db:get-results', monitorId, options),
  saveCoverage: (resultId: string, data?: { notes?: string; tags?: string[] }) =>
    ipcRenderer.invoke('db:save-coverage', resultId, data),
  startMonitoring: (monitorId: string) => ipcRenderer.invoke('monitoring:start', monitorId),
  stopMonitoring: (monitorId: string) => ipcRenderer.invoke('monitoring:stop', monitorId),
  getSession: (monitorId: string) => ipcRenderer.invoke('monitoring:session', monitorId),
  openArticleWindow: (articleId: string) => ipcRenderer.invoke('window:open-article', articleId),
  onMonitoringStream: (callback: (event: unknown) => void) => {
    const handler = (_: unknown, event: unknown) => callback(event)
    ipcRenderer.on('monitoring:stream', handler)
    return () => ipcRenderer.removeListener('monitoring:stream', handler)
  }
}

contextBridge.exposeInMainWorld('publshr', api)

export type PublshrAPI = typeof api
