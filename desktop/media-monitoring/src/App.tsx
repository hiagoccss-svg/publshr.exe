import { useEffect, useState } from 'react'
import { HashRouter, Routes, Route } from 'react-router-dom'
import { AuthScreen } from '@/components/auth/AuthScreen'
import { BiometricUnlock } from '@/components/auth/BiometricUnlock'
import { AppShell } from '@/components/layout/AppShell'
import { ArticleDetailView } from '@/views/ArticleDetailView'
import { useMonitoringStore } from '@/store/monitoringStore'
import { Loader2 } from 'lucide-react'

type BootPhase = 'loading' | 'biometric' | 'auth' | 'app'

export default function App() {
  const [phase, setPhase] = useState<BootPhase>('loading')
  const { setAuthInfo, setSyncStatus, setDisplayName } = useMonitoringStore()

  const enterApp = (state: {
    email?: string | null
    workspaceName?: string | null
    displayName?: string | null
    session?: unknown
  }) => {
    setAuthInfo(state.email ?? null, state.workspaceName ?? null)
    setDisplayName(state.displayName ?? null)
    setSyncStatus(state.session ? 'synced' : 'offline')
    setPhase('app')
  }

  useEffect(() => {
    const boot = async () => {
      const bio = await window.publshr.biometricStatus()
      if (bio.enabled && bio.available) {
        setPhase('biometric')
        return
      }
      const state = await window.publshr.restoreSession()
      if (state.session) {
        enterApp(state)
      } else {
        setPhase('auth')
      }
    }
    void boot()

    return window.publshr.onSyncStatus((payload: unknown) => {
      const p = payload as {
        status?: string
        auth?: {
          email?: string
          workspaceName?: string
          displayName?: string
          session?: unknown
        }
      }
      if (p.status) setSyncStatus(p.status as 'synced' | 'syncing' | 'offline' | 'error')
      if (p.auth?.session) {
        setAuthInfo(p.auth.email ?? null, p.auth.workspaceName ?? null)
        setDisplayName(p.auth.displayName ?? null)
      }
    })
  }, [setAuthInfo, setSyncStatus, setDisplayName])

  if (phase === 'loading') {
    return (
      <div className="h-full flex items-center justify-center bg-surface-title text-content-muted gap-2">
        <Loader2 size={18} className="animate-spin" />
        <span className="text-sm">Loading…</span>
      </div>
    )
  }

  if (phase === 'biometric') {
    return (
      <BiometricUnlock
        onUnlocked={() => void window.publshr.biometricUnlock().then(enterApp)}
        onUsePassword={() => setPhase('auth')}
      />
    )
  }

  if (phase === 'auth') {
    return (
      <AuthScreen
        onAuthenticated={() => void window.publshr.getAuthState().then(enterApp)}
      />
    )
  }

  return (
    <HashRouter>
      <Routes>
        <Route path="/" element={<AppShell />} />
        <Route path="/article/:id" element={<ArticleDetailView />} />
      </Routes>
    </HashRouter>
  )
}
