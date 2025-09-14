//
//  ContentView.swift
//  Timer
//
//  Created by Patrick Cunniff on 6/3/23.
//

import SwiftUI
import Foundation

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
    @ObservedObject var timerModel = TimerControlModel.shared

    var body: some View {
        VStack {
            HStack(spacing: 1) {
                ForEach(0..<100) { index in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(index == 100-Int((100*timerModel.timeRemaining/timerModel.maxTime)) ? Color.red : Color.gray.opacity(0.3))
                        .frame(width: index == timerModel.currentTimerPreset ? 2 : 1.5, height: 20)
                }
            }
            
            // Pomodoro status indicator
            if timerModel.isPomodoroMode {
                HStack {
                    HStack(spacing: 4) {
                        if timerModel.isBreakTime {
                            Image(systemName: "cup.and.saucer.fill")
                                .resizable()
                                .frame(width: 16, height: 16)
                                .foregroundColor(.black)
                        } else {
                            Image("tomato")
                                .resizable()
                                .frame(width: 16, height: 16)
                                .foregroundColor(.red)
                        }
                        Text(timerModel.isBreakTime ? "break" : "work")
                            .fontWeight(.medium)
                            .foregroundColor(timerModel.isBreakTime ? .black : .red)
                    }
                    Spacer()
                    HStack(spacing: 6) {
                        ForEach(1...4, id: \.self) { idx in
                            Circle()
                                .fill(idx <= timerModel.pomodoroSession ? Color.red : Color.gray.opacity(0.3))
                                .frame(width: 5, height: 5)
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
            
            HStack(spacing: 1) {
                Group {
                    if timerModel.isPaused {
                        if timerModel.isPomodoroMode {
                            CustomButton(text: "+1m")
                                .onTapGesture {
                                    timerModel.addTimeAndSwitchMode(minutes: 1)
                                }
                            CustomButton(text: "+5m")
                                .onTapGesture {
                                    timerModel.addTimeAndSwitchMode(minutes: 5)
                                }
                            if timerModel.isBreakTime {
                                CustomButton(text: "skip break")
                                    .onTapGesture {
                                        timerModel.skipBreak()
                                    }
                            }
                        } else {
                            CustomButton(text: String(timerModel.settingsManager.settingsData.timer_presets[0]) + "m")
                                .onTapGesture {
                                    timerModel.startRegularTimer(preset: 0)
                                }
                            CustomButton(text: String(timerModel.settingsManager.settingsData.timer_presets[1]) + "m")
                                .onTapGesture {
                                    timerModel.startRegularTimer(preset: 1)
                                }
                            CustomButton(text: String(timerModel.settingsManager.settingsData.timer_presets[2]) + "m")
                                .onTapGesture {
                                    timerModel.startRegularTimer(preset: 2)
                                }
                            CustomIconButton(
                                text: pomodoroButtonText(),
                                iconName: pomodoroIconName()
                            )
                                .onTapGesture {
                                    timerModel.startPomodoroTimer()
                                }
                        }
                    } else {
                        if timerModel.isPomodoroMode {
                            CustomButton(text: "skip").onTapGesture {
                                timerModel.handlePomodoroCompletion()
                            }
                        }
                        CustomButton(text: "cancel").onTapGesture {
                            timerModel.cancelTimer()
                        }
                        CustomButton(text: "restart").onTapGesture {
                            timerModel.restartTimer()
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
                    if timerModel.isPaused {
                        if timerModel.timeRemaining == 0 {
                            CustomButton(text: "stop")
                                .onTapGesture {
                                    timerModel.maxTime = max(timerModel.settingsManager.settingsData.timer_presets[timerModel.currentTimerPreset] * 60, 1)
                                    timerModel.timeRemaining = timerModel.maxTime
                                }
                        } else {
                            CustomButton(text: "start")
                                .onTapGesture {
                                    timerModel.toggleTimer()
                                }
                        }
                    } else {
                        CustomButton(text: "pause")
                            .onTapGesture {
                                timerModel.toggleTimer()
                            }
                    }
                }
                
                Spacer()
                
                Text("\(formatDuration(seconds: timerModel.timeRemaining))")
                    .font(.system(size: 36))
                    .fontWeight(.thin)
            }
            .foregroundColor(.primary)
        }
        .frame(width: 250)
        .padding(.all, 10.0)
        .background(Color.white.opacity(0.6))
        .cornerRadius(10)
        .onAppear {
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("ToggleTimer"),
                object: nil,
                queue: .main
            ) { _ in
                timerModel.toggleTimer()
            }
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name("ToggleTimer"), object: nil)
        }
    }

    private func pomodoroButtonText() -> String {
        if timerModel.isPomodoroMode && !timerModel.isPaused {
            return timerModel.isBreakTime ? "break" : "work"
        }
        return "pomo"
    }

    private func pomodoroIconName() -> String {
        if timerModel.isPomodoroMode && !timerModel.isPaused {
            return timerModel.isBreakTime ? "cup.and.saucer.fill" : "tomato"
        }
        return "tomato"
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environmentObject(SettingsManager.instance)
    }
}

