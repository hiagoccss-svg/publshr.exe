export type PlannerItemType =
  | 'campaign'
  | 'press_release'
  | 'editorial_article'
  | 'media_pitch'
  | 'client_announcement'
  | 'social_content'
  | 'event_communication'
  | 'report'
  | 'coverage_follow_up'
  | 'approval_request'
  | 'internal_task'

export type PlannerItemStatus =
  | 'idea'
  | 'drafting'
  | 'internal_review'
  | 'client_approval'
  | 'scheduled'
  | 'published'
  | 'coverage_tracking'
  | 'reporting'
  | 'completed'

export type PlannerView =
  | 'timeline'
  | 'calendar'
  | 'board'
  | 'editorial_grid'
  | 'approvals'
  | 'workload'
  | 'client'

export type Priority = 'low' | 'medium' | 'high' | 'urgent'

export type WorkspaceRole = 'owner' | 'admin' | 'manager' | 'editor' | 'viewer' | 'client'

export type ApprovalStage =
  | 'draft_review'
  | 'internal_review'
  | 'manager_approval'
  | 'client_approval'
  | 'legal_approval'
  | 'final_approval'

export type ApprovalStatus =
  | 'not_requested'
  | 'requested'
  | 'changes_requested'
  | 'approved'
  | 'rejected'
  | 'overdue'

export type CommentVisibility = 'internal' | 'client'

export interface Workspace {
  id: string
  name: string
  logo_url: string | null
  created_at: string
}

export interface WorkspaceMember {
  id: string
  workspace_id: string
  user_id: string
  role: WorkspaceRole
  status: string
}

export interface Client {
  id: string
  workspace_id: string
  name: string
  logo_url: string | null
  contact_email: string | null
}

export interface Project {
  id: string
  workspace_id: string
  client_id: string | null
  name: string
  description: string | null
  status: string
}

export interface Campaign {
  id: string
  workspace_id: string
  project_id: string | null
  client_id: string | null
  name: string
  description: string | null
  start_date: string | null
  end_date: string | null
  status: string
}

export interface PlannerItem {
  id: string
  workspace_id: string
  project_id: string | null
  client_id: string | null
  campaign_id: string | null
  title: string
  type: PlannerItemType
  status: PlannerItemStatus
  priority: Priority
  owner_id: string | null
  description: string | null
  start_date: string | null
  due_date: string | null
  publish_date: string | null
  tags: string[]
  created_by: string | null
  created_at: string
  updated_at: string
  editor_document_id?: string | null
  _syncStatus?: 'synced' | 'pending' | 'conflict'
}

export interface PlannerItemAssignee {
  id: string
  planner_item_id: string
  user_id: string
}

export interface EditorDocument {
  id: string
  workspace_id: string
  planner_item_id: string | null
  title: string
  subtitle: string | null
  content_json: Record<string, unknown> | null
  content_html: string | null
  status: string
  created_by: string | null
  updated_by: string | null
  created_at: string
  updated_at: string
}

export interface Approval {
  id: string
  workspace_id: string
  planner_item_id: string
  editor_document_id: string | null
  stage: ApprovalStage
  approver_id: string | null
  status: ApprovalStatus
  requested_by: string | null
  requested_at: string | null
  responded_at: string | null
  comments: string | null
  document_version_id: string | null
}

export interface Comment {
  id: string
  workspace_id: string
  planner_item_id: string | null
  editor_document_id: string | null
  user_id: string
  body: string
  visibility: CommentVisibility
  created_at: string
}

export interface Attachment {
  id: string
  workspace_id: string
  planner_item_id: string | null
  editor_document_id: string | null
  file_name: string
  file_url: string
  file_type: string | null
  file_size: number | null
  uploaded_by: string | null
  created_at: string
}

export interface ActivityLogEntry {
  id: string
  workspace_id: string
  planner_item_id: string | null
  user_id: string | null
  action: string
  metadata: Record<string, unknown> | null
  created_at: string
}

export interface Notification {
  id: string
  workspace_id: string
  user_id: string
  type: string
  title: string
  body: string | null
  read: boolean
  created_at: string
}

export const PLANNER_ITEM_TYPE_LABELS: Record<PlannerItemType, string> = {
  campaign: 'Campaign',
  press_release: 'Press Release',
  editorial_article: 'Editorial',
  media_pitch: 'Media Pitch',
  client_announcement: 'Client Announcement',
  social_content: 'Social Content',
  event_communication: 'Event',
  report: 'Report',
  coverage_follow_up: 'Coverage Follow-Up',
  approval_request: 'Approval Request',
  internal_task: 'Internal Task'
}

export const BOARD_COLUMNS: { id: PlannerItemStatus; label: string }[] = [
  { id: 'idea', label: 'Idea' },
  { id: 'drafting', label: 'Drafting' },
  { id: 'internal_review', label: 'Internal Review' },
  { id: 'client_approval', label: 'Client Approval' },
  { id: 'scheduled', label: 'Scheduled' },
  { id: 'published', label: 'Published' },
  { id: 'coverage_tracking', label: 'Coverage Tracking' },
  { id: 'reporting', label: 'Reporting' },
  { id: 'completed', label: 'Completed' }
]

export const TYPE_COLORS: Record<PlannerItemType, string> = {
  campaign: '#3d5a80',
  press_release: '#6b4c9a',
  editorial_article: '#2d6a4f',
  media_pitch: '#b86e00',
  client_announcement: '#3d7a6a',
  social_content: '#c45c26',
  event_communication: '#5c4d7a',
  report: '#5c5a56',
  coverage_follow_up: '#3d7a9a',
  approval_request: '#b42318',
  internal_task: '#8a8782'
}
