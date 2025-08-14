//
//  ContentView.swift
//  Timer
//
//  Created by Patrick Cunniff on 6/3/23.
//

import SwiftUI

struct CustomButton: View {
    let text: String
    @State var isActive: Bool = false
    
    var body: some View {
        Text(text)
            .onHover { isHovered in
                self.isActive = isHovered
            }
            .padding(.vertical, 3)
            .padding(.horizontal, 6)
            .background(isActive ? Color.white.opacity(0.15) : Color.clear)
            .cornerRadius(4)
    }
}

struct MainView: View {
    @Binding var timeRemaining: Int
    @State private var selectedIndex = 2
    @State private var isPaused = true
    @State private var maxTime = 300
    @State private var currentTimerPreset = 0
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var soundPlayer = SoundPlayer()
    
    // Pomodoro state
    @State private var isPomodoroMode = false
    @State private var pomodoroSession = 1 // 1-4 for work sessions
    @State private var isBreakTime = false
    @State private var completedPomodoros = 0
    
    @StateObject var settingsManager: SettingsManager = SettingsManager.instance

    var body: some View {
        VStack {
            HStack(spacing: 1) {
                ForEach(0..<100) { index in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(index == 100-Int((100*timeRemaining/maxTime)) ? Color.red : Color.gray.opacity(0.3))
                        .frame(width: index == selectedIndex ? 2 : 1.5, height: 20)
                }
            }
            
            // Pomodoro status indicator
            if isPomodoroMode {
                HStack {
                    Text(isBreakTime ? "☕ Break" : "🍅 Work")
                        .fontWeight(.medium)
                        .foregroundColor(isBreakTime ? .blue : .red)
                    Spacer()
                    Text("Session \(pomodoroSession)/4")
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
            
            HStack(spacing: 1) {
                Group {
                    if isPaused {
                        CustomButton(text: String(settingsManager.settingsData.timer_presets[0]) + "m")
                            .onTapGesture {
                                startRegularTimer(preset: 0)
                            }
                        CustomButton(text: String(settingsManager.settingsData.timer_presets[1]) + "m")
                            .onTapGesture {
                                startRegularTimer(preset: 1)
                            }
                        CustomButton(text: String(settingsManager.settingsData.timer_presets[2]) + "m")
                            .onTapGesture {
                                startRegularTimer(preset: 2)
                            }
                        CustomButton(text: pomodoroButtonText())
                            .onTapGesture {
                                startPomodoroTimer()
                            }
                    } else {
                        CustomButton(text: "cancel").onTapGesture {
                            cancelTimer()
                        }
                        CustomButton(text: "restart").onTapGesture {
                            restartTimer()
                        }
                    }
                }
                Spacer()
                
                Menu {
                    Button("Settings") {
                        AppDelegate.shared.openCocoaWindow(id: "settings")
                    }
                    
                    Divider()
                    
                    Button("About SimplePomato") {
                        AppDelegate.shared.openCocoaWindow(id: "about")
                    }
                    
                    Button("Quit") {
                        NSApplication.shared.terminate(nil)
                    }
                } label: {
                }
                .menuStyle(BorderlessButtonMenuStyle())
            }
            
            Spacer().frame(height: 30)
            
            HStack(alignment: .lastTextBaseline) {
                Group {
                    if isPaused {
                        if timeRemaining == 0 {
                            CustomButton(text: "stop")
                            .onTapGesture {
                                maxTime = max(settingsManager.settingsData.timer_presets[currentTimerPreset] * 60, 1)
                                timeRemaining = maxTime
                                soundPlayer.stopSound()
                            }
                        } else {
                            CustomButton(text: "start")
                            .onTapGesture {
                                isPaused = false
                                timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
                                soundPlayer.stopSound()
                            }
                        }
                    } else {
                        CustomButton(text: "pause")
                        .onTapGesture {
                            isPaused = true
                        }
                    }
                }
                
                Spacer()
                
                Text("\(formatDuration(seconds: timeRemaining))")
                    .font(.system(size: 36))
                    .fontWeight(.thin)
                    .onReceive(timer) { _ in
                        if !isPaused && timeRemaining > 0 {
                            timeRemaining -= 1
                        }
                        if timeRemaining == 0 {
                            soundPlayer.playSound(volume: settingsManager.settingsData.alarm_volume)
                            isPaused = true
                            
                            if isPomodoroMode {
                                handlePomodoroCompletion()
                            }
                        }
                        
                        // Mettre à jour la fenêtre flottante
                        DispatchQueue.main.async {
                            AppDelegate.shared.updateFloatingTimer(
                                timeRemaining: timeRemaining,
                                isPaused: isPaused,
                                isPomodoroMode: isPomodoroMode,
                                isBreakTime: isBreakTime,
                                pomodoroSession: pomodoroSession
                            )
                        }
                    }
            }
            .foregroundColor(.primary)
        }
        .frame(width: 250)
        .padding(.all, 10.0)
    }
    
    // MARK: - Timer Functions
    private func startRegularTimer(preset: Int) {
        isPomodoroMode = false
        currentTimerPreset = preset
        maxTime = max(settingsManager.settingsData.timer_presets[preset] * 60, 1)
        timeRemaining = maxTime
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        isPaused = false
        soundPlayer.stopSound()
    }
    
    private func startPomodoroTimer() {
        isPomodoroMode = true
        pomodoroSession = 1
        isBreakTime = false
        completedPomodoros = 0
        
        maxTime = settingsManager.settingsData.pomodoro_work_duration * 60
        timeRemaining = maxTime
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
        isPaused = false
        soundPlayer.stopSound()
    }
    
    private func handlePomodoroCompletion() {
        if isBreakTime {
            // Break completed, prepare next work session or finish cycle
            isBreakTime = false
            pomodoroSession += 1
            
            if pomodoroSession > 4 {
                // Completed full Pomodoro cycle
                isPomodoroMode = false
                pomodoroSession = 1
                completedPomodoros += 1
                return
            }
            
            // Prepare next work session but don't auto-start
            maxTime = settingsManager.settingsData.pomodoro_work_duration * 60
            timeRemaining = maxTime
            // Don't restart timer automatically - wait for user to click start
        } else {
            // Work session completed, prepare break but don't auto-start
            isBreakTime = true
            
            // Long break after 4th session, short break otherwise
            let breakDuration = (pomodoroSession == 4) ? 
                settingsManager.settingsData.pomodoro_long_break_duration :
                settingsManager.settingsData.pomodoro_break_duration
            
            maxTime = breakDuration * 60
            timeRemaining = maxTime
            // Don't restart timer automatically - wait for user to click start
        }
    }
    
    private func cancelTimer() {
        if isPomodoroMode {
            isPomodoroMode = false
            pomodoroSession = 1
            isBreakTime = false
        }
        timeRemaining = maxTime
        isPaused = true
    }
    
    private func restartTimer() {
        timeRemaining = maxTime
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    }
    
    private func pomodoroButtonText() -> String {
        if isPomodoroMode && !isPaused {
            return isBreakTime ? "☕ Break" : "🍅 Work"
        }
        return "🍅"
    }
}


struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(timeRemaining: .constant(245))
            .environmentObject(SettingsManager.instance)
    }
}
