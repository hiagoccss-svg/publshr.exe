import { TopBar } from './TopBar'
import { Sidebar } from './Sidebar'
import { WorkspaceArea } from './WorkspaceArea'
import { ContextPanel } from './ContextPanel'
import { CommandPalette } from '../command/CommandPalette'
import { NewSpaceModal } from '../spaces/NewSpaceModal'
import { SpaceSettingsModal } from '../spaces/SpaceSettingsModal'
import { useSpacesStore } from '../../stores/spaces-store'

export function MainShell(): React.ReactElement {
  const collapsed = useSpacesStore((s) => s.sidebarCollapsed)
  const contextOpen = useSpacesStore((s) => s.contextPanelOpen)

  return (
    <div className="glass-shell flex h-full flex-col">
      <TopBar />
      <div className="flex min-h-0 flex-1">
        <Sidebar collapsed={collapsed} />
        <WorkspaceArea />
        {contextOpen && <ContextPanel />}
      </div>
      <CommandPalette />
      <NewSpaceModal />
      <SpaceSettingsModal />
    </div>
  )
}
