//
//  SettingsView.swift
//  Timer
//
//  Created by Patrick Cunniff on 6/4/23.
//

import SwiftUI

import ServiceManagement

func setLaunchAtLogin(enabled: Bool) {
    if enabled {
        try? SMAppService().register()
    } else {
        try? SMAppService().unregister()
    }
}

struct SettingsView: View {
    @StateObject var settingsManager: SettingsManager = SettingsManager.instance
    
    @State private var soundPlayer = SoundPlayer()
    
    var body: some View {
        Form {
            VStack {
                Text("Timer presets (min):")
                HStack(alignment: .center) {
                    Spacer()
                    TextField("", text: Binding(
                        get: { String(settingsManager.settingsData.timer_presets[0]) },
                        set: { settingsManager.settingsData.timer_presets[0] = (Int($0) ?? 0)}
                    ))
                        .frame(width: 40)
                        .multilineTextAlignment(.center)
                    TextField("", text: Binding(
                        get: { String(settingsManager.settingsData.timer_presets[1]) },
                        set: { settingsManager.settingsData.timer_presets[1] = (Int($0) ?? 0)}
                    ))
                        .frame(width: 40)
                        .multilineTextAlignment(.center)
                    TextField("", text: Binding(
                        get: { String(settingsManager.settingsData.timer_presets[2]) },
                        set: { settingsManager.settingsData.timer_presets[2] = (Int($0) ?? 0)}
                    ))
                        .frame(width: 40)
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                Divider()
                Text("🍅 Pomodoro Settings:")
                HStack {
                    Text("work:")
                    TextField("", text: Binding(
                        get: { String(settingsManager.settingsData.pomodoro_work_duration) },
                        set: { settingsManager.settingsData.pomodoro_work_duration = (Int($0) ?? 25)}
                    ))
                        .frame(width: 40)
                        .multilineTextAlignment(.center)
                    Text("min")
                    
                    Spacer()
                    
                    Text("Break:")
                    TextField("", text: Binding(
                        get: { String(settingsManager.settingsData.pomodoro_break_duration) },
                        set: { settingsManager.settingsData.pomodoro_break_duration = (Int($0) ?? 5)}
                    ))
                        .frame(width: 40)
                        .multilineTextAlignment(.center)
                    Text("min")
                }
                HStack {
                    Text("Long Break:")
                    TextField("", text: Binding(
                        get: { String(settingsManager.settingsData.pomodoro_long_break_duration) },
                        set: { settingsManager.settingsData.pomodoro_long_break_duration = (Int($0) ?? 15)}
                    ))
                        .frame(width: 40)
                        .multilineTextAlignment(.center)
                    Text("min")
                    Spacer()
                    Text("(after 4 sessions)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Divider()
                Text("alarm volume:")
                HStack {
                    Image(systemName: "volume.1.fill")
                    Slider(value: Binding(
                        get: { Double(settingsManager.settingsData.alarm_volume) },
                        set: { settingsManager.settingsData.alarm_volume = Int($0) }
                    ), in: 0...100)
                    Image(systemName: "volume.3.fill")
                }.padding()
                HStack {
                    Text("Test")
                    Image(systemName: "volume.2")
                        .onTapGesture {
                            soundPlayer.playTestSound(volume: settingsManager.settingsData.alarm_volume)
                        }
                        .onHover { isHovered in
                            if isHovered {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                }.padding()
                Divider()
                Toggle("launch at login", isOn: $settingsManager.settingsData.launch_at_login)
                    .padding()
                    .onChange(of: settingsManager.settingsData.launch_at_login) { launchAtLogin in
                        if launchAtLogin {
                            setLaunchAtLogin(enabled: true)
                        } else {
                            setLaunchAtLogin(enabled: false)
                        }
                    }
                Toggle("show floating timer", isOn: $settingsManager.settingsData.show_floating_timer)
                    .padding()
            }
        }
        
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(SettingsManager.instance)
    }
}
