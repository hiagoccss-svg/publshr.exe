import { app, BrowserWindow, shell } from 'electron'
import { join } from 'path'
import { initDatabase, closeDatabase } from './db'
import { MonitoringEngine } from './monitoring/engine'
import { registerIpcHandlers } from './ipc/handlers'
import { SyncService } from './supabase/sync-service'

const isDev = !app.isPackaged
let mainWindow: BrowserWindow | null = null
let engine: MonitoringEngine | null = null
let syncService: SyncService | null = null

function createWindow(): void {
  mainWindow = new BrowserWindow({
    width: 1440,
    height: 900,
    minWidth: 1100,
    minHeight: 700,
    show: false,
    backgroundColor: '#1E1E1E',
    titleBarStyle: process.platform === 'darwin' ? 'hiddenInset' : 'default',
    trafficLightPosition: { x: 14, y: 12 },
    webPreferences: {
      preload: join(__dirname, '../preload/index.mjs'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false
    }
  })

  mainWindow.on('ready-to-show', () => {
    mainWindow?.show()
  })

  mainWindow.webContents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url)
    return { action: 'deny' }
  })

  if (isDev && process.env.ELECTRON_RENDERER_URL) {
    mainWindow.loadURL(process.env.ELECTRON_RENDERER_URL)
  } else {
    mainWindow.loadFile(join(__dirname, '../renderer/index.html'))
  }
}

app.whenReady().then(() => {
  const db = initDatabase()
  engine = new MonitoringEngine(db)
  syncService = new SyncService(db)
  registerIpcHandlers(engine, syncService)
  void syncService.restoreSession()
  createWindow()

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
