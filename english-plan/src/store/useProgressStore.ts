import { create } from 'zustand'

interface Strategy {
  id: number
  strategy_number: number
  phase: string
  name: string
  description: string
  status: 'locked' | 'available' | 'completed' | 'mastered'
  progress: number
}

interface ProgressState {
  strategies: Strategy[]
  loadStrategies: () => Promise<void>
  unlockStrategy: (id: number) => void
  completeLesson: (strategyId: number, xp: number) => void
}

// MOCK DATA
const MOCK_STRATEGIES: Strategy[] = [
  { id: 1, strategy_number: 1, phase: 'beginners', name: 'How About You?', description: 'Keep the conversation going', status: 'available', progress: 0 },
  { id: 2, strategy_number: 2, phase: 'beginners', name: 'Actually', description: 'Correcting or adding info', status: 'locked', progress: 0 },
  { id: 3, strategy_number: 3, phase: 'beginners', name: 'I Mean', description: 'Clarifying your point', status: 'locked', progress: 0 },
  { id: 4, strategy_number: 4, phase: 'beginners', name: 'You Know', description: 'Creating connection', status: 'locked', progress: 0 },
  { id: 5, strategy_number: 5, phase: 'beginners', name: 'Kind Of / Sort Of', description: 'Softening statements', status: 'locked', progress: 0 },
  // Add more as needed
]

export const useProgressStore = create<ProgressState>((set, get) => ({
  strategies: MOCK_STRATEGIES,
  loadStrategies: async () => {
    // In real app, fetch from Supabase
    // set({ strategies: fetchedData })
  },
  unlockStrategy: (id) => {
    set((state) => ({
      strategies: state.strategies.map(s =>
        s.id === id ? { ...s, status: 'available' } : s
      )
    }))
  },
  completeLesson: (strategyId, xp) => {
     // Handle XP in AuthStore ideally, but here we update progress
     set((state) => ({
       strategies: state.strategies.map(s =>
         s.id === strategyId ? { ...s, progress: Math.min(s.progress + 33, 100) } : s // Assume 3 lessons per strategy for mock
       )
     }))
  }
}))
