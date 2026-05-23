/** True when running inside a Tauri webview (Rust shell). */
export function isTauriDesktop(): boolean {
  return typeof window !== 'undefined' && '__TAURI_INTERNALS__' in window
}

/** True when running inside legacy Electron preload. */
export function isElectronDesktop(): boolean {
  return typeof window !== 'undefined' && 'spaces' in window && !isTauriDesktop()
}

export type DesktopShell = 'tauri' | 'electron' | 'web'

export function desktopShell(): DesktopShell {
  if (isTauriDesktop()) return 'tauri'
  if (isElectronDesktop()) return 'electron'
  return 'web'
}
