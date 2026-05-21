import type { SpacesAPI } from '../../shared/types'

export function getSpacesAPI(): SpacesAPI {
  if (!window.spaces) {
    throw new Error('Spaces API unavailable — run inside Electron')
  }
  return window.spaces
}
