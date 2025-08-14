//
//  UserDefaults.swift
//  Timer
//
//  Created by Patrick Cunniff on 6/4/23.
//

import Foundation

@propertyWrapper
struct UserDefault<T> {
    let key: String
    let defaultValue: T
    
    var wrappedValue: T {
        get {
            UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}

struct SettingsData {
    @UserDefault(key: "launch_at_login", defaultValue: false)
    var launch_at_login: Bool
    
    @UserDefault(key: "timer_presets", defaultValue: [5, 10, 15])
    var timer_presets: [Int]
    
    @UserDefault(key: "pomodoro_work_duration", defaultValue: 25)
    var pomodoro_work_duration: Int
    
    @UserDefault(key: "pomodoro_break_duration", defaultValue: 5)
    var pomodoro_break_duration: Int
    
    @UserDefault(key: "pomodoro_long_break_duration", defaultValue: 15)
    var pomodoro_long_break_duration: Int
    
    @UserDefault(key: "show_floating_timer", defaultValue: false)
    var show_floating_timer: Bool
    
    @UserDefault(key: "alarm_volume", defaultValue: 25)
    var alarm_volume: Int
}

class SettingsManager: ObservableObject {
    static let instance = SettingsManager()

    @Published var settingsData: SettingsData

    private init() {
        settingsData = SettingsData()
    }
}
