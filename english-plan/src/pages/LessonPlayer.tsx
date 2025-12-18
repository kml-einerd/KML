import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { Progress } from '@/components/ui/progress';
import { Card } from '@/components/ui/card';
import { X, ChevronRight, Mic, CheckCircle2, AlertCircle } from 'lucide-react';
import { useProgressStore } from '@/store/useProgressStore';
import { useAuthStore } from '@/store/useAuthStore';
import { cn } from '@/lib/utils';
import { LevelUpModal } from '@/components/gamification/GamificationOverlay';

// MOCK LESSON DATA (Since we might not have DB connection yet)
const MOCK_LESSON_CONTENT = {
  id: 1,
  title: "Introduction: Actually vs Currently",
  steps: [
    {
      type: "video",
      title: "Watch carefully",
      url: "https://www.youtube.com/embed/oEdkZIU8n0g", // Rachel's English
      duration: 180
    },
    {
      type: "info",
      title: "Key Concept",
      content: "⚠️ **Common Mistake:**\n\nMany students confuse **Actually** with **Currently**.\n\n*   **Actually** = In fact / Na verdade\n*   **Currently** = At the moment / Atualmente"
    },
    {
      type: "multiple_choice",
      question: "What does 'Actually' mean in this sentence: 'Actually, I don't like coffee.'?",
      options: ["Atualmente", "Na verdade", "Infelizmente"],
      correct: 1,
      explanation: "It corrects the expectation that you might like coffee."
    },
    {
      type: "speech",
      prompt: "Say: Actually, I live in Brazil.",
      expected: "actually i live in brazil",
      phonemes: ["actually", "brazil"]
    }
  ]
};

export function LessonPlayer() {
  const { strategyId } = useParams();
  const navigate = useNavigate();
  const [currentStepIndex, setCurrentStepIndex] = useState(0);
  const [isCorrect, setIsCorrect] = useState<boolean | null>(null);
  const [selectedOption, setSelectedOption] = useState<number | null>(null);
  const { completeLesson } = useProgressStore();
  const [showLevelUp, setShowLevelUp] = useState(false);

  const lesson = MOCK_LESSON_CONTENT; // In real app, fetch based on strategyId
  const currentStep = lesson.steps[currentStepIndex];
  const progress = ((currentStepIndex) / lesson.steps.length) * 100;

  const handleNext = () => {
    if (currentStepIndex < lesson.steps.length - 1) {
      setCurrentStepIndex(currentStepIndex + 1);
      setIsCorrect(null);
      setSelectedOption(null);
    } else {
      // Complete Lesson
      completeLesson(Number(strategyId), 50);
      // Simulate level up chance for demo
      if (Math.random() > 0.5) {
          setShowLevelUp(true);
      } else {
          navigate('/');
      }
    }
  };

  const handleCheck = () => {
     if (currentStep.type === 'multiple_choice') {
        if (selectedOption === currentStep.correct) {
            setIsCorrect(true);
            // Play sound
        } else {
            setIsCorrect(false);
            // Play error sound
        }
     } else if (currentStep.type === 'info' || currentStep.type === 'video') {
         handleNext();
     }
  };

  return (
    <div className="flex flex-col h-[calc(100vh-64px)] md:h-screen max-w-3xl mx-auto bg-white md:border-x border-gray-100">

      {/* Header */}
      <div className="p-4 flex items-center gap-4">
        <Button variant="ghost" size="icon" onClick={() => navigate('/')}>
           <X className="text-gray-400" />
        </Button>
        <Progress value={progress} className="h-3 rounded-full" />
      </div>

      {/* Content Area */}
      <div className="flex-1 overflow-y-auto p-6 flex flex-col items-center justify-center">

         {/* VIDEO STEP */}
         {currentStep.type === 'video' && (
            <div className="w-full space-y-4 text-center">
                <h2 className="text-2xl font-bold">{currentStep.title}</h2>
                <div className="relative pt-[56.25%] bg-black rounded-xl overflow-hidden shadow-lg">
                    <iframe
                        className="absolute top-0 left-0 w-full h-full"
                        src={currentStep.url}
                        title="YouTube video player"
                        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                        allowFullScreen
                    ></iframe>
                </div>
                <p className="text-gray-500">Watch the video to understand the context.</p>
            </div>
         )}

         {/* INFO STEP */}
         {currentStep.type === 'info' && (
             <div className="space-y-6 text-center max-w-md">
                 <h2 className="text-2xl font-bold">{currentStep.title}</h2>
                 <div className="bg-blue-50 p-6 rounded-xl border border-blue-100 text-left prose prose-blue">
                     <p className="whitespace-pre-wrap">{currentStep.content}</p>
                 </div>
             </div>
         )}

         {/* QUIZ STEP */}
         {currentStep.type === 'multiple_choice' && (
             <div className="w-full max-w-md space-y-6">
                 <h2 className="text-2xl font-bold text-center">{currentStep.question}</h2>

                 <div className="space-y-3">
                    {currentStep.options?.map((option, idx) => (
                        <div
                           key={idx}
                           onClick={() => !isCorrect && setSelectedOption(idx)}
                           className={cn(
                               "p-4 rounded-xl border-2 cursor-pointer transition-all flex items-center justify-between",
                               selectedOption === idx ? "border-blue-400 bg-blue-50" : "border-gray-200 hover:bg-gray-50",
                               isCorrect === true && idx === currentStep.correct && "bg-green-100 border-green-500",
                               isCorrect === false && selectedOption === idx && "bg-red-100 border-red-500"
                           )}
                        >
                            <span className="font-medium">{option}</span>
                            {/* Keypress visual hints could go here */}
                            <div className="w-6 h-6 border rounded-sm flex items-center justify-center text-xs text-gray-400">
                                {idx + 1}
                            </div>
                        </div>
                    ))}
                 </div>
             </div>
         )}

         {/* SPEECH STEP */}
         {currentStep.type === 'speech' && (
             <SpeechStep
                prompt={currentStep.prompt || ""}
                expected={currentStep.expected || ""}
                onSuccess={() => setIsCorrect(true)}
             />
         )}

      </div>

      <LevelUpModal isOpen={showLevelUp} onClose={() => navigate('/')} newLevel={4} />

      {/* Footer / Controls */}
      <div className={cn(
          "p-6 border-t",
          isCorrect === true ? "bg-green-100 border-green-200" :
          isCorrect === false ? "bg-red-100 border-red-200" : "bg-white border-gray-100"
      )}>
         <div className="max-w-3xl mx-auto flex justify-between items-center">

            {/* Feedback Message */}
            <div className="flex items-center gap-3">
                {isCorrect === true && (
                    <>
                        <div className="w-12 h-12 bg-white rounded-full flex items-center justify-center text-green-500">
                            <CheckCircle2 size={32} />
                        </div>
                        <div>
                            <h4 className="font-bold text-green-800 text-lg">Nicely done!</h4>
                            <p className="text-green-700 text-sm">You are learning fast.</p>
                        </div>
                    </>
                )}
                {isCorrect === false && (
                    <>
                         <div className="w-12 h-12 bg-white rounded-full flex items-center justify-center text-red-500">
                            <AlertCircle size={32} />
                        </div>
                        <div>
                            <h4 className="font-bold text-red-800 text-lg">Not quite...</h4>
                            <p className="text-red-700 text-sm">Correct Answer: {currentStep.type === 'multiple_choice' ? currentStep.options?.[currentStep.correct!] : ''}</p>
                        </div>
                    </>
                )}
            </div>

            {/* Action Button */}
            <Button
                size="lg"
                className={cn(
                    "px-8 font-bold text-lg uppercase tracking-wide",
                    isCorrect === true ? "bg-green-600 hover:bg-green-700" :
                    isCorrect === false ? "bg-red-600 hover:bg-red-700" : "bg-primary"
                )}
                onClick={isCorrect === true || isCorrect === false || currentStep.type === 'info' || currentStep.type === 'video' ? handleNext : handleCheck}
                disabled={currentStep.type === 'multiple_choice' && selectedOption === null}
            >
                {isCorrect === null && currentStep.type !== 'info' && currentStep.type !== 'video' ? 'Check' : 'Continue'}
            </Button>
         </div>
      </div>
    </div>
  );
}

