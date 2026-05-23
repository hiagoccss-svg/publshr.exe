import { bindTauriSpacesRefresh, resolveSpacesAPI } from './tauri-api'

export function getSpacesAPI() {
  return resolveSpacesAPI()
}

/** Wire refresh events when running under Tauri. */
export function initSpacesPlatform(): void {
  bindTauriSpacesRefresh(() => {
    window.dispatchEvent(new CustomEvent('spaces:refresh'))
  })
}
