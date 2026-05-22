/// <reference types="vite/client" />

import type { PublshrAPI } from '../electron/preload/index'

declare global {
  interface Window {
    publshr: PublshrAPI
  }
}
