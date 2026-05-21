import { useEffect, useCallback } from 'react'
import { useMonitoringStore } from '@/store/monitoringStore'
import type { MonitorProfile, MonitorResult } from '@/types'

export function useLoadResults() {
  const { setResults, filters, searchQuery } = useMonitoringStore()

  return useCallback(
    async (monitorId: string) => {
      const results = (await window.publshr.getResults(monitorId, {
        sentiment: filters.sentiment || undefined,
        savedOnly: filters.savedOnly,
        search: searchQuery || undefined,
        sort: filters.sort
      })) as MonitorResult[]
      setResults(results)
    },
    [filters, searchQuery, setResults]
  )
}

export function useMonitoringBootstrap() {
  const {
    setMonitors,
    setActiveMonitor,
    handleStreamEvent,
    setSyncStatus,
    setAuthInfo,
    activeMonitorId
  } = useMonitoringStore()
  const loadResults = useLoadResults()

  const loadMonitors = useCallback(async () => {
    const monitors = (await window.publshr.getMonitors()) as MonitorProfile[]
    setMonitors(monitors)
    const active = useMonitoringStore.getState().activeMonitorId
    const target = active && monitors.some((m) => m.id === active) ? active : monitors[0]?.id
    if (target) {
      setActiveMonitor(target)
      await loadResults(target)
    }
  }, [setMonitors, setActiveMonitor, loadResults])

  useEffect(() => {
    void loadMonitors()

    window.publshr.restoreSession().then((state: {
      email?: string
      workspaceName?: string
      displayName?: string
      session?: unknown
    }) => {
      setAuthInfo(state.email ?? null, state.workspaceName ?? null)
      useMonitoringStore.getState().setDisplayName(state.displayName ?? null)
      if (state.session) setSyncStatus('synced')
    })

    const unsubStream = window.publshr.onMonitoringStream((event) => {
      handleStreamEvent(event as Parameters<typeof handleStreamEvent>[0])
    })

    const unsubSync = window.publshr.onSyncStatus((payload: unknown) => {
      const p = payload as { status?: string; auth?: { email?: string; workspaceName?: string } }
      if (p.status) setSyncStatus(p.status as 'synced' | 'syncing' | 'offline' | 'error')
      if (p.auth) setAuthInfo(p.auth.email ?? null, p.auth.workspaceName ?? null)
    })

    const unsubRemote = window.publshr.onRemoteArticle(() => {
      const id = useMonitoringStore.getState().activeMonitorId
      if (id) void loadResults(id)
    })

    return () => {
      unsubStream()
      unsubSync()
      unsubRemote()
    }
  }, [loadMonitors, handleStreamEvent, setSyncStatus, setAuthInfo, loadResults])

  useEffect(() => {
    if (activeMonitorId) void loadResults(activeMonitorId)
  }, [activeMonitorId, loadResults])

  return { loadMonitors, loadResults }
}

export function useActiveMonitor() {
  const { monitors, activeMonitorId, setMonitoring } = useMonitoringStore()
  const loadResults = useLoadResults()

  const activeMonitor = monitors.find((m) => m.id === activeMonitorId) ?? null

  const selectMonitor = useCallback(
    async (id: string) => {
      useMonitoringStore.getState().setActiveMonitor(id)
      await loadResults(id)
      const session = await window.publshr.getSession(id)
      setMonitoring(session?.status === 'running')
    },
    [loadResults, setMonitoring]
  )

  const startLive = useCallback(async () => {
    if (!activeMonitorId) return
    setMonitoring(true)
    useMonitoringStore.getState().setSyncStatus('syncing')
    await window.publshr.startMonitoring(activeMonitorId)
  }, [activeMonitorId, setMonitoring])

  const stopLive = useCallback(async () => {
    if (!activeMonitorId) return
    await window.publshr.stopMonitoring(activeMonitorId)
    setMonitoring(false)
    useMonitoringStore.getState().setSyncStatus('synced')
  }, [activeMonitorId, setMonitoring])

  return { activeMonitor, selectMonitor, startLive, stopLive }
}
