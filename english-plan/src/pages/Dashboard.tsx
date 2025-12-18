import React from 'react';
import { useProgressStore } from '@/store/useProgressStore';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Lock, Check, Star } from 'lucide-react';
import { cn } from '@/lib/utils';
import { useNavigate } from 'react-router-dom';

export function Dashboard() {
  const { strategies } = useProgressStore();
  const navigate = useNavigate();

  return (
    <div className="space-y-8">
      {/* Header Banner */}
      <div className="bg-gradient-to-r from-blue-600 to-indigo-600 rounded-2xl p-6 text-white shadow-lg">
        <h2 className="text-2xl font-bold mb-2">Welcome back, Student! 👋</h2>
        <p className="opacity-90">You are on a 5 day streak. Keep it up!</p>
      </div>

      {/* Learning Path */}
      <div className="relative max-w-2xl mx-auto pb-20">

        {/* Phase Header */}
        <div className="flex items-center gap-4 mb-8">
            <div className="h-px bg-gray-300 flex-1"></div>
            <span className="text-sm font-bold text-gray-500 uppercase tracking-widest bg-gray-100 px-3 py-1 rounded">
                Phase 1: Beginners (A2)
            </span>
            <div className="h-px bg-gray-300 flex-1"></div>
        </div>

        {/* Path Nodes */}
        <div className="flex flex-col items-center gap-6">
          {strategies.map((strategy, index) => {
             const isLeft = index % 2 === 0;
             const isAvailable = strategy.status === 'available' || strategy.status === 'completed';
             const isLocked = strategy.status === 'locked';

             return (
               <div key={strategy.id} className={cn("relative z-10",
                  isLeft ? "-translate-x-12" : "translate-x-12"
               )}>
                  <div className="group relative">
                     {/* Floating Label */}
                     <div className={cn(
                       "absolute top-2 w-48 text-center pointer-events-none transition-all",
                       isLeft ? "right-full mr-4 text-right" : "left-full ml-4 text-left"
                     )}>
                        <h4 className="font-bold text-gray-700">{strategy.strategy_number}. {strategy.name}</h4>
                        <p className="text-xs text-gray-500">{strategy.description}</p>
                     </div>

                     {/* Circle Button */}
                     <button
                       onClick={() => !isLocked && navigate(`/lesson/${strategy.id}`)}
                       disabled={isLocked}
                       className={cn(
                         "w-20 h-20 rounded-full flex items-center justify-center border-b-4 transition-all shadow-sm active:border-b-0 active:translate-y-1",
                         strategy.status === 'completed'
                           ? "bg-yellow-400 border-yellow-600 text-yellow-900"
                           : strategy.status === 'available'
                             ? "bg-primary border-green-700 text-white animate-pulse-slow"
                             : "bg-gray-200 border-gray-300 text-gray-400 cursor-not-allowed"
                       )}
                     >
                       {isLocked ? <Lock size={24} /> :
                        strategy.status === 'completed' ? <Check size={32} strokeWidth={3} /> :
                        <Star size={32} fill="currentColor" />
                       }
                     </button>

                     {/* Crown for mastery */}
                     {strategy.status === 'completed' && (
                        <div className="absolute -top-6 -right-2 text-yellow-500 animate-bounce">
                           <Star size={24} fill="currentColor" />
                        </div>
                     )}
                  </div>
               </div>
             )
          })}
        </div>
      </div>
    </div>
  );
}
