import React from 'react';
import { NavLink, Outlet } from 'react-router-dom';
import { Home, BookOpen, Trophy, User, Zap, Heart } from 'lucide-react';
import { useAuthStore } from '@/store/useAuthStore';
import { cn } from '@/lib/utils';

export function AppShell() {
  const { user } = useAuthStore();

  return (
    <div className="flex flex-col h-screen bg-gray-50 md:flex-row">
      {/* Sidebar (Desktop) */}
      <aside className="hidden md:flex flex-col w-64 bg-white border-r border-gray-200">
        <div className="p-6">
          <h1 className="text-2xl font-bold text-primary flex items-center gap-2">
            <span className="text-3xl">🇬🇧</span> English Plan
          </h1>
        </div>

        <nav className="flex-1 px-4 space-y-2">
          <NavItem to="/" icon={<Home />} label="Home" />
          <NavItem to="/learn" icon={<BookOpen />} label="Learn" />
          <NavItem to="/leaderboard" icon={<Trophy />} label="Leaderboard" />
          <NavItem to="/profile" icon={<User />} label="Profile" />
        </nav>

        <div className="p-4 border-t border-gray-100">
           <div className="bg-blue-50 p-4 rounded-xl">
             <h3 className="font-bold text-blue-900">Premium Plan</h3>
             <p className="text-sm text-blue-700 mt-1">Unlock unlimited hearts and offline mode.</p>
           </div>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 overflow-auto flex flex-col">
        {/* Top Header */}
        <header className="bg-white border-b border-gray-200 p-4 sticky top-0 z-10 flex justify-between items-center shadow-sm">
           <div className="flex items-center gap-4">
              <div className="md:hidden font-bold text-primary">English Plan</div>
           </div>

           <div className="flex items-center gap-6">
              {/* Flag / Course */}
              <div className="hidden sm:flex items-center gap-2 px-3 py-1 rounded-full border border-gray-200 hover:bg-gray-50 cursor-pointer">
                 <span className="text-xl">🇺🇸</span>
                 <span className="font-medium text-gray-600">English</span>
              </div>

              {/* Streak */}
              <div className="flex items-center gap-1.5 text-orange-500 font-bold">
                 <Zap className="fill-orange-500 w-5 h-5" />
                 <span>{user?.current_streak}</span>
              </div>

              {/* Hearts */}
              <div className="flex items-center gap-1.5 text-red-500 font-bold">
                 <Heart className="fill-red-500 w-5 h-5" />
                 <span>{user?.hearts}</span>
              </div>

              {/* User Avatar */}
              <div className="w-10 h-10 rounded-full bg-primary text-white flex items-center justify-center font-bold text-lg">
                {user?.username[0].toUpperCase()}
              </div>
           </div>
        </header>

        <div className="flex-1 p-4 md:p-8 max-w-5xl mx-auto w-full">
           <Outlet />
        </div>
      </main>

      {/* Bottom Nav (Mobile) */}
      <nav className="md:hidden bg-white border-t border-gray-200 flex justify-around p-3 pb-safe">
        <NavItemMobile to="/" icon={<Home />} label="Home" />
        <NavItemMobile to="/learn" icon={<BookOpen />} label="Learn" />
        <NavItemMobile to="/leaderboard" icon={<Trophy />} label="Rank" />
        <NavItemMobile to="/profile" icon={<User />} label="Profile" />
      </nav>
    </div>
  );
}

// @ts-ignore
function NavItem({ to, icon, label }: { to: string; icon: React.ReactNode; label: string }) {
  return (
    <NavLink
      to={to}
      className={({ isActive }) =>
        cn(
          "flex items-center gap-3 px-4 py-3 rounded-xl transition-all font-medium text-gray-500 hover:bg-gray-100",
          isActive && "bg-blue-50 text-blue-600 border-2 border-blue-200"
        )
      }
    >
      {/* @ts-ignore */}
      {React.cloneElement(icon as React.ReactElement, { size: 22, strokeWidth: 2.5 })}
      {label}
    </NavLink>
  );
}

// @ts-ignore
function NavItemMobile({ to, icon, label }: { to: string; icon: React.ReactNode; label: string }) {
  return (
    <NavLink
      to={to}
      className={({ isActive }) =>
        cn(
          "flex flex-col items-center gap-1 p-1 rounded-lg transition-all text-gray-400",
          isActive && "text-blue-600"
        )
      }
    >
      {/* @ts-ignore */}
      {({ isActive }) => React.cloneElement(icon as React.ReactElement, { size: 24, strokeWidth: isActive ? 3 : 2 })}
    </NavLink>
  );
}
