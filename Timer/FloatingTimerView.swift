//
//  FloatingTimerView.swift
//  Timer
//
//  Created by Assistant on 8/14/25.
//

import SwiftUI

struct FloatingTimerView: View {
    var timeRemaining: Int
    var isPaused: Bool
    var isPomodoroMode: Bool
    var isBreakTime: Bool
    var pomodoroSession: Int
    
    var body: some View {
        VStack(spacing: 8) {
            if isPomodoroMode {
                HStack {
                    Text(isBreakTime ? "☕" : "🍅")
                        .font(.title2)
                    Text("Session \(pomodoroSession)/4")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Text(formatDuration(seconds: timeRemaining))
                .font(.system(size: 24, weight: .medium, design: .monospaced))
                .foregroundColor(.primary)
            Circle()
                .foregroundColor(isPaused ? Color.gray : (isPomodoroMode && isBreakTime ? Color.blue : Color.red))
                .frame(width: 8, height: 8)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .foregroundColor(Color(NSColor.windowBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct FloatingTimerView_Previews: PreviewProvider {
    static var previews: some View {
        FloatingTimerView(
            timeRemaining: 1500,
            isPaused: false,
            isPomodoroMode: true,
            isBreakTime: false,
            pomodoroSession: 2
        )
    }
}
