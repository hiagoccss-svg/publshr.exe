import type { BrowserWindow, BrowserWindowConstructorOptions } from 'electron'

export type GlassWindowTheme = 'light' | 'dark'

/**
 * Native translucent window — wallpaper bleeds through on macOS (vibrancy) and
 * Windows 11+ (Mica). Renderer uses `desktop-transparency.css` for shell vs content.
 */
export function glassWindowOptions(
  theme: GlassWindowTheme,
  overrides: BrowserWindowConstructorOptions = {}
): BrowserWindowConstructorOptions {
  const platform = process.platform

  const base: BrowserWindowConstructorOptions = {
    show: false,
    hasShadow: true,
    ...overrides
  }

  if (platform === 'darwin') {
    return {
      ...base,
      transparent: true,
      backgroundColor: '#00000000',
      vibrancy: 'under-window',
      titleBarStyle: overrides.titleBarStyle ?? 'hiddenInset'
    }
  }

  if (platform === 'win32') {
    return {
      ...base,
      backgroundColor: '#00000000',
      backgroundMaterial: 'mica',
      titleBarStyle: overrides.titleBarStyle ?? 'default'
    }
  }

  const fallbackBg = theme === 'dark' ? '#1e1e1ef0' : '#f3f2eff0'
  return {
    ...base,
    backgroundColor: fallbackBg,
    titleBarStyle: overrides.titleBarStyle ?? 'default'
  }
}

/** Re-apply platform glass after load (Swift MainWindowChrome-style retries). */
export function configureGlassWindow(win: BrowserWindow, theme: GlassWindowTheme): void {
  if (process.platform === 'darwin') {
    win.setBackgroundColor('#00000000')
    if (typeof win.setVibrancy === 'function') {
      win.setVibrancy('under-window')
    }
  } else if (process.platform === 'win32') {
    win.setBackgroundColor('#00000000')
    if (typeof win.setBackgroundMaterial === 'function') {
      win.setBackgroundMaterial('mica')
    }
  } else {
    win.setBackgroundColor(theme === 'dark' ? '#1e1e1ef0' : '#f3f2eff0')
  }

  win.webContents.once('did-finish-load', () => {
    void win.webContents.executeJavaScript(
      `document.documentElement.dataset.glassTheme = ${JSON.stringify(theme)};`
    )
  })
}
