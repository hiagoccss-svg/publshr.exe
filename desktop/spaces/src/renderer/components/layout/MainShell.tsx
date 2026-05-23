import { TopBar } from './TopBar'
import { EnterpriseNavRail } from './EnterpriseNavRail'
import { EnterpriseContextSidebar } from './EnterpriseContextSidebar'
import { WorkspaceArea } from './WorkspaceArea'
import { ContextPanel } from './ContextPanel'
import { CommandPalette } from '../command/CommandPalette'
import { NewSpaceModal } from '../spaces/NewSpaceModal'
import { SpaceSettingsModal } from '../spaces/SpaceSettingsModal'
import { useSpacesStore } from '../../stores/spaces-store'

export function MainShell(): React.ReactElement {
  const contextOpen = useSpacesStore((s) => s.contextPanelOpen)

  return (
    <div className="glass-shell flex h-full flex-col">
      <TopBar />
      <div className="flex min-h-0 flex-1">
        <EnterpriseNavRail />
        <EnterpriseContextSidebar />
        <WorkspaceArea />
        {contextOpen && <ContextPanel />}
      </div>
      <CommandPalette />
      <NewSpaceModal />
      <SpaceSettingsModal />
    </div>
  )
}
