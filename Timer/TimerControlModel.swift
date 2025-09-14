// TimerControlModel.swift

import Foundation
import SwiftUI
import Combine

class TimerControlModel: ObservableObject {
    static let shared = TimerControlModel()
    
    // Timer State
    @Published var timeRemaining: Int = 300
    @Published var isPaused: Bool = true
    @Published var maxTime: Int = 300
    @Published var currentTimerPreset: Int = 0
    @Published var isPomodoroMode: Bool = false
    @Published var pomodoroSession: Int = 1
    @Published var isBreakTime: Bool = false
    @Published var isExtra: Bool = false
    @Published var regularDuration: Int = 25
    @Published var workDuration: Int = 25
    @Published var breakDuration: Int = 5
    @Published var longBreakDuration: Int = 15

    private var timer: AnyCancellable?
    private var soundPlayer = SoundPlayer()
    @Published var settingsManager: SettingsManager = SettingsManager.instance

    private init() {}

    // MARK: - Timer Functions

    func startRegularTimer(preset: Int) {
        isPomodoroMode = false
        isPaused = false
        currentTimerPreset = preset
        regularDuration = settingsManager.settingsData.timer_presets[preset]
        maxTime = max(regularDuration * 60, 1)
        timeRemaining = maxTime
        stopTimer()
        startTimer()
        soundPlayer.stopSound()
    }

    func startPomodoroTimer() {
        isPomodoroMode = true
        pomodoroSession = 1
        isBreakTime = false

        workDuration = settingsManager.settingsData.pomodoro_work_duration
        breakDuration = settingsManager.settingsData.pomodoro_break_duration
        longBreakDuration = settingsManager.settingsData.pomodoro_long_break_duration
        maxTime = workDuration * 60
        timeRemaining = maxTime
        startTimer()
        soundPlayer.stopSound()
    }

    func startExtra(minutes: Int) {
        stopTimer()
        isExtra = true
        maxTime = minutes * 60
        timeRemaining = maxTime
        isPaused = false
        startTimer()
    }

    func addTimeAndSwitchMode(minutes: Int) {
        stopTimer()
        isExtra = false
        
        if isBreakTime {
            // Actuellement en pause -> retourner au travail avec du temps supplémentaire
            isBreakTime = false
            let workDuration = settingsManager.settingsData.pomodoro_work_duration
            maxTime = (workDuration + minutes) * 60
            timeRemaining = maxTime
        } else {
            // Actuellement au travail -> passer à la pause avec du temps supplémentaire
            isBreakTime = true
            let breakDuration = pomodoroSession == 4 ? 
                settingsManager.settingsData.pomodoro_long_break_duration : 
                settingsManager.settingsData.pomodoro_break_duration
            maxTime = (breakDuration + minutes) * 60
            timeRemaining = maxTime
        }
        
        isPaused = false
        startTimer()
    }

    func skipBreak() {
        stopTimer()
        isBreakTime = false
        isExtra = false
        maxTime = settingsManager.settingsData.pomodoro_work_duration * 60
        timeRemaining = maxTime
        isPaused = false
        
        // Incrémenter la session après avoir sauté une pause
        if pomodoroSession < 4 {
            pomodoroSession += 1
        } else {
            pomodoroSession = 1
        }
        
        startTimer()
    }

    func handlePomodoroCompletion() {
        stopTimer()
        if isBreakTime {
            // Fin de pause : retour au travail
            isPaused = true
            isBreakTime = false
            isExtra = false
            // Incrémenter la session seulement après une pause de travail normale (pas extra)
            if !isExtra && pomodoroSession < 4 {
                pomodoroSession += 1
            } else if pomodoroSession == 4 {
                pomodoroSession = 1
            }
            maxTime = settingsManager.settingsData.pomodoro_work_duration * 60
            timeRemaining = maxTime
        } else {
            // Fin de travail : début de pause
            isPaused = true
            isBreakTime = true
            isExtra = false
            if pomodoroSession == 4 {
                // Pause longue après la 4ème session
                let breakDuration = settingsManager.settingsData.pomodoro_long_break_duration
                maxTime = breakDuration * 60
                timeRemaining = maxTime
            } else {
                // Pause courte
                let breakDuration = settingsManager.settingsData.pomodoro_break_duration
                maxTime = breakDuration * 60
                timeRemaining = maxTime
            }
        }
    }

    func cancelTimer() {
        stopTimer()
        isPaused = true
        isPomodoroMode = false
        pomodoroSession = 1
        isBreakTime = false
        isExtra = false
        timeRemaining = maxTime
    }

    func restartTimer() {
        stopTimer()
        timeRemaining = maxTime
        isPaused = false
        startTimer()
    }

    func toggleTimer() {
        if isPaused {
            if timeRemaining > 0 {
                isPaused = false
                startTimer()
                soundPlayer.stopSound()
            }
        } else {
            isPaused = true
            stopTimer()
        }
    }

    private func startTimer() {
        stopTimer()
        isPaused = false
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
        isPaused = true
    }

    private func tick() {
        guard !isPaused else { return }
        if timeRemaining > 0 {
            timeRemaining -= 1
        }
        if timeRemaining == 0 {
            soundPlayer.playSound(volume: settingsManager.settingsData.alarm_volume)
            isPaused = true
            if isPomodoroMode {
                handlePomodoroCompletion()
            }
        }
        DispatchQueue.main.async {
            AppDelegate.shared.updateFloatingTimer(
                timeRemaining: self.timeRemaining,
                totalTime: self.maxTime,
                isPaused: self.isPaused,
                isPomodoroMode: self.isPomodoroMode,
                isBreakTime: self.isBreakTime,
                pomodoroSession: self.pomodoroSession,
                workDuration: self.workDuration,
                breakDuration: self.breakDuration,
                longBreakDuration: self.longBreakDuration
            )
        }
    }
}
