import { ExternalLink } from 'lucide-react'

export default function SetupScreen() {
  return (
    <div className="flex h-screen flex-col items-center justify-center bg-surface px-8">
      <div className="max-w-md text-center">
        <h1 className="font-display text-2xl font-semibold tracking-tight text-ink">
          Publshr Planner
        </h1>
        <p className="mt-3 text-sm leading-relaxed text-ink-secondary">
          Copy <code className="rounded bg-surface-muted px-1.5 py-0.5 text-xs">.env.example</code>{' '}
          to <code className="rounded bg-surface-muted px-1.5 py-0.5 text-xs">.env</code> in{' '}
          <code className="rounded bg-surface-muted px-1.5 py-0.5 text-xs">planner/desktop</code>{' '}
          and set your Supabase URL and publishable key.
        </p>
        <button
          type="button"
          onClick={() =>
            window.planner?.openExternal(
              'https://supabase.com/dashboard/project/lboesdtsrqfvosznjpdy/settings/api'
            )
          }
          className="no-drag mt-6 inline-flex items-center gap-2 rounded-lg bg-ink px-4 py-2 text-sm font-medium text-white transition hover:bg-ink/90"
        >
          Open Supabase settings
          <ExternalLink className="h-3.5 w-3.5" />
        </button>
      </div>
    </div>
  )
}
