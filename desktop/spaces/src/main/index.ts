import { app, BrowserWindow, nativeTheme } from 'electron'
import { electronApp, optimizer } from '@electron-toolkit/utils'
import { SpacesDatabase } from './db/database'
import { registerIpcHandlers } from './ipc/handlers'
import { SupabaseSyncService } from './sync/supabase-sync'
import { createMainWindow } from './windows'
import { initDesktopUpdates } from './updates'

let database: SpacesDatabase | null = null
let syncService: SupabaseSyncService | null = null

function broadcastRefresh(): void {
  for (const win of BrowserWindow.getAllWindows()) {
    if (!win.isDestroyed()) win.webContents.send('spaces:refresh')
  }
}

app.whenReady().then(async () => {
  electronApp.setAppUserModelId('com.publshr.spaces')
  app.on('browser-window-created', (_, window) => {
    optimizer.watchWindowShortcuts(window)
  })

  nativeTheme.themeSource = 'light'
  database = new SpacesDatabase()
  registerIpcHandlers(database)
  initDesktopUpdates()

  syncService = new SupabaseSyncService(database, () => broadcastRefresh())
  await syncService.start()

  createMainWindow()

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createMainWindow()
    }
  })
})

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit()
})

app.on('before-quit', () => {
  syncService?.stop()
  database?.close()
})
