import { useState } from 'react'
import { Loader2, Radar } from 'lucide-react'
import { shell } from '@/theme/shellTheme'

type Screen = 'signIn' | 'signUp' | 'confirmEmail'

export function AuthScreen({ onAuthenticated }: { onAuthenticated: () => void }) {
  const [screen, setScreen] = useState<Screen>('signIn')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [displayName, setDisplayName] = useState('')
  const [otp, setOtp] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [info, setInfo] = useState<string | null>(null)

  const clearMessages = () => {
    setError(null)
    setInfo(null)
  }

  const validate = (requireName = false) => {
    if (!email.trim().includes('@')) {
      setError('Enter a valid email address.')
      return false
    }
    if (password.length < 8) {
      setError('Password must be at least 8 characters.')
      return false
    }
    if (requireName && !displayName.trim()) {
      setError('Enter your name to create an account.')
      return false
    }
    return true
  }

  const handleSignIn = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!validate()) return
    setLoading(true)
    clearMessages()
    try {
      await window.publshr.signIn(email.trim(), password)
      onAuthenticated()
    } catch (err) {
      setError(friendlyError(err))
    } finally {
      setLoading(false)
    }
  }

  const handleSignUp = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!validate(true)) return
    setLoading(true)
    clearMessages()
    try {
      const result = await window.publshr.signUp(email.trim(), password, displayName.trim())
      if (result.needsConfirmation) {
        setInfo('Check your email for a 6-digit confirmation code.')
        setScreen('confirmEmail')
      } else {
        onAuthenticated()
      }
    } catch (err) {
      setError(friendlyError(err))
    } finally {
      setLoading(false)
    }
  }

  const handleVerify = async (e: React.FormEvent) => {
    e.preventDefault()
    if (otp.trim().length < 6) {
      setError('Enter the 6-digit code from your email.')
      return
    }
    setLoading(true)
    clearMessages()
    try {
      await window.publshr.verifyOtp(email.trim(), otp.trim())
      onAuthenticated()
    } catch (err) {
      setError(friendlyError(err))
    } finally {
      setLoading(false)
    }
  }

  return (
    <div
      className="h-full flex flex-col items-center justify-center px-8"
      style={{ backgroundColor: shell.activityBar }}
    >
      <div className="w-full max-w-[420px] space-y-6">
        <header className="text-center space-y-2">
          <Radar size={36} className="mx-auto text-content" strokeWidth={1.5} />
          <h1 className="text-[22px] font-semibold text-content">Publshr</h1>
          <p className="text-[13px] text-content-muted">Media Monitoring — sign in to continue</p>
        </header>

        <div
          className="rounded-sm p-5 space-y-4 border"
          style={{ backgroundColor: shell.authCard, borderColor: shell.border }}
        >
          {screen !== 'confirmEmail' && (
            <div
              className="flex rounded-sm overflow-hidden"
              style={{ backgroundColor: shell.workspace }}
            >
              <Tab active={screen === 'signIn'} onClick={() => { setScreen('signIn'); clearMessages() }}>
                Sign in
              </Tab>
              <Tab active={screen === 'signUp'} onClick={() => { setScreen('signUp'); clearMessages() }}>
                Create account
              </Tab>
            </div>
          )}

          {screen === 'signIn' && (
            <form onSubmit={handleSignIn} className="space-y-3">
              <Field label="Email" value={email} onChange={setEmail} type="email" />
              <Field label="Password" value={password} onChange={setPassword} type="password" />
              <PrimaryButton loading={loading}>Sign in</PrimaryButton>
            </form>
          )}

          {screen === 'signUp' && (
            <form onSubmit={handleSignUp} className="space-y-3">
              <Field label="Name" value={displayName} onChange={setDisplayName} />
              <Field label="Email" value={email} onChange={setEmail} type="email" />
              <Field label="Password" value={password} onChange={setPassword} type="password" />
              <p className="text-[11px] text-content-dim">At least 8 characters</p>
              <PrimaryButton loading={loading}>Create account</PrimaryButton>
            </form>
          )}

          {screen === 'confirmEmail' && (
            <form onSubmit={handleVerify} className="space-y-3">
              <p className="text-sm font-medium text-content">Confirm your email</p>
              <p className="text-xs text-content-muted">
                Enter the 6-digit code sent to {email}
              </p>
              <Field label="Code" value={otp} onChange={setOtp} />
              <PrimaryButton loading={loading}>Verify email</PrimaryButton>
              <div className="flex justify-between text-xs">
                <button
                  type="button"
                  className="text-accent hover:underline"
                  onClick={async () => {
                    setLoading(true)
                    try {
                      await window.publshr.resendOtp(email.trim())
                      setInfo('Confirmation email sent again.')
                    } catch (err) {
                      setError(friendlyError(err))
                    } finally {
                      setLoading(false)
                    }
                  }}
                >
                  Resend code
                </button>
                <button
                  type="button"
                  className="text-content-muted hover:text-content"
                  onClick={() => { setScreen('signIn'); setOtp(''); clearMessages() }}
                >
                  Back to sign in
                </button>
              </div>
            </form>
          )}

          {error && <p className="text-xs" style={{ color: shell.error }}>{error}</p>}
          {info && <p className="text-xs" style={{ color: shell.success }}>{info}</p>}
        </div>
      </div>
    </div>
  )
}

function Tab({
  children,
  active,
  onClick
}: {
  children: React.ReactNode
  active: boolean
  onClick: () => void
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="flex-1 py-2 text-[13px] font-medium transition-colors"
      style={{
        color: active ? shell.foreground : shell.foregroundMuted,
        backgroundColor: active ? shell.sideBar : 'transparent'
      }}
    >
      {children}
    </button>
  )
}

function Field({
  label,
  value,
  onChange,
  type = 'text'
}: {
  label: string
  value: string
  onChange: (v: string) => void
  type?: string
}) {
  return (
    <label className="block">
      <span className="text-[12px] text-content-muted">{label}</span>
      <input
        type={type}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="mt-1.5 w-full text-[13px] text-content px-2.5 py-2 rounded-sm border outline-none focus:border-accent/60"
        style={{ backgroundColor: shell.input, borderColor: shell.borderSubtle }}
      />
    </label>
  )
}

function PrimaryButton({
  children,
  loading
}: {
  children: React.ReactNode
  loading?: boolean
}) {
  return (
    <button
      type="submit"
      disabled={loading}
      className="w-full flex items-center justify-center gap-2 py-2 rounded-sm text-[13px] font-medium text-white disabled:opacity-70"
      style={{ backgroundColor: shell.button }}
    >
      {loading && <Loader2 size={14} className="animate-spin" />}
      {children}
    </button>
  )
}

function friendlyError(err: unknown): string {
  const text = err instanceof Error ? err.message : String(err)
  if (text.toLowerCase().includes('email not confirmed')) return 'Confirm your email with the 6-digit code we sent you.'
  if (text.toLowerCase().includes('invalid login') || text.toLowerCase().includes('invalid credentials')) {
    return 'Incorrect email or password.'
  }
  if (text.toLowerCase().includes('already registered') || text.toLowerCase().includes('already exists')) {
    return 'An account with this email already exists. Sign in instead.'
  }
  return text
}
