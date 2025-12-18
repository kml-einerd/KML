import React from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { AppShell } from '@/components/layout/AppShell';
import { Dashboard } from '@/pages/Dashboard';
import { LessonPlayer } from '@/pages/LessonPlayer';

// Simple placeholders for other routes
const Learn = () => <div className="p-8"><h1>Full Curriculum (Coming Soon)</h1></div>;
const Leaderboard = () => <div className="p-8"><h1>Leaderboard (Coming Soon)</h1></div>;
const Profile = () => <div className="p-8"><h1>Profile Settings (Coming Soon)</h1></div>;

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<AppShell />}>
          <Route index element={<Dashboard />} />
          <Route path="learn" element={<Learn />} />
          <Route path="leaderboard" element={<Leaderboard />} />
          <Route path="profile" element={<Profile />} />
        </Route>
        <Route path="/lesson/:strategyId" element={<LessonPlayer />} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
