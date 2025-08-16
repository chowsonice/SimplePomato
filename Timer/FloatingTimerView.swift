//
//  FloatingTimerView.swift
//  Timer
//
//  Created by Assistant on 8/14/25.
//

import SwiftUI

struct FloatingTimerView: View {
    var timeRemaining: Int
    var totalTime: Int
    var isPaused: Bool
    var isPomodoroMode: Bool
    var isBreakTime: Bool
    var pomodoroSession: Int
    
    // Couleurs selon le design spécifié
    private var progressColor: Color {
        if isPomodoroMode {
            return isBreakTime ? Color(red: 1.0, green: 0.18, blue: 0.7) : Color(red: 0.0, green: 0.79, blue: 0.79) // Magenta ou Cyan
        } else {
            return Color(red: 0.23, green: 0.51, blue: 0.98) // Bleu par défaut
        }
    }
    
    private var modeLabel: String {
        if isPomodoroMode {
            return isBreakTime ? "BREAK" : "FOCUS"
        } else {
            return "TIMER"
        }
    }
    
    private var progress: Double {
        guard totalTime > 0 else { return 0 }
        return max(0, min(1, Double(totalTime - timeRemaining) / Double(totalTime)))
    }
    
    var body: some View {
        ZStack {
            // Fond blanc avec ombre subtile
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
            
            VStack(spacing: 12) {
                // Label du mode (FOCUS/BREAK/TIMER)
                Text(modeLabel)
                    .font(.system(size: 10, weight: .semibold, design: .default))
                    .foregroundColor(Color(red: 0.33, green: 0.33, blue: 0.33))
                    .tracking(0.5)
                
                // Indicateur de progression circulaire
                ZStack {
                    // Cercle de fond (track)
                    Circle()
                        .stroke(Color(red: 0.88, green: 0.88, blue: 0.88), lineWidth: 3)
                        .frame(width: 80, height: 80)
                    
                    // Cercle de progression
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(progressColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: progress)
                    
                    // Temps restant au centre
                    VStack(spacing: 0) {
                        Text(formatDuration(seconds: timeRemaining))
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Bouton d'action
                Button(action: {
                    // Action sera gérée par l'AppDelegate
                    NotificationCenter.default.post(name: NSNotification.Name("ToggleTimer"), object: nil)
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .stroke(progressColor, lineWidth: 2)
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(progressColor)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .onHover { isHovered in
                    // Effet de survol subtil
                }
            }
            .padding(16)
        }
        .frame(width: 120, height: 160)
    }
}

struct FloatingTimerView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Mode Focus (Pomodoro)
            FloatingTimerView(
                timeRemaining: 1080, // 18m
                totalTime: 1500,     // 25m
                isPaused: false,
                isPomodoroMode: true,
                isBreakTime: false,
                pomodoroSession: 2
            )
            .previewDisplayName("Focus Mode")
            
            // Mode Pause (Break)
            FloatingTimerView(
                timeRemaining: 300,  // 5m
                totalTime: 300,      // 5m
                isPaused: false,
                isPomodoroMode: true,
                isBreakTime: true,
                pomodoroSession: 1
            )
            .previewDisplayName("Break Mode")
            
            // Mode Timer normal
            FloatingTimerView(
                timeRemaining: 180,  // 3m
                totalTime: 600,      // 10m
                isPaused: true,
                isPomodoroMode: false,
                isBreakTime: false,
                pomodoroSession: 1
            )
            .previewDisplayName("Timer Mode")
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}
