import { app, BrowserWindow, ipcMain, shell, nativeTheme, Notification } from 'electron'
import { join } from 'path'
import { electronApp, optimizer, is } from '@electron-toolkit/utils'
import { initDatabase, closeDatabase } from './database'
import { registerIpcHandlers } from './ipc'
import {
  configureGlassWindow,
  glassWindowOptions
} from '../../../../shared/electron/glass-window'

let mainWindow: BrowserWindow | null = null
const editorWindows = new Map<string, BrowserWindow>()

function createMainWindow(): BrowserWindow {
  const win = new BrowserWindow(
    glassWindowOptions('light', {
      width: 1440,
      height: 900,
      minWidth: 1100,
      minHeight: 700,
      trafficLightPosition: { x: 14, y: 14 },
      webPreferences: {
        preload: join(__dirname, '../preload/index.mjs'),
        sandbox: false,
        contextIsolation: true,
        nodeIntegration: false
      }
    })
  )

  configureGlassWindow(win, 'light')
  win.on('ready-to-show', () => win.show())

  if (is.dev && process.env['ELECTRON_RENDERER_URL']) {
    win.loadURL(process.env['ELECTRON_RENDERER_URL'])
  } else {
    win.loadFile(join(__dirname, '../renderer/index.html'))
  }

  return win
}

function createEditorWindow(documentId: string, plannerItemId: string): BrowserWindow {
  const existing = editorWindows.get(documentId)
  if (existing && !existing.isDestroyed()) {
    existing.focus()
    return existing
  }

  const win = new BrowserWindow(
    glassWindowOptions('light', {
      width: 1200,
      height: 820,
      minWidth: 900,
      minHeight: 600,
      trafficLightPosition: { x: 14, y: 14 },
      webPreferences: {
        preload: join(__dirname, '../preload/index.mjs'),
        sandbox: false,
        contextIsolation: true,
        nodeIntegration: false,
        additionalArguments: [
          `--editor-document-id=${documentId}`,
          `--planner-item-id=${plannerItemId}`
        ]
      }
    })
  )

  configureGlassWindow(win, 'light')

  const hash = `#/editor/${documentId}?plannerItem=${plannerItemId}`
  if (is.dev && process.env['ELECTRON_RENDERER_URL']) {
    win.loadURL(`${process.env['ELECTRON_RENDERER_URL']}${hash}`)
  } else {
    win.loadFile(join(__dirname, '../renderer/index.html'), { hash: `/editor/${documentId}?plannerItem=${plannerItemId}` })
  }

  win.on('ready-to-show', () => win.show())
  win.on('closed', () => editorWindows.delete(documentId))

  editorWindows.set(documentId, win)
  return win
}

app.whenReady().then(() => {
  electronApp.setAppUserModelId('com.publshr.planner')
  initDatabase(app.getPath('userData'))
  registerIpcHandlers({
    getMainWindow: () => mainWindow,
    openEditorWindow: createEditorWindow
  })

  app.on('browser-window-created', (_, window) => {
    optimizer.watchWindowShortcuts(window)
  })

  nativeTheme.themeSource = 'light'
  mainWindow = createMainWindow()

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      mainWindow = createMainWindow()
    }
  })
})

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit()
})

app.on('before-quit', () => {
  closeDatabase()
})

ipcMain.handle('shell:openExternal', (_, url: string) => {
  return shell.openExternal(url)
})

ipcMain.handle('notification:show', (_, payload: { title: string; body: string }) => {
  if (Notification.isSupported()) {
    new Notification({ title: payload.title, body: payload.body }).show()
  }
})
