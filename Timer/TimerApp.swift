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

// Floating Timer View Structure
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
            contentRect: NSRect(x: 0, y: 0, width: 160, height: 100),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        floatingTimerWindow.isOpaque = true
        floatingTimerWindow.backgroundColor = NSColor.windowBackgroundColor
        floatingTimerWindow.level = .floating
        floatingTimerWindow.isMovableByWindowBackground = true
        floatingTimerWindow.hasShadow = true
        floatingTimerWindow.isReleasedWhenClosed = false
        
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            floatingTimerWindow.setFrameOrigin(NSPoint(
                x: screenFrame.maxX - 180,
                y: screenFrame.maxY - 120
            ))
        }
        
        // Create persistent hosting view once
        let initialView = FloatingTimerView(
            timeRemaining: 0,
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
    
    func updateFloatingTimer(timeRemaining: Int, isPaused: Bool, isPomodoroMode: Bool, isBreakTime: Bool, pomodoroSession: Int) {
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
            isPaused: isPaused,
            isPomodoroMode: isPomodoroMode,
            isBreakTime: isBreakTime,
            pomodoroSession: pomodoroSession
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
