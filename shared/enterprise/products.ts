/**
 * Canonical Publshr product names — keep in sync with:
 * - `.github/workflows/deliver-desktop.yml` (product_name)
 * - `*/electron-builder.yml` (productName, appId)
 * - `mac/publshr/.../DesktopCompanionAppLauncher.swift`
 */
export const PUBLSHR_PRODUCTS = {
  ide: {
    id: 'publshr',
    productName: 'Publshr',
    bundleId: 'com.publshr.app',
    channelTag: 'live'
  },
  spaces: {
    id: 'spaces',
    productName: 'Publshr Spaces',
    bundleId: 'com.publshr.spaces',
    channelTag: 'spaces-staging'
  },
  mediaMonitoring: {
    id: 'media-monitoring',
    productName: 'Publshr Media Monitoring',
    bundleId: 'com.publshr.media-monitoring',
    channelTag: 'media-monitoring-staging'
  },
  planner: {
    id: 'planner',
    productName: 'Publshr Planner',
    bundleId: 'com.publshr.planner',
    channelTag: 'planner-staging'
  }
} as const

export type PublshrProductKey = keyof typeof PUBLSHR_PRODUCTS
