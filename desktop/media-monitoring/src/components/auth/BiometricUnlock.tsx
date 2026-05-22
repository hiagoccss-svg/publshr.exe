import { useState } from 'react'
import { Fingerprint, Loader2, Radar } from 'lucide-react'
import { shell } from '@/theme/shellTheme'

interface Props {
  onUnlocked: () => void
  onUsePassword: () => void
}

export function BiometricUnlock({ onUnlocked, onUsePassword }: Props) {
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const unlock = async () => {
    setLoading(true)
    setError(null)
    try {
      await window.publshr.biometricUnlock()
      onUnlocked()
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Biometric unlock failed')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div
      className="h-full flex flex-col items-center justify-center px-8"
      style={{ backgroundColor: shell.activityBar }}
    >
      <div className="w-full max-w-[380px] text-center space-y-6">
        <Radar size={32} className="mx-auto text-content-muted" />
        <div>
          <h1 className="text-lg font-medium text-content">Unlock with Touch ID</h1>
          <p className="text-xs text-content-muted mt-2">
            Use your fingerprint to open Media Monitoring without entering your password.
          </p>
        </div>
        <button
          type="button"
          onClick={() => void unlock()}
          disabled={loading}
          className="mx-auto flex flex-col items-center gap-3 p-5 rounded-sm transition-colors hover:bg-surface-highlight/50"
        >
          {loading ? (
            <Loader2 size={48} className="animate-spin text-accent" />
          ) : (
            <Fingerprint size={48} className="text-accent" />
          )}
          <span className="text-sm text-content">{loading ? 'Verifying…' : 'Touch ID'}</span>
        </button>
        {error && <p className="text-xs text-sentiment-negative">{error}</p>}
        <button type="button" className="text-xs text-content-muted hover:text-accent" onClick={onUsePassword}>
          Use password instead
        </button>
      </div>
    </div>
  )
}
