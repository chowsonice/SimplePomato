import SwiftUI

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

    WindowGroup("Floating Timer") {
        FloatingTimerView(
            timeRemaining: timeRemaining,
            totalTime: 300,
            isPaused: true,
            isPomodoroMode: false,
            isBreakTime: false,
            pomodoroSession: 1,
            workDuration: 25,
            breakDuration: 5,
            longBreakDuration: 15
        )
    }
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

// Helper function for time formatting
func formatTimeComponents(seconds: Int) -> (minutes: String, seconds: String) {
    let mins = seconds / 60
    let secs = seconds % 60
    return (String(format: "%02d", mins), String(format: "%02d", secs))
}

// Floating Timer View Structure
struct FloatingTimerView: View {
    private static let backgroundColor = Color(red: 0.902, green: 0.902, blue: 0.902).opacity(0.7)
    var timeRemaining: Int
    var totalTime: Int
    var isPaused: Bool
    var isPomodoroMode: Bool
    var isBreakTime: Bool
    var pomodoroSession: Int
    var workDuration: Int
    var breakDuration: Int
    var longBreakDuration: Int

    // Couleurs selon le design spécifié - ajustées pour correspondre à l'image
    private var progressColor: Color {
        if isPomodoroMode {
            return isBreakTime ? Color(red: 0.7, green: 0.9, blue: 0.3) : Color(red: 0.8, green: 0.4, blue: 0.8) // Vert pour pause, Violet pour travail
        } else {
            return Color(red: 0.23, green: 0.51, blue: 0.98) // Bleu par défaut
        }
    }
    
    private var modeLabel: String {
        if isPomodoroMode {
            return isBreakTime ? "BREAK" : "FOCUS"
        } else {
            return "TIMER"
        }
    }
    
    private var progress: Double {
        guard totalTime > 0 else { return 0 }
        return max(0, min(1, Double(totalTime - timeRemaining) / Double(totalTime)))
    }

    private var pomodoroProgress: Double {
        guard totalTime > 0 else { return 0 }
        return max(0, min(1, Double(timeRemaining) / Double(totalTime)))
    }
    
    // Calculer les segments pour le mode Pomodoro
    private func pomodoroSegments() -> (workProgress: Double, breakProgress: Double) {
        if !isPomodoroMode { return (0, 0) }
        
        let total = Double(workDuration + breakDuration)
        let workPortion: Double = total > 0 ? Double(workDuration) / total : 0
        let breakPortion: Double = total > 0 ? Double(breakDuration) / total : 0

        if isBreakTime {
            // En pause : montrer le travail complété et la progression de la pause
            return (workPortion - 0.04, progress * (breakPortion - 0.08))
        } else {
            // En travail : montrer seulement la progression du travail
            return (0.04 + progress * (workPortion - 0.08), 0)
        }
    }
    
