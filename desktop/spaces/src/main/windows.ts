import { BrowserWindow, shell } from 'electron'
import { join } from 'path'
import { is } from '@electron-toolkit/utils'
import {
  configureGlassWindow,
  glassWindowOptions
} from '../../../../shared/electron/glass-window'

const openWindows = new Map<string, BrowserWindow>()

function loadUrl(win: BrowserWindow, hash: string): void {
  if (is.dev && process.env['ELECTRON_RENDERER_URL']) {
    win.loadURL(`${process.env['ELECTRON_RENDERER_URL']}#${hash}`)
  } else {
    win.loadFile(join(__dirname, '../renderer/index.html'), { hash })
  }
}

export function createMainWindow(): BrowserWindow {
  const win = new BrowserWindow(
    glassWindowOptions('light', {
      width: 1440,
      height: 900,
      minWidth: 1100,
      minHeight: 680,
      webPreferences: {
        preload: join(__dirname, '../preload/index.js'),
        sandbox: false,
        contextIsolation: true,
        nodeIntegration: false
      }
    })
  )

  configureGlassWindow(win, 'light')
  win.on('ready-to-show', () => win.show())
  win.webContents.setWindowOpenHandler((details) => {
    shell.openExternal(details.url)
    return { action: 'deny' }
  })

  loadUrl(win, '/')
  return win
}

export function createSpaceWindow(spaceId: string): BrowserWindow {
  const key = `space:${spaceId}`
  const existing = openWindows.get(key)
  if (existing && !existing.isDestroyed()) {
    existing.focus()
    return existing
  }

  const win = new BrowserWindow(
    glassWindowOptions('light', {
      width: 1280,
      height: 800,
      minWidth: 900,
      minHeight: 600,
      webPreferences: {
        preload: join(__dirname, '../preload/index.js'),
        sandbox: false,
        contextIsolation: true,
        nodeIntegration: false
      }
    })
  )

  configureGlassWindow(win, 'light')
  win.on('ready-to-show', () => win.show())
  win.on('closed', () => openWindows.delete(key))
  openWindows.set(key, win)
  loadUrl(win, `/space/${spaceId}`)
  return win
}

export function createDocumentWindow(documentId: string, title: string): BrowserWindow {
  const key = `doc:${documentId}`
  const existing = openWindows.get(key)
  if (existing && !existing.isDestroyed()) {
    existing.focus()
    return existing
  }

  const win = new BrowserWindow(
    glassWindowOptions('light', {
      width: 960,
      height: 720,
      minWidth: 640,
      minHeight: 480,
      title,
      webPreferences: {
        preload: join(__dirname, '../preload/index.js'),
        sandbox: false,
        contextIsolation: true,
        nodeIntegration: false
      }
    })
  )

  configureGlassWindow(win, 'light')
  win.on('ready-to-show', () => win.show())
  win.on('closed', () => openWindows.delete(key))
  openWindows.set(key, win)
  loadUrl(win, `/document/${documentId}`)
  return win
}
