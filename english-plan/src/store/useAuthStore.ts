import { create } from 'zustand'

export interface User {
  id: string
  username: string
  full_name?: string
  total_xp: number
  level: number
  current_streak: number
  hearts: number
  max_hearts: number
}

interface AuthState {
  user: User | null
  isLoading: boolean
  login: (email: string) => Promise<void>
  logout: () => void
}

// MOCK DATA for initial development without DB
const MOCK_USER: User = {
  id: 'mock-user-1',
  username: 'student_1',
  full_name: 'Student One',
  total_xp: 1250,
  level: 3,
  current_streak: 5,
  hearts: 5,
  max_hearts: 5
}

export const useAuthStore = create<AuthState>((set) => ({
  user: MOCK_USER, // Default to logged in for dev convenience
  isLoading: false,
  login: async (email) => {
    set({ isLoading: true })
    // Simulate API call
    setTimeout(() => {
      set({ user: MOCK_USER, isLoading: false })
    }, 500)
  },
  logout: () => set({ user: null }),
}))
