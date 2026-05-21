export function DocumentWindow({ documentId }: { documentId: string }): React.ReactElement {
  return (
    <div className="flex h-full flex-col bg-white">
      <header className="drag-region border-b border-surface-border px-6 py-4">
        <p className="no-drag text-xs text-ink-muted">Document · {documentId.slice(0, 8)}</p>
        <h1 className="no-drag mt-1 text-lg font-semibold text-ink">Untitled document</h1>
      </header>
      <div className="no-drag flex-1 overflow-auto p-6">
        <p className="text-sm text-ink-secondary">
          Native document editor opens here — aligned with the Publshr Editor system (Phase 2).
        </p>
        <textarea
          className="mt-4 min-h-[400px] w-full resize-none rounded-lg border border-surface-border p-4 text-sm leading-relaxed text-ink focus:outline-none focus:ring-2 focus:ring-accent/10"
          placeholder="Start writing…"
        />
      </div>
    </div>
  )
}