function SpeechStep({ prompt, expected, onSuccess }: { prompt: string, expected: string, onSuccess: () => void }) {
    const [listening, setListening] = useState(false);
    const [transcript, setTranscript] = useState('');
    const [status, setStatus] = useState<'idle' | 'recording' | 'processing' | 'success' | 'fail'>('idle');

    const toggleRecording = () => {
        if (listening) {
            stop();
        } else {
            start();
        }
    };

    const start = () => {
        setListening(true);
        setStatus('recording');

        // Mock Speech Recognition for Browser compatibility safety in sandbox
        // In real app: use window.webkitSpeechRecognition
        setTimeout(() => {
            const mockResult = expected; // Simulate perfect speech for demo
            setTranscript(mockResult);
            setListening(false);
            setStatus('success');
            onSuccess();
        }, 3000);
    };

    const stop = () => {
        setListening(false);
    };

    return (
        <div className="text-center space-y-8">
            <h2 className="text-2xl font-bold">{prompt}</h2>

            <div className="relative">
                <Button
                    variant={listening ? "destructive" : "default"}
                    className={cn(
                        "w-32 h-32 rounded-full flex items-center justify-center transition-all",
                        listening && "animate-pulse ring-8 ring-red-200"
                    )}
                    onClick={toggleRecording}
                >
                    <Mic size={48} />
                </Button>
                {status === 'success' && (
                    <div className="absolute top-0 right-0 -mt-2 -mr-2 bg-green-500 text-white p-2 rounded-full">
                        <CheckCircle2 />
                    </div>
                )}
            </div>

            <div className="h-12">
                {listening && <p className="text-gray-500 animate-bounce">Listening...</p>}
                {transcript && <p className="text-xl font-medium text-blue-600">"{transcript}"</p>}
            </div>
        </div>
    )
}
