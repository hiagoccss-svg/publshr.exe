/// <reference types="vite/client" />

import type { SpacesAPI } from '../shared/types'

declare global {
  interface Window {
    spaces: SpacesAPI
  }
}

export {}
