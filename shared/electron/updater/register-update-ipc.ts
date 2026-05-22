import { ipcMain, type BrowserWindow } from 'electron'
import type { DesktopUpdateService } from './desktop-update-service'

export function registerUpdateIpc(
  service: DesktopUpdateService,
  getWindows: () => BrowserWindow[]
): void {
  ipcMain.handle('desktop:getUpdateStatus', () => service.getStatus())
  ipcMain.handle('desktop:checkForUpdates', () => service.runUpdateCycle())
  ipcMain.handle('desktop:restartToUpdate', async () => {
    await service.applyPendingAndRestart(getWindows())
  })
  ipcMain.handle('desktop:rollbackAppBundle', () => {
    service.rollbackAppBundle()
  })
}
