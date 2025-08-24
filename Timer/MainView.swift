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

struct CustomIconButton: View {
    let text: String
    let iconName: String
    @State var isActive: Bool = false
    
    var body: some View {
        HStack(spacing: 3) {
            if iconName == "tomato" {
                Image("tomato")
                    .resizable()
                    .frame(width: 11, height: 11)
            } else {
                Image(systemName: iconName)
                    .font(.system(size: 11))
            }
            Text(text)
        }
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
    @State private var regularDuration: Int = 25 // Default regular duration in minutes
    @State private var workDuration: Int = 25 // Default work duration in minutes
    @State private var breakDuration: Int = 5 // Default break duration in minutes
    @State private var longBreakDuration: Int = 15 // Default long break duration in minutes
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
                    HStack(spacing: 4) {
                        if isBreakTime {
                            Image(systemName: "cup.and.saucer.fill")
                                .resizable()
                                .frame(width: 16, height: 16)
                                .foregroundColor(.blue)
                        } else {
                            Image("tomato")
                                .resizable()
                                .frame(width: 16, height: 16)
                                .foregroundColor(.red)
                        }
                        Text(isBreakTime ? "break" : "work")
                            .fontWeight(.medium)
                            .foregroundColor(isBreakTime ? .blue : .red)
                    }
                    Spacer()
HStack(spacing: 6) {
    ForEach(1...4, id: \.self) { idx in
        Circle()
            .fill(idx <= pomodoroSession ? Color.red : Color.gray.opacity(0.3))
            .frame(width: 5, height: 5)
    }
}
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
            
            HStack(spacing: 1) {
                Group {
                    if isPaused {
                        if isPomodoroMode {
                            CustomButton(text: "+1m")
                                .onTapGesture {
                                    timeRemaining += 60
                                    maxTime += 60
                                }
                            CustomButton(text: "+5m")
                                .onTapGesture {
                                    timeRemaining += 300
                                    maxTime += 300
                                }
                            CustomButton(text: "Skip Break")
                                .onTapGesture {
                                    isBreakTime = false
                                    pomodoroSession += 1
                                    maxTime = settingsManager.settingsData.pomodoro_work_duration * 60
                                    timeRemaining = maxTime
                                }
                        } else {
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
                            CustomIconButton(
                                text: pomodoroButtonText(),
                                iconName: pomodoroIconName()
                            )
                                .onTapGesture {
                                    startPomodoroTimer()
                                }
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
                                totalTime: maxTime,
                                isPaused: isPaused,
                                isPomodoroMode: isPomodoroMode,
                                isBreakTime: isBreakTime,
                                pomodoroSession: pomodoroSession,
                                workDuration: workDuration,
                                breakDuration: breakDuration,
                                longBreakDuration: longBreakDuration
                            )
                        }
                    }
            }
            .foregroundColor(.primary)
        }
        .frame(width: 250)
        .padding(.all, 10.0)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.2))
        .cornerRadius(10)
        .onAppear {
            // Ajouter l'observateur pour les actions de la fenêtre flottante
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("ToggleTimer"),
                object: nil,
                queue: .main
            ) { _ in
                self.toggleTimer()
            }
        }
        .onDisappear {
            // Retirer l'observateur
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name("ToggleTimer"), object: nil)
        }
    }
    
    // MARK: - Timer Functions
    private func toggleTimer() {
        if isPaused {
            // Démarrer le timer
            if timeRemaining > 0 {
                isPaused = false
                timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
                soundPlayer.stopSound()
            }
        } else {
            // Mettre en pause le timer
            isPaused = true
        }
    }
    
    private func startRegularTimer(preset: Int) {
        isPomodoroMode = false
        currentTimerPreset = preset
        regularDuration = settingsManager.settingsData.timer_presets[preset]
        maxTime = max(regularDuration * 60, 1)
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

        workDuration = settingsManager.settingsData.pomodoro_work_duration
        breakDuration = settingsManager.settingsData.pomodoro_break_duration
        longBreakDuration = settingsManager.settingsData.pomodoro_long_break_duration
        maxTime = workDuration * 60
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

        // Replace preset menu with new options when paused and in Pomodoro mode
        // No additional function is needed; the menu is directly handled in the UI logic.
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
            return isBreakTime ? "break" : "work"
        }
        return "pomo"
    }
    
    private func pomodoroIconName() -> String {
        if isPomodoroMode && !isPaused {
            return isBreakTime ? "cup.and.saucer.fill" : "tomato"
        }
        return "tomato"
    }
}


struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(timeRemaining: .constant(245))
            .environmentObject(SettingsManager.instance)
    }
}
