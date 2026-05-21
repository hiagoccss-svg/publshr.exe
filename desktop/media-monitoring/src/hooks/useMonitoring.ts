import { useEffect, useCallback } from 'react'
import { useMonitoringStore } from '@/store/monitoringStore'
import type { MonitorProfile, MonitorResult } from '@/types'

export function useMonitoringBootstrap() {
  const { setMonitors, setActiveMonitor, setResults, handleStreamEvent } = useMonitoringStore()

  const loadMonitors = useCallback(async () => {
    const monitors = (await window.publshr.getMonitors()) as MonitorProfile[]
    setMonitors(monitors)
    if (monitors.length && !useMonitoringStore.getState().activeMonitorId) {
      setActiveMonitor(monitors[0].id)
      const results = (await window.publshr.getResults(monitors[0].id)) as MonitorResult[]
      setResults(results)
      useMonitoringStore.setState({ streamCount: results.length })
    }
  }, [setMonitors, setActiveMonitor, setResults])

  useEffect(() => {
    loadMonitors()
    const unsub = window.publshr.onMonitoringStream((event) => {
      handleStreamEvent(event as Parameters<typeof handleStreamEvent>[0])
    })
    return () => {
      unsub()
    }
  }, [loadMonitors, handleStreamEvent])

  return { loadMonitors }
}

export function useActiveMonitor() {
  const { monitors, activeMonitorId, setResults, setMonitoring, setStreamCount } = useMonitoringStore()

  const activeMonitor = monitors.find((m) => m.id === activeMonitorId) ?? null

  const selectMonitor = useCallback(
    async (id: string) => {
      useMonitoringStore.getState().setActiveMonitor(id)
      const results = (await window.publshr.getResults(id)) as MonitorResult[]
      setResults(results)
      setStreamCount(results.length)
      const session = await window.publshr.getSession(id)
      setMonitoring(session?.status === 'running')
    },
    [setResults, setMonitoring, setStreamCount]
  )

  const startLive = useCallback(async () => {
    if (!activeMonitorId) return
    setMonitoring(true)
    useMonitoringStore.setState({ syncStatus: 'syncing' })
    await window.publshr.startMonitoring(activeMonitorId)
  }, [activeMonitorId, setMonitoring])

  const stopLive = useCallback(async () => {
    if (!activeMonitorId) return
    await window.publshr.stopMonitoring(activeMonitorId)
    setMonitoring(false)
    useMonitoringStore.setState({ syncStatus: 'synced' })
  }, [activeMonitorId, setMonitoring])

  return { activeMonitor, selectMonitor, startLive, stopLive }
}
