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
    <div className="flex-1 overflow-y-auto">
      <div className="px-4 py-3 border-b border-border">
        <h1 className="text-[13px] font-medium text-content">Settings</h1>
      </div>

      <section className="px-4 py-4 border-b border-border max-w-xl">
        <div className="flex items-center gap-2 mb-3">
          <Fingerprint size={16} className="text-accent" strokeWidth={1.5} />
          <h2 className="text-[13px] font-medium text-content">Biometric unlock</h2>
        </div>
        {!bio?.available && (
          <p className="text-[11px] text-content-muted leading-relaxed">
            Touch ID is available on macOS with secure enclave support. On {bio?.platform ?? 'this platform'}, use password sign-in.
          </p>
        )}
        {bio?.available && (
          <>
            <p className="text-[11px] text-content-muted leading-relaxed">
              After signing in with your password, enable Touch ID to unlock Media Monitoring without re-entering credentials.
            </p>
            {bio.enabled ? (
              <button
                type="button"
                className="mt-3 text-[11px] text-sentiment-negative hover:underline"
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
                className="mt-3 text-[11px] px-3 py-1.5 rounded-sm text-white"
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
        {message && <p className="text-[11px] text-content-muted mt-2">{message}</p>}
      </section>

      <section className="px-4 py-4">
        <button
          type="button"
          className="text-[11px] text-content-muted hover:text-sentiment-negative"
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
