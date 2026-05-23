import { TopBar } from './TopBar'
import { ShellColumnTitlebar } from './ShellColumnTitlebar'
import { EnterpriseNavRail } from './EnterpriseNavRail'
import { EnterpriseContextSidebar } from './EnterpriseContextSidebar'
import { WorkspaceArea } from './WorkspaceArea'
import { ContextPanel } from './ContextPanel'
import { CommandPalette } from '../command/CommandPalette'
import { NotificationsPanel } from './NotificationsPanel'
import { NewSpaceModal } from '../spaces/NewSpaceModal'
import { SpaceSettingsModal } from '../spaces/SpaceSettingsModal'
import { useSpacesStore } from '../../stores/spaces-store'

export interface MainShellProps {
  /** Hides duplicate title chrome when hosted inside enterprise DesktopShell. */
  embedded?: boolean
  onSignOut?: () => void
}

export function MainShell({ embedded = false, onSignOut }: MainShellProps = {}): React.ReactElement {
  const contextOpen = useSpacesStore((s) => s.contextPanelOpen)

  return (
    <div className={embedded ? 'flex h-full min-h-0 flex-1 flex-col' : 'glass-shell flex h-full flex-col'}>
      {embedded ? (
        <ShellColumnTitlebar embedded onSignOut={onSignOut} />
      ) : (
        <TopBar onSignOut={onSignOut} />
      )}
      <div className="flex min-h-0 flex-1">
        <EnterpriseNavRail />
        <EnterpriseContextSidebar />
        <WorkspaceArea />
        {contextOpen && <ContextPanel />}
      </div>
      <CommandPalette />
      <NotificationsPanel />
      <NewSpaceModal />
      <SpaceSettingsModal />
    </div>
  )
}
