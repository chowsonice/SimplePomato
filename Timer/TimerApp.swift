import SwiftUI

// MARK: - Liquid Glassmorphism Timer View

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
    @State private var animationsEnabled: Bool = true // Performance toggle
    @State private var useSimpleMode: Bool = false // Ultra-performance mode
    @State private var liquidPhysicsEnabled: Bool = true // Disable if buggy
    @StateObject private var liquidPhysics = LiquidPhysicsModel()
    
    private let timerSize: CGFloat = 160
    
    private var liquidGradientColors: (Color, Color) {
        if isPomodoroMode && isBreakTime {
            return (
                Color(red: 0.31, green: 0.96, blue: 0.88), // #4FF4E1
                Color(red: 0.0, green: 0.62, blue: 0.88)   // #009DE0
            )
        } else {
            return (
                Color(red: 1.0, green: 0.6, blue: 0.4),   // Lighter orange
                Color(red: 0.9, green: 0.3, blue: 0.3)    // Deeper red
            )
        }
    }
    
    var body: some View {
        ZStack {
            // Simple glassmorphic container - transparence gérée par NSWindow
            RoundedRectangle(cornerRadius: 20)
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
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
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
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                .frame(width: timerSize, height: timerSize)
            
            // Liquid Fill with Waves - Conditionally rendered for performance
            if !useSimpleMode {
                LiquidFillView(
                    progress: CGFloat(timeRemaining) / CGFloat(max(maxTime, 1)),
                    waveOffset1: waveOffset1,
                    waveOffset2: waveOffset2,
                    isBreakTime: isBreakTime,
                    isPomodoroMode: isPomodoroMode,
                    liquidPhysics: liquidPhysics,
                    physicsEnabled: liquidPhysicsEnabled
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .frame(width: timerSize - 3, height: timerSize - 3)
            } else {
                // Simple fill with curved edge for maximum performance
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                liquidGradientColors.0,
                                liquidGradientColors.1
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .opacity(0.4)
                    )
                    .mask(
                        // Custom shape for curved liquid surface even in simple mode
                        SimpleLiquidShape(
                            progress: CGFloat(timeRemaining) / CGFloat(max(maxTime, 1)),
                            liquidTilt: liquidPhysicsEnabled ? liquidPhysics.liquidTilt : 0
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    )
                    .frame(width: timerSize - 3, height: timerSize - 3)
            }
            
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
                Text("\(Int((CGFloat(timeRemaining) / CGFloat(max(maxTime, 1))) * 100))%")
                    .font(.system(size: 11, weight: .light))
                    .foregroundColor(.white.opacity(0.7))
                    .shadow(color: Color.black.opacity(0.3), radius: 1, x: 0, y: 1)
            }
            
            // Pause indicator
            if isPaused {
                Circle()
                    .foregroundColor(.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
                    .offset(y: 50)
            }
            
            // Glass reflection effect - adjusted for rounded rectangle
            RoundedRectangle(cornerRadius: 15)
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
            // Auto-enable simple mode for better performance and stability
            useSimpleMode = true // Set to false if you want waves
            liquidPhysicsEnabled = false // Disable by default to avoid bugs
            
            if animationsEnabled && !useSimpleMode {
                startAnimations()
            }
        }
        .onTapGesture(count: 3) {
            // Triple-tap to toggle physics (for debugging)
            liquidPhysicsEnabled.toggle()
            if liquidPhysicsEnabled {
                useSimpleMode = false
            }
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
        // Very gentle animations to avoid buggy behavior
        if animationsEnabled && !useSimpleMode {
            withAnimation(
                Animation.linear(duration: 12.0)
                    .repeatForever(autoreverses: false)
            ) {
                waveOffset1 = 120 // Further reduced range
            }
            
            // Even slower second wave
            withAnimation(
                Animation.linear(duration: 16.0)
                    .repeatForever(autoreverses: false)
            ) {
                waveOffset2 = -60 // Much smaller range
            }
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
    let liquidPhysics: LiquidPhysicsModel
    let physicsEnabled: Bool
    
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let waveHeight: CGFloat = 8
            
            ZStack {
                // Background liquid
                liquidGradient
                    .opacity(0.15)
                
                // Back wave
                WaveShape(
                    offset: waveOffset2,
                    waveHeight: waveHeight * 0.8,
                    progress: progress,
                    liquidTilt: physicsEnabled ? liquidPhysics.liquidTilt : 0
                )
                .fill(liquidGradient.opacity(0.35))
                
                // Front wave
                WaveShape(
                    offset: waveOffset1,
                    waveHeight: waveHeight,
                    progress: progress,
                    liquidTilt: physicsEnabled ? liquidPhysics.liquidTilt : 0
                )
                .fill(liquidGradient.opacity(0.55))
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
    let liquidTilt: CGFloat
    
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let liquidHeight = height * progress
        
        // Apply tilt to the liquid surface
        let tiltOffset = liquidTilt * 0.5 // Scale down the tilt effect
        let leftY = height - liquidHeight + tiltOffset
        let rightY = height - liquidHeight - tiltOffset
        
        // Start from bottom left
        path.move(to: CGPoint(x: 0, y: height))
        
        // Draw left edge with slight curve for rectangle
        let edgeCurve: CGFloat = 4 // Small curve at edges
        if leftY > edgeCurve {
            path.addLine(to: CGPoint(x: 0, y: leftY + edgeCurve))
            path.addQuadCurve(
                to: CGPoint(x: edgeCurve, y: leftY),
                control: CGPoint(x: 0, y: leftY)
            )
        } else {
            path.addLine(to: CGPoint(x: 0, y: leftY))
        }
        
        // Draw the wave - simplified for stability
        let waveLength: CGFloat = width
        let frequency: CGFloat = 2 * .pi / waveLength
        let step: CGFloat = 8 // Larger step for better performance and stability
        
        // Start wave from after the left edge
        let waveStartX = max(edgeCurve, 0)
        let waveEndX = width - edgeCurve
        
        for x in stride(from: waveStartX, through: waveEndX, by: step) {
            let relativeX = x + offset
            let progressionX = x / width // 0 to 1 across width
            
            // Simple interpolation for tilt (reduced complexity)
            let tiltedBaseY = leftY + (rightY - leftY) * progressionX
            
            // Simplified wave calculation - reduced amplitude for stability
            let simplifiedWaveHeight = waveHeight * 0.5 // Reduce wave intensity
            let baseWaveY = tiltedBaseY + sin(relativeX * frequency) * simplifiedWaveHeight
            
            // Minimal edge effect to avoid complex calculations
            let y = baseWaveY
            
            if x == waveStartX {
                if leftY > edgeCurve {
                    // Already positioned by edge curve
                } else {
                    path.move(to: CGPoint(x: x, y: y))
                }
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        // Draw right edge with curve and tilt
        if rightY > edgeCurve {
            path.addQuadCurve(
                to: CGPoint(x: width, y: rightY + edgeCurve),
                control: CGPoint(x: width, y: rightY)
            )
            path.addLine(to: CGPoint(x: width, y: height))
        } else {
            path.addLine(to: CGPoint(x: width, y: height))
        }
        
        // Complete the shape
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

struct SimpleLiquidShape: Shape {
    let progress: CGFloat
    let liquidTilt: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let liquidHeight = height * progress
        
        // Apply tilt to the liquid surface
        let tiltOffset = liquidTilt * 0.5 // Scale down for rectangle
        let leftY = height - liquidHeight + tiltOffset
        let rightY = height - liquidHeight - tiltOffset
        
        // Start from bottom left
        path.move(to: CGPoint(x: 0, y: height))
        
        // Left edge
        path.addLine(to: CGPoint(x: 0, y: leftY))
        
        // Top edge with tilt
        path.addLine(to: CGPoint(x: width, y: rightY))
        
        // Right edge
        path.addLine(to: CGPoint(x: width, y: height))
        
        // Bottom edge
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}

// MARK: - Physics Model

class LiquidPhysicsModel: ObservableObject {
    @Published var liquidTilt: CGFloat = 0
    
    private var windowObserver: NSObjectProtocol?
    private var lastMoveTime: Date = Date()
    private var animationTimer: Timer?
    
    init() {
        setupWindowObserver()
    }
    
    deinit {
        if let observer = windowObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        animationTimer?.invalidate()
    }
    
    private func setupWindowObserver() {
        windowObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.simulateWindowMovement()
        }
    }
    
    private func simulateWindowMovement() {
        // Throttle rapid movements to prevent buggy behavior
        let now = Date()
        guard now.timeIntervalSince(lastMoveTime) > 0.1 else { return }
        lastMoveTime = now
        
        // Cancel any existing animation
        animationTimer?.invalidate()
        
        // Simple, predictable tilt based on direction
        let tiltAmount: CGFloat = 3.0 // Reduced from random -8...8
        
        withAnimation(.easeOut(duration: 0.2)) {
            liquidTilt = tiltAmount
        }
        
        // Reset with delay - prevent overlapping animations
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                self?.liquidTilt = 0
            }
        }
    }
}

// MARK: - Main App

@main
struct UtilityApp: App {
    
    @State private var timeRemaining: Int = 300
    @State private var appearanceObserver: NSObjectProtocol?

    var body: some Scene {
        MenuBarExtra {
            MainView(timeRemaining: $timeRemaining)
        } label: {
            Image(nsImage: createMenuBarImage(text: formatDuration(seconds: timeRemaining)))
                .onAppear {
                    setupAppearanceObserver()
                }
                .onDisappear {
                    removeAppearanceObserver()
                }
        }
        .menuBarExtraStyle(.window)
        .windowStyle(HiddenTitleBarWindowStyle())
    }
    
    private func setupAppearanceObserver() {
        appearanceObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Force une mise à jour de l'image quand les paramètres d'écran changent
            timeRemaining = timeRemaining // Trigger une mise à jour
        }
    }
    
    private func removeAppearanceObserver() {
        if let observer = appearanceObserver {
            NotificationCenter.default.removeObserver(observer)
            appearanceObserver = nil
        }
    }
    
    private func createMenuBarImage(text: String) -> NSImage {
        let font = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.black // Utilisera le noir pour l'image template
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedString.size()
        
        // Ajouter du padding
        let padding: CGFloat = 6
        let imageSize = CGSize(
            width: textSize.width + padding * 2,
            height: textSize.height + padding
        )
        
        // Créer une nouvelle image à chaque fois pour éviter la mise en cache
        let image = NSImage(size: imageSize)
        image.cacheMode = .never // Éviter la mise en cache
        
        image.lockFocus()
        
        // Dessiner le rectangle
        let rect = NSRect(origin: .zero, size: imageSize)
        let roundedRect = NSBezierPath(roundedRect: rect.insetBy(dx: 1, dy: 1), xRadius: 4, yRadius: 4)
        NSColor.black.setStroke() // Utilisera le noir pour l'image template
        roundedRect.lineWidth = 1.1
        roundedRect.stroke()
        
        // Dessiner le texte centré
        let textRect = NSRect(
            x: padding,
            y: (imageSize.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        attributedString.draw(in: textRect)
        
        image.unlockFocus()
        
        // IMPORTANT: Marquer comme image template pour adaptation automatique
        image.isTemplate = true
        
        return image
    }
}

// Note: FloatingTimerView is now replaced by LiquidGlassmorphTimerView


import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    static let shared = AppDelegate()
    
    var aboutWindow: NSWindow!
    var settingsWindow: NSWindow!
    var floatingTimerWindow: NSWindow!
    var hostingView: NSHostingView<LiquidGlassmorphTimerView>!
    
    private var settingsManager = SettingsManager.instance
    private var spaceObserver: NSObjectProtocol?
    
    override init() {
        super.init()
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        createAboutWindow()
        createSettingsWindow()
        // Ne pas créer la fenêtre flottante ici - elle sera créée à la demande
        
        // Observer pour surveiller les changements de paramètres
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsChanged),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
        
        // Observer pour surveiller les changements d'espaces de travail
        setupSpaceObserver()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Nettoyer les observateurs et fenêtres
        NotificationCenter.default.removeObserver(self)
        removeSpaceObserver()
        closeFloatingTimer()
    }
    
    @objc private func settingsChanged() {
        DispatchQueue.main.async {
            if self.settingsManager.settingsData.show_floating_timer {
                // Créer la fenêtre seulement si elle n'existe pas
                if self.floatingTimerWindow == nil {
                    self.createFloatingTimerWindow()
                }
                self.showFloatingTimer()
            } else {
                self.hideFloatingTimer()
            }
        }
    }
    
    private func setupSpaceObserver() {
        spaceObserver = NotificationCenter.default.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.ensureFloatingTimerVisibility()
        }
    }
    
    private func removeSpaceObserver() {
        if let observer = spaceObserver {
            NotificationCenter.default.removeObserver(observer)
            spaceObserver = nil
        }
    }
    
    private func ensureFloatingTimerVisibility() {
        guard let floatingTimerWindow = floatingTimerWindow,
              settingsManager.settingsData.show_floating_timer else { return }
        
        // Rendre la fenêtre visible sur l'espace actuel
        floatingTimerWindow.orderFront(nil)
        
        // S'assurer que les paramètres de comportement sont corrects
        floatingTimerWindow.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        floatingTimerWindow.level = .floating
    }
    
    func createAboutWindow() {
        aboutWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 270),
            styleMask: [.borderless, .closable],
            backing: .buffered,
            defer: false
        )
        
        aboutWindow.titleVisibility = .hidden
        aboutWindow.isMovableByWindowBackground = true
        
        let aboutView = AboutView(closeWindow: closeCocoaWindow)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        aboutWindow.contentView = NSHostingView(rootView: aboutView)
        aboutWindow.center()
        aboutWindow.isReleasedWhenClosed = false
    }
    
    func createSettingsWindow() {
        settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 270, height: 290),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        settingsWindow.titleVisibility = .hidden
        settingsWindow.isMovableByWindowBackground = true

        let settingsView = SettingsView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        settingsWindow.contentView = NSHostingView(rootView: settingsView)
        settingsWindow.center()
        settingsWindow.isReleasedWhenClosed = false
    }
    
    func createFloatingTimerWindow() {
        self.floatingTimerWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 180, height: 180),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Configuration pour transparence native
        floatingTimerWindow.isOpaque = false
        floatingTimerWindow.backgroundColor = NSColor(calibratedHue: 0.0, saturation: 0.0, brightness: 0.0, alpha: 0.0)
        floatingTimerWindow.level = .floating
        floatingTimerWindow.isMovableByWindowBackground = true
        floatingTimerWindow.hasShadow = false // Disable system shadow, we have custom shadow
        floatingTimerWindow.isReleasedWhenClosed = false
        
        // Assurer que la fenêtre apparaît sur tous les bureaux/espaces
        floatingTimerWindow.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            floatingTimerWindow.setFrameOrigin(NSPoint(
                x: screenFrame.maxX - 200,
                y: screenFrame.maxY - 200
            ))
        }
        
        // Create persistent hosting view once
        let initialView = LiquidGlassmorphTimerView(
            timeRemaining: 300,
            maxTime: 300,
            isPaused: false,
            isPomodoroMode: false,
            isBreakTime: false,
            pomodoroSession: 0
        )
        hostingView = NSHostingView(rootView: initialView)
        floatingTimerWindow.contentView = hostingView
    }
    
    func showFloatingTimer() {
        guard floatingTimerWindow != nil else { return }
        
        // S'assurer que la fenêtre a les bonnes propriétés pour rester sur tous les espaces
        floatingTimerWindow.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        floatingTimerWindow.level = .floating
        floatingTimerWindow.orderFront(nil)
    }
    
    func hideFloatingTimer() {
        guard floatingTimerWindow != nil else { return }
        floatingTimerWindow.orderOut(nil)
    }
    
    func closeFloatingTimer() {
        if floatingTimerWindow != nil {
            floatingTimerWindow.close()
            floatingTimerWindow = nil
        }
        hostingView = nil
    }
    
    func updateFloatingTimer(timeRemaining: Int, maxTime: Int, isPaused: Bool, isPomodoroMode: Bool, isBreakTime: Bool, pomodoroSession: Int) {
        guard settingsManager.settingsData.show_floating_timer else {
            hideFloatingTimer()
            return
        }
        
        // Créer la fenêtre seulement si elle n'existe pas
        if floatingTimerWindow == nil || hostingView == nil {
            self.createFloatingTimerWindow()
        }
        
        guard hostingView != nil else { return }
        
        // Update rootView with reduced frequency to avoid excessive updates
        DispatchQueue.main.async {
            self.hostingView.rootView = LiquidGlassmorphTimerView(
                timeRemaining: timeRemaining,
                maxTime: maxTime,
                isPaused: isPaused,
                isPomodoroMode: isPomodoroMode,
                isBreakTime: isBreakTime,
                pomodoroSession: pomodoroSession
            )
        }
        
        if !floatingTimerWindow.isVisible {
            showFloatingTimer()
        }
    }

    func openCocoaWindow(id: String) {
        switch id {
        case "about":
            aboutWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        case "settings":
            createSettingsWindow()
            settingsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        default:
            break
        }
    }
    
    func closeCocoaWindow(id: String) {
        switch id {
        case "about":
            aboutWindow.close()
        case "settings":
            settingsWindow.close()
        default:
            break
        }
    }
}
