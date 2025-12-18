import React, { useEffect, useState } from 'react';
import { createPortal } from 'react-dom';
import { Trophy, Star, X } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils';
import { useAuthStore } from '@/store/useAuthStore';

interface LevelUpModalProps {
  isOpen: boolean;
  onClose: () => void;
  newLevel: number;
}

export function LevelUpModal({ isOpen, onClose, newLevel }: LevelUpModalProps) {
  if (!isOpen) return null;

  return createPortal(
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm animate-in fade-in">
      <div className="bg-white rounded-2xl p-8 max-w-sm w-full mx-4 relative overflow-hidden text-center shadow-2xl animate-in zoom-in-95">

        {/* Background rays effect */}
        <div className="absolute inset-0 bg-gradient-to-br from-yellow-100 to-transparent opacity-50"></div>

        <div className="relative z-10">
            <div className="w-24 h-24 bg-yellow-400 rounded-full mx-auto mb-6 flex items-center justify-center shadow-lg animate-bounce">
                <Trophy size={48} className="text-yellow-900" />
            </div>

            <h2 className="text-3xl font-bold text-gray-800 mb-2">LEVEL UP!</h2>
            <p className="text-gray-500 mb-8">You are now Level {newLevel}</p>

            <div className="grid grid-cols-2 gap-4 mb-8">
                <div className="bg-gray-50 p-4 rounded-xl">
                    <div className="text-sm text-gray-500">Unlocks</div>
                    <div className="font-bold text-lg">New Badge</div>
                </div>
                 <div className="bg-gray-50 p-4 rounded-xl">
                    <div className="text-sm text-gray-500">Bonus</div>
                    <div className="font-bold text-lg text-yellow-600">+100 XP</div>
                </div>
            </div>

            <Button size="lg" className="w-full font-bold" onClick={onClose}>
                CONTINUE
            </Button>
        </div>
      </div>
    </div>,
    document.body
  );
}

export function XPFloating({ amount, x, y }: { amount: number, x: number, y: number }) {
    return (
        <div
            className="fixed pointer-events-none text-yellow-500 font-bold text-2xl animate-out fade-out slide-out-to-top-10 duration-1000 z-50 flex items-center gap-1 shadow-sm"
            style={{ left: x, top: y }}
        >
            +{amount} <span className="text-sm">XP</span>
        </div>
    )
}
