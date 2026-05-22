import { useEffect, useState } from 'react'
import { Fingerprint } from 'lucide-react'
import { cursor } from '@/theme/cursor'

export function SettingsPanel() {
  const [bio, setBio] = useState<{ available: boolean; enabled: boolean; platform: string } | null>(null)
  const [message, setMessage] = useState<string | null>(null)

  useEffect(() => {
    window.publshr.biometricStatus().then(setBio)
  }, [])

  return (
    <div className="flex-1 overflow-y-auto p-6 max-w-lg">
      <h1 className="text-sm font-medium text-content mb-4">Settings</h1>

      <section
        className="rounded-lg border p-4 space-y-3"
        style={{ borderColor: cursor.border, backgroundColor: cursor.editor }}
      >
        <div className="flex items-center gap-2">
          <Fingerprint size={18} className="text-accent" />
          <h2 className="text-sm font-medium text-content">Biometric unlock</h2>
        </div>
        {!bio?.available && (
          <p className="text-xs text-content-muted">
            Touch ID is available on macOS with secure enclave support. On {bio?.platform ?? 'this platform'}, use password sign-in.
          </p>
        )}
        {bio?.available && (
          <>
            <p className="text-xs text-content-muted">
              After signing in with your password, enable Touch ID to unlock Media Monitoring without re-entering credentials.
            </p>
            {bio.enabled ? (
              <button
                type="button"
                className="text-xs text-sentiment-negative hover:underline"
                onClick={async () => {
                  await window.publshr.biometricDisable()
                  setBio(await window.publshr.biometricStatus())
                  setMessage('Biometric unlock disabled.')
                }}
              >
                Disable Touch ID
              </button>
            ) : (
              <button
                type="button"
                className="text-xs px-3 py-1.5 rounded text-white"
                style={{ backgroundColor: cursor.button }}
                onClick={async () => {
                  try {
                    await window.publshr.biometricEnable()
                    setBio(await window.publshr.biometricStatus())
                    setMessage('Touch ID enabled for this device.')
                  } catch (err) {
                    setMessage(err instanceof Error ? err.message : 'Failed to enable')
                  }
                }}
              >
                Enable Touch ID
              </button>
            )}
          </>
        )}
        {message && <p className="text-xs text-content-muted">{message}</p>}
      </section>

      <section className="mt-6">
        <button
          type="button"
          className="text-xs text-content-muted hover:text-sentiment-negative"
          onClick={async () => {
            await window.publshr.signOut()
            window.location.reload()
          }}
        >
          Sign out
        </button>
      </section>
    </div>
  )
}
