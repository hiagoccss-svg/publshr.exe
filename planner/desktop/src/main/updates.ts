import { app, BrowserWindow } from 'electron'
import { DesktopUpdateService } from '../../../../shared/electron/updater/desktop-update-service'
import { registerUpdateIpc } from '../../../../shared/electron/updater/register-update-ipc'

let updateService: DesktopUpdateService | null = null

export function initDesktopUpdates(): DesktopUpdateService {
  if (!updateService) {
    updateService = new DesktopUpdateService(app, 'planner')
    registerUpdateIpc(updateService, () => BrowserWindow.getAllWindows())
    updateService.start({ checkOnStart: true })
  }
  return updateService
}

export function getDesktopUpdates(): DesktopUpdateService | null {
  return updateService
}
