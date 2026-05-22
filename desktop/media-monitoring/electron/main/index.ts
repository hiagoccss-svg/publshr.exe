import { app, BrowserWindow, shell, Notification } from 'electron'
import { join } from 'path'
import { initDatabase, closeDatabase } from './db'
import { MonitoringEngine } from './monitoring/engine'
import { registerIpcHandlers } from './ipc/handlers'
import { SyncService } from './supabase/sync-service'
import {
  configureGlassWindow,
  glassWindowOptions
} from '../../../../shared/electron/glass-window'
import { loadRendererWindow } from '../../../../shared/electron/updater/window-loader'
import { getDesktopUpdates, initDesktopUpdates } from './updates'

const bundledRendererIndex = join(__dirname, '../renderer/index.html')
let mainWindow: BrowserWindow | null = null
let engine: MonitoringEngine | null = null
let syncService: SyncService | null = null

function createWindow(): void {
  mainWindow = new BrowserWindow(
    glassWindowOptions('dark', {
      width: 1440,
      height: 900,
      minWidth: 1100,
      minHeight: 700,
      trafficLightPosition: { x: 14, y: 12 },
      webPreferences: {
        preload: join(__dirname, '../preload/index.mjs'),
        contextIsolation: true,
        nodeIntegration: false,
        sandbox: false
      }
    })
  )

  configureGlassWindow(mainWindow, 'dark')

  mainWindow.on('ready-to-show', () => {
    mainWindow?.show()
    mainWindow?.focus()
  })

  mainWindow.webContents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url)
    return { action: 'deny' }
  })

  loadRendererWindow(mainWindow, bundledRendererIndex, getDesktopUpdates()?.appBundle ?? null)
}

app.whenReady().then(() => {
  if (process.platform === 'linux' && !process.env.DISPLAY) {
    process.env.DISPLAY = ':99'
  }

  const db = initDatabase()
  engine = new MonitoringEngine(db)
  syncService = new SyncService(db)
  registerIpcHandlers(engine, syncService)
  initDesktopUpdates()
  void syncService.restoreSession().catch((err) => console.error('Session restore:', err))
  createWindow()

  if (Notification.isSupported()) {
    console.log('Desktop notifications enabled')
  }

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow()
  })
})

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit()
})

app.on('before-quit', () => {
  engine?.removeAllListeners()
  closeDatabase()
})