    var body: some View {
        ZStack {
            // Fond harmonisé avec MainView
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0.902, green: 0.902, blue: 0.902).opacity(0.85))
                .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 2)
                VStack(spacing: 12) {
                    // Label du mode (FOCUS/BREAK/TIMER)
            Text(modeLabel)
                .font(.system(size: 13))
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .tracking(0.8)
                        
                // Indicateur de progression circulaire
                ZStack {
                    // Cercle de fond (track) - plus épais comme dans l'image

                    if isPomodoroMode {
                        // Mode Pomodoro : afficher les segments de travail et de pause
                        let workColor = Color(red: 0.8, green: 0.4, blue: 0.8) // Violet pour travail
                        let breakColor = Color(red: 0.7, green: 0.9, blue: 0.3) // Vert pour pause
                        let segments = pomodoroSegments()

                        let total = Double(workDuration + breakDuration)
                        let workPortion: Double = total > 0 ? Double(workDuration) / total : 0
                        let breakPortion: Double = total > 0 ? Double(breakDuration) / total : 0

                        Circle()
                            .trim(from: 0.04, to: workPortion - 0.04)
                            .stroke(Color(red: 0.73, green: 0.73, blue: 0.73), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .frame(width: 90, height: 90)
                            .rotationEffect(.degrees(-90))

                        Circle()
                            .trim(from: workPortion + 0.04, to: 1 - 0.04)
                            .stroke(Color(red: 0.73, green: 0.73, blue: 0.73), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .frame(width: 90, height: 90)
                            .rotationEffect(.degrees(-90))
                        
                        // Segment de travail (violet) - commence au début
                        if segments.workProgress > 0 {
                            Circle()
                                .trim(from: 0.04, to: segments.workProgress)
                                .stroke(workColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                .frame(width: 90, height: 90)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 0.5), value: segments.workProgress)
                        }
                        
                        // Segment de pause (vert) - commence après le travail
                        if segments.breakProgress > 0 {
                            Circle()
                                .trim(from: workPortion + 0.04, to: workPortion + 0.04 + segments.breakProgress)
                                .stroke(breakColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                .frame(width: 90, height: 90)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 0.5), value: segments.breakProgress)
                        }
                    } else {
                        Circle()
                            .stroke(Color(red: 0.15, green: 0.15, blue: 0.15), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .frame(width: 90, height: 90)

                        // Mode timer normal
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(progressColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .frame(width: 90, height: 90)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.5), value: progress)
                    }
                    
                    // Indicateur de fin de progression (petit point blanc)
                    if progress > 0 {
                        let total = Double(workDuration + breakDuration)
                        let workPortion: Double = total > 0 ? Double(workDuration) / total : 0
                        let breakPortion: Double = total > 0 ? Double(breakDuration) / total : 0
                        
                        let dotProgress: Double = isPomodoroMode ? 
                            (isBreakTime ? workPortion + 0.04 + (progress * (breakPortion - 0.08)) : 0.04 + progress * (workPortion - 0.08)) :
                            progress
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                            .offset(y: -45)
                            .rotationEffect(.degrees(dotProgress * 360))
                            .animation(.easeInOut(duration: 0.5), value: dotProgress)
                    }
                    
                    // Temps restant au centre avec formatage amélioré
VStack(spacing: 2) {
    let timeComponents = formatTimeComponents(seconds: timeRemaining)
    HStack(alignment: .lastTextBaseline, spacing: 2) {
Text(timeComponents.minutes)
    .font(.system(size: 28))
    .fontWeight(.thin)
    .foregroundColor(.primary)
Text("m")
    .font(.system(size: 12))
    .fontWeight(.medium)
    .foregroundColor(.primary)
    }
    HStack(alignment: .lastTextBaseline, spacing: 2) {
Text(timeComponents.seconds)
    .font(.system(size: 28))
    .fontWeight(.thin)
    .foregroundColor(.primary)
Text("s")
    .font(.system(size: 12))
    .fontWeight(.medium)
    .foregroundColor(.primary)
    }
}
                }
                
                // Bouton d'action - style de l'image
                Button(action: {
                    // Action sera gérée par l'AppDelegate
                    NotificationCenter.default.post(name: NSNotification.Name("ToggleTimer"), object: nil)
                }) {
                    ZStack {
                        Circle()
                            .fill(progressColor)
                            .frame(width: 36, height: 36)
                            .shadow(color: progressColor.opacity(0.3), radius: 4, x: 0, y: 2)
                        
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 0.2), value: isPaused)
            }
            .padding(.all, 10.0)
        }
    .frame(width: 250)
    }
}


import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    static let shared = AppDelegate()
    
    var aboutWindow: NSWindow!
    var settingsWindow: NSWindow!
    var floatingTimerWindow: NSWindow!
    var hostingView: NSHostingView<FloatingTimerView>!
    
    private var settingsManager = SettingsManager.instance
    
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
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Nettoyer les observateurs et fenêtres
        NotificationCenter.default.removeObserver(self)
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
            contentRect: NSRect(x: 0, y: 0, width: 140, height: 180),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        floatingTimerWindow.isOpaque = false
        floatingTimerWindow.backgroundColor = NSColor.clear
        floatingTimerWindow.level = .floating
        floatingTimerWindow.isMovableByWindowBackground = true
        floatingTimerWindow.hasShadow = false
        floatingTimerWindow.isReleasedWhenClosed = false
        
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            floatingTimerWindow.setFrameOrigin(NSPoint(
                x: screenFrame.maxX - 160,
                y: screenFrame.maxY - 200
            ))
        }
        
        // Create persistent hosting view once
        let initialView = FloatingTimerView(
            timeRemaining: 0,
            totalTime: 1,
            isPaused: false,
            isPomodoroMode: false,
            isBreakTime: false,
            pomodoroSession: 0,
            workDuration: 25,
            breakDuration: 5,
            longBreakDuration: 15
        )
        hostingView = NSHostingView(rootView: initialView)
        floatingTimerWindow.contentView = hostingView
    }
    
    func showFloatingTimer() {
        guard floatingTimerWindow != nil else { return }
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
    
    func updateFloatingTimer(timeRemaining: Int, totalTime: Int, isPaused: Bool, isPomodoroMode: Bool, isBreakTime: Bool, pomodoroSession: Int, workDuration: Int, breakDuration: Int, longBreakDuration: Int) {
        guard settingsManager.settingsData.show_floating_timer else {
            hideFloatingTimer()
            return
        }
        
        // Créer la fenêtre seulement si elle n'existe pas
        if floatingTimerWindow == nil || hostingView == nil {
            self.createFloatingTimerWindow()
        }
        
        guard hostingView != nil else { return }
        
        // Update rootView instead of creating a new hosting view each time
        hostingView.rootView = FloatingTimerView(
            timeRemaining: timeRemaining,
            totalTime: totalTime,
            isPaused: isPaused,
            isPomodoroMode: isPomodoroMode,
            isBreakTime: isBreakTime,
            pomodoroSession: pomodoroSession,
            workDuration: workDuration,
            breakDuration: breakDuration,
            longBreakDuration: longBreakDuration
        )
        
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
