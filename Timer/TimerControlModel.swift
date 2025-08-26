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
        currentTimerPreset = preset
        regularDuration = settingsManager.settingsData.timer_presets[preset]
        maxTime = max(regularDuration * 60, 1)
        timeRemaining = maxTime
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
        isBreakTime = false
        isExtra = true
        maxTime = minutes * 60
        timeRemaining = maxTime
        isPaused = false
        startTimer()
    }

    func skipBreak() {
        isBreakTime = false
        isExtra = false
        maxTime = settingsManager.settingsData.pomodoro_work_duration * 60
        timeRemaining = maxTime
        isPaused = false
        startTimer()
    }

    func handlePomodoroCompletion() {
        if isBreakTime {
            isBreakTime = false
            if pomodoroSession == 4 {
                pomodoroSession = 1
                return
            }
            if !isExtra {
                pomodoroSession += 1
            }
            isExtra = false
            maxTime = settingsManager.settingsData.pomodoro_work_duration * 60
            timeRemaining = maxTime
        } else {
            isBreakTime = true
            if pomodoroSession == 4 {
                let breakDuration = settingsManager.settingsData.pomodoro_long_break_duration
                maxTime = breakDuration * 60
                timeRemaining = maxTime
            } else {
                let breakDuration = settingsManager.settingsData.pomodoro_break_duration
                maxTime = breakDuration * 60
                timeRemaining = maxTime
            }
        }
    }

    func cancelTimer() {
        if isPomodoroMode {
            isPomodoroMode = false
            pomodoroSession = 1
            isBreakTime = false
        }
        timeRemaining = maxTime
        isPaused = true
        stopTimer()
    }

    func restartTimer() {
        timeRemaining = maxTime
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
