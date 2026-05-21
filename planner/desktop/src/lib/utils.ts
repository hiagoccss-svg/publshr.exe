import { format, isPast, parseISO } from 'date-fns'
import type { PlannerItem } from '@/types/planner'

export function cn(...classes: (string | false | null | undefined)[]): string {
  return classes.filter(Boolean).join(' ')
}

export function formatShortDate(date: string | null): string {
  if (!date) return '—'
  try {
    return format(parseISO(date), 'MMM d')
  } catch {
    return '—'
  }
}

export function isOverdue(item: PlannerItem): boolean {
  if (!item.due_date) return false
  if (item.status === 'completed' || item.status === 'published') return false
  try {
    return isPast(parseISO(item.due_date))
  } catch {
    return false
  }
}

export function initials(name: string): string {
  return name
    .split(/\s+/)
    .map((w) => w[0])
    .join('')
    .slice(0, 2)
    .toUpperCase()
}
