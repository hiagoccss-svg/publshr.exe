import { useAuthStore } from '@/stores/authStore'

/** Drag region for overlay title bar (macOS traffic lights remain native). */
export function TitleBar() {
  const { snapshot, signOut } = useAuthStore()

  return (
    <header
      data-tauri-drag-region
      className="glass-toolbar flex h-11 shrink-0 items-center justify-between border-b border-black/5 px-16"
    >
      <span className="text-xs font-medium text-[var(--lib-ink-muted)]">Publshr</span>
      {snapshot?.user ? (
        <button
          type="button"
          onClick={() => void signOut()}
          className="text-xs text-[var(--lib-ink-muted)] hover:text-[var(--lib-ink)]"
        >
          Sign out
        </button>
      ) : null}
    </header>
  )
}
