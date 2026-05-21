import type { WorkspaceRole } from '@/types/planner'

const PERMISSIONS = {
  create_planner_item: ['owner', 'admin', 'manager', 'editor'],
  edit_planner_item: ['owner', 'admin', 'manager', 'editor'],
  delete_planner_item: ['owner', 'admin', 'manager'],
  assign_users: ['owner', 'admin', 'manager'],
  request_approval: ['owner', 'admin', 'manager', 'editor'],
  approve_items: ['owner', 'admin', 'manager'],
  view_internal_notes: ['owner', 'admin', 'manager', 'editor'],
  open_editor: ['owner', 'admin', 'manager', 'editor'],
  publish_content: ['owner', 'admin', 'manager'],
  manage_settings: ['owner', 'admin']
} as const

export type Permission = keyof typeof PERMISSIONS

export function hasPermission(role: WorkspaceRole | null, permission: Permission): boolean {
  if (!role) return false
  return (PERMISSIONS[permission] as readonly string[]).includes(role)
}
