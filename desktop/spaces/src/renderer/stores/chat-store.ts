import { create } from 'zustand'

export interface ChatChannel {
  id: string
  name: string
  description: string
  isDm: boolean
  unread: number
}

export interface ChatMessage {
  id: string
  channelId: string
  authorId: string
  authorName: string
  body: string
  createdAt: string
}

const STORAGE_KEY = 'publshr.enterprise.chat.v1'

const DEFAULT_CHANNELS: ChatChannel[] = [
  { id: 'general', name: 'general', description: 'Workspace-wide updates', isDm: false, unread: 0 },
  { id: 'operations', name: 'operations', description: 'Ops and delivery', isDm: false, unread: 0 },
  { id: 'creative', name: 'creative', description: 'Docs, campaigns, assets', isDm: false, unread: 0 }
]

const DEFAULT_MESSAGES: ChatMessage[] = [
  {
    id: 'm1',
    channelId: 'general',
    authorId: 'system',
    authorName: 'Publshr',
    body: 'Welcome to enterprise chat. Messages are stored locally until Supabase sync is connected.',
    createdAt: new Date(Date.now() - 3600_000).toISOString()
  }
]

function loadPersisted(): { channels: ChatChannel[]; messages: ChatMessage[] } {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return { channels: DEFAULT_CHANNELS, messages: DEFAULT_MESSAGES }
    const parsed = JSON.parse(raw) as { channels: ChatChannel[]; messages: ChatMessage[] }
    return {
      channels: parsed.channels?.length ? parsed.channels : DEFAULT_CHANNELS,
      messages: parsed.messages?.length ? parsed.messages : DEFAULT_MESSAGES
    }
  } catch {
    return { channels: DEFAULT_CHANNELS, messages: DEFAULT_MESSAGES }
  }
}

function persist(state: { channels: ChatChannel[]; messages: ChatMessage[] }): void {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify({ channels: state.channels, messages: state.messages }))
  } catch {
    /* ignore quota */
  }
}

interface ChatState {
  hydrated: boolean
  channels: ChatChannel[]
  messages: ChatMessage[]
  activeChannelId: string
  draft: string
  hydrate: () => void
  setActiveChannel: (id: string) => void
  setDraft: (v: string) => void
  sendMessage: (authorId: string, authorName: string) => void
  createChannel: (name: string) => void
}

export const useChatStore = create<ChatState>((set, get) => ({
  hydrated: false,
  channels: DEFAULT_CHANNELS,
  messages: DEFAULT_MESSAGES,
  activeChannelId: 'general',
  draft: '',

  hydrate: () => {
    const data = loadPersisted()
    set({
      hydrated: true,
      channels: data.channels,
      messages: data.messages,
      activeChannelId: data.channels[0]?.id ?? 'general'
    })
  },

  setActiveChannel: (id) => {
    set((s) => ({
      activeChannelId: id,
      channels: s.channels.map((c) => (c.id === id ? { ...c, unread: 0 } : c))
    }))
    persist({ channels: get().channels, messages: get().messages })
  },

  setDraft: (draft) => set({ draft }),

  sendMessage: (authorId, authorName) => {
    const body = get().draft.trim()
    if (!body) return
    const channelId = get().activeChannelId
    const message: ChatMessage = {
      id: `m-${Date.now()}`,
      channelId,
      authorId,
      authorName,
      body,
      createdAt: new Date().toISOString()
    }
    set((s) => {
      const next = { channels: s.channels, messages: [...s.messages, message] }
      persist(next)
      return { ...next, draft: '' }
    })
  },

  createChannel: (name) => {
    const trimmed = name.trim().toLowerCase().replace(/\s+/g, '-')
    if (!trimmed) return
    const id = trimmed
    if (get().channels.some((c) => c.id === id)) return
    const channel: ChatChannel = {
      id,
      name: trimmed,
      description: 'Team channel',
      isDm: false,
      unread: 0
    }
    set((s) => {
      const next = { channels: [...s.channels, channel], messages: s.messages }
      persist(next)
      return { ...next, activeChannelId: id }
    })
  }
}))
