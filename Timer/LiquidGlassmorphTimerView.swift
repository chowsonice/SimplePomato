import SwiftUI

struct LiquidGlassmorphTimerView: View {
    var timeRemaining: Int
    var maxTime: Int
    var isPaused: Bool
    var isPomodoroMode: Bool
    var isBreakTime: Bool
    var pomodoroSession: Int
    
    @State private var waveOffset1: CGFloat = 0
    @State private var waveOffset2: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    
    private let timerSize: CGFloat = 160
    
    var body: some View {
        ZStack {
            // Glassmorphic Container
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.6),
                                    Color.white.opacity(0.2)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 8)
                .shadow(color: Color.white.opacity(0.3), radius: 1, x: 0, y: -1)
                .frame(width: timerSize, height: timerSize)
            
            // Liquid Fill with Waves
            LiquidFillView(
                progress: CGFloat(timeRemaining) / CGFloat(maxTime),
                waveOffset1: waveOffset1,
                waveOffset2: waveOffset2,
                isBreakTime: isBreakTime,
                isPomodoroMode: isPomodoroMode
            )
            .clipShape(Circle())
            .frame(width: timerSize - 3, height: timerSize - 3)
            
            // Time Display
            VStack(spacing: 2) {
                if isPomodoroMode {
                    Text(isBreakTime ? "☕" : "🍅")
                        .font(.system(size: 16))
                        .opacity(0.9)
                }
                
                Text(formatTime(timeRemaining))
                    .font(.system(size: 18, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                
                if isPomodoroMode {
                    Text("\(pomodoroSession)/4")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
                }
                
                // Percentage display
                Text("\(Int((CGFloat(timeRemaining) / CGFloat(maxTime)) * 100))%")
                    .font(.system(size: 11, weight: .light))
                    .foregroundColor(.white.opacity(0.7))
                    .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
            
            // Pause indicator
            if isPaused {
                Circle()
                    .foregroundColor(.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
                    .offset(y: 35)
            }
            
            // Glass reflection effect
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.white.opacity(0.4), location: 0.0),
                            .init(color: Color.white.opacity(0.1), location: 0.3),
                            .init(color: Color.clear, location: 0.7)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .frame(width: timerSize - 20, height: timerSize - 20)
                .blur(radius: 2)
                .offset(x: -8, y: -8)
        }
        .scaleEffect(pulseScale)
        .onAppear {
            startAnimations()
        }
        .onChange(of: timeRemaining) { newValue in
            if newValue <= 10 && newValue > 0 {
                startUrgencyPulse()
            } else {
                stopUrgencyPulse()
            }
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    
    private func startAnimations() {
        // Wave animation 1
        withAnimation(
            Animation.linear(duration: 3.0)
                .repeatForever(autoreverses: false)
        ) {
            waveOffset1 = 360
        }
        
        // Wave animation 2 (slightly different speed)
        withAnimation(
            Animation.linear(duration: 4.0)
                .repeatForever(autoreverses: false)
        ) {
            waveOffset2 = -360
        }
    }
    
    private func startUrgencyPulse() {
        withAnimation(
            Animation.easeInOut(duration: 0.5)
                .repeatForever(autoreverses: true)
        ) {
            pulseScale = 1.05
        }
    }
    
    private func stopUrgencyPulse() {
        withAnimation(.easeOut(duration: 0.3)) {
            pulseScale = 1.0
        }
    }
}

struct LiquidFillView: View {
    let progress: CGFloat
    let waveOffset1: CGFloat
    let waveOffset2: CGFloat
    let isBreakTime: Bool
    let isPomodoroMode: Bool
    
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let waveHeight: CGFloat = 8
            
            ZStack {
                // Background liquid
                liquidGradient
                    .opacity(0.3)
                
                // Back wave
                WaveShape(
                    offset: waveOffset2,
                    waveHeight: waveHeight * 0.8,
                    progress: progress
                )
                .fill(liquidGradient.opacity(0.6))
                
                // Front wave
                WaveShape(
                    offset: waveOffset1,
                    waveHeight: waveHeight,
                    progress: progress
                )
                .fill(liquidGradient)
            }
        }
    }
    
    private var liquidGradient: LinearGradient {
        if isPomodoroMode && isBreakTime {
            // Break time - blue gradient
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.31, green: 0.96, blue: 0.88), // #4FF4E1
                    Color(red: 0.0, green: 0.62, blue: 0.88)   // #009DE0
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            // Work time - red/orange gradient
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 1.0, green: 0.6, blue: 0.4),   // Lighter orange
                    Color(red: 0.9, green: 0.3, blue: 0.3)    // Deeper red
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

struct WaveShape: Shape {
    var offset: CGFloat
    let waveHeight: CGFloat
    let progress: CGFloat
    
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let liquidHeight = height * progress
        let startY = height - liquidHeight
        
        // Start from bottom left
        path.move(to: CGPoint(x: 0, y: height))
        
        // Draw left edge up to wave start
        path.addLine(to: CGPoint(x: 0, y: startY))
        
        // Draw the wave
        let waveLength: CGFloat = width / 2
        let frequency: CGFloat = 2 * .pi / waveLength
        
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x + offset
            let y = startY + sin(relativeX * frequency) * waveHeight * (1 + (1 - progress) * 0.5)
            
            if x == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        // Complete the shape
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

#Preview {
    ZStack {
        LinearGradient(
            gradient: Gradient(colors: [Color.blue, Color.purple]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        LiquidGlassmorphTimerView(
            timeRemaining: 180,
            maxTime: 300,
            isPaused: false,
            isPomodoroMode: true,
            isBreakTime: false,
            pomodoroSession: 2
        )
    }
}
