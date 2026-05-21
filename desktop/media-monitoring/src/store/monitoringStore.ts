import { create } from 'zustand'
import type { MonitorProfile, MonitorResult, SidebarSection, TopBarMode, StreamEvent } from '@/types'

export interface FeedFilters {
  sentiment: string
  sort: string
  savedOnly: boolean
}

interface MonitoringState {
  section: SidebarSection
  sidebarCollapsed: boolean
  topBarMode: TopBarMode
  monitors: MonitorProfile[]
  activeMonitorId: string | null
  results: MonitorResult[]
  selectedArticleId: string | null
  isMonitoring: boolean
  streamCount: number
  showCreatePanel: boolean
  searchQuery: string
  filters: FeedFilters
  syncStatus: 'synced' | 'syncing' | 'offline' | 'error'
  workspaceName: string | null
  userEmail: string | null
  setSection: (s: SidebarSection) => void
  toggleSidebar: () => void
  setTopBarMode: (m: TopBarMode) => void
  setMonitors: (m: MonitorProfile[]) => void
  setActiveMonitor: (id: string | null) => void
  setResults: (r: MonitorResult[]) => void
  prependResult: (r: MonitorResult) => void
  setSelectedArticle: (id: string | null) => void
  setMonitoring: (v: boolean) => void
  setStreamCount: (n: number) => void
  setShowCreatePanel: (v: boolean) => void
  setSearchQuery: (q: string) => void
  setFilters: (f: Partial<FeedFilters>) => void
  setSyncStatus: (s: MonitoringState['syncStatus']) => void
  setAuthInfo: (email: string | null, workspace: string | null) => void
  handleStreamEvent: (e: StreamEvent) => void
}

export const useMonitoringStore = create<MonitoringState>((set, get) => ({
  section: 'monitoring',
  sidebarCollapsed: false,
  topBarMode: 'live',
  monitors: [],
  activeMonitorId: null,
  results: [],
  selectedArticleId: null,
  isMonitoring: false,
  streamCount: 0,
  showCreatePanel: false,
  searchQuery: '',
  filters: { sentiment: '', sort: 'newest', savedOnly: false },
  syncStatus: 'offline',
  workspaceName: null,
  userEmail: null,

  setSection: (section) => set({ section, topBarMode: section === 'monitoring' ? 'live' : 'default' }),
  toggleSidebar: () => set((s) => ({ sidebarCollapsed: !s.sidebarCollapsed })),
  setTopBarMode: (topBarMode) => set({ topBarMode }),
  setMonitors: (monitors) => set({ monitors }),
  setActiveMonitor: (activeMonitorId) => set({ activeMonitorId, results: [], streamCount: 0 }),
  setResults: (results) => set({ results, streamCount: results.length }),
  prependResult: (r) =>
    set((s) => ({
      results: [r, ...s.results.filter((x) => x.id !== r.id)],
      streamCount: s.streamCount + 1
    })),
  setSelectedArticle: (selectedArticleId) => set({ selectedArticleId }),
  setMonitoring: (isMonitoring) => set({ isMonitoring, topBarMode: 'live' }),
  setStreamCount: (streamCount) => set({ streamCount }),
  setShowCreatePanel: (showCreatePanel) => set({ showCreatePanel }),
  setSearchQuery: (searchQuery) => set({ searchQuery }),
  setFilters: (f) => set((s) => ({ filters: { ...s.filters, ...f } })),
  setSyncStatus: (syncStatus) => set({ syncStatus }),
  setAuthInfo: (userEmail, workspaceName) => set({ userEmail, workspaceName }),
  handleStreamEvent: (e) => {
    const { activeMonitorId } = get()
    if (e.monitorId !== activeMonitorId) return
    if (e.type === 'article' && e.article) {
      get().prependResult(e.article)
      set({ streamCount: e.totalFound ?? get().streamCount + 1, isMonitoring: true })
    }
    if (e.type === 'complete') {
      set({ isMonitoring: false, syncStatus: 'synced' })
    }
    if (e.type === 'status') {
      set({ isMonitoring: e.status === 'running' })
    }
  }
}))
