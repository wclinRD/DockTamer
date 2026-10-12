import Cocoa
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {

    var statusItem: NSStatusItem!
    var menu: NSMenu!
    var toggleItem: NSMenuItem!
    var launchAtLoginItem: NSMenuItem!
    var permissionItem: NSMenuItem!
    
    // Timer para verificar si el usuario aprobó en Preferencias del Sistema
    var permissionTimer: Timer?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupMenuBar()
        checkAndRequestAccessibilityPermissions()
    }

    func setupMenuBar() {
        // VariableLength para que se adapte al ícono
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // Estilo Apple nativo pero con gráficos detallados generados dinámicamente
            button.image = NSImage.macDockMenuBarIcon
        }

        menu = NSMenu()
        
        toggleItem = NSMenuItem(title: NSLocalizedString("Menu.ToggleFeature.Disabled", comment: ""), action: #selector(toggleFeature), keyEquivalent: "")
        menu.addItem(toggleItem)
        
        launchAtLoginItem = NSMenuItem(title: NSLocalizedString("Menu.LaunchAtLogin", comment: ""), action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLoginItem.state = isLaunchAtLogin() ? .on : .off
        menu.addItem(launchAtLoginItem)
        
        permissionItem = NSMenuItem(title: NSLocalizedString("Permission.Status.Evaluating", comment: ""), action: #selector(requestPermissionsManual), keyEquivalent: "")
        menu.addItem(permissionItem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: NSLocalizedString("Menu.Quit", comment: ""), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        // El retraso al asignar el menú evita el warning de "_NSDetectedLayoutRecursion" 
        // común en macOS 13+ al inicializar un NSStatusItem.
        DispatchQueue.main.async {
            self.statusItem.menu = self.menu
        }
    }
    
    @objc func toggleFeature() {
        DockClickMonitor.shared.isEnabled.toggle()
        toggleItem.title = DockClickMonitor.shared.isEnabled ? NSLocalizedString("Menu.ToggleFeature.Disabled", comment: "") : NSLocalizedString("Menu.ToggleFeature.Enabled", comment: "")
    }
    
    @objc func toggleLaunchAtLogin() {
        let isEnabled = launchAtLoginItem.state == .on
        setLaunchAtLogin(!isEnabled)
        launchAtLoginItem.state = isLaunchAtLogin() ? .on : .off
    }
    
    func isLaunchAtLogin() -> Bool {
        return SMAppService.mainApp.status == .enabled
    }
    
    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch let nsError as NSError {
            let errorCode = nsError.code
            
            // SMAppService error codes:
            // kSMErrorAlreadyRegistered = -1
            // kSMErrorJobNotFound = -2
            // kSMErrorRequiresApproval = -3
            // kSMErrorNotAllowed = -4
            
            switch errorCode {
            case -1: // Already registered
                // Already registered, this is fine when enabling
                break
            case -2: // Job not found
                // Not found, this is fine when disabling
                break
            case -3: // Requires approval
                // Need user approval to add to login items
                showLoginItemApprovalAlert()
            case -4: // Not allowed
                print("Launch at login is not allowed. Please ensure the app is signed and has a hardened runtime.")
            default:
                print("Failed to update launch at login setting: \(nsError.localizedDescription)")
            }
        } catch {
            print("Failed to update launch at login setting: \(error)")
        }
    }
    
    private func showLoginItemApprovalAlert() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("LoginItem.Approval.Title", comment: "")
        alert.informativeText = NSLocalizedString("LoginItem.Approval.Message", comment: "")
        alert.alertStyle = .informational
        alert.addButton(withTitle: NSLocalizedString("LoginItem.Approval.OpenSettings", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("LoginItem.Approval.Cancel", comment: ""))
        
        NSApp.activate(ignoringOtherApps: true)
        
        if alert.runModal() == .alertFirstButtonReturn {
            // Open System Settings to Login Items
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.general?LoginItems") {
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    func checkAndRequestAccessibilityPermissions() {
        // La opción Prompt lanza la alerta nativa del sistema si el permiso no está otorgado
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let isTrusted = AXIsProcessTrustedWithOptions(options)
        
        updatePermissionUI(granted: isTrusted)
        
        if isTrusted {
            DockClickMonitor.shared.start()
            AppActivationMonitor.shared.start()
        } else {
            showPermissionAlert()
            
            // Iniciar un timer (polling) para arrancar la app automáticamente en cuanto el usuario otorgue el permiso de Privacidad
            permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] timer in
                let granted = AXIsProcessTrusted()
                self?.updatePermissionUI(granted: granted)
                
                if granted {
                    DockClickMonitor.shared.start()
                    AppActivationMonitor.shared.start()
                    timer.invalidate()
                }
            }
        }
    }
    
    func updatePermissionUI(granted: Bool) {
        permissionItem.title = granted ? NSLocalizedString("Permission.Status.Granted", comment: "") : NSLocalizedString("Permission.Status.Denied", comment: "")
        // Si está concedido ya no necesitamos darle clic
        permissionItem.action = granted ? nil : #selector(requestPermissionsManual)
    }
    
    @objc func requestPermissionsManual() {
        // URL universal en macOS modernos para abrir Privacidad > Accesibilidad
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Permission.Alert.Title", comment: "")
        alert.informativeText = NSLocalizedString("Permission.Alert.Message", comment: "")
        alert.alertStyle = .warning
        alert.addButton(withTitle: NSLocalizedString("Permission.Alert.OpenSettings", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Permission.Alert.Later", comment: ""))
        
        // Elevar la alerta a primer plano para que el usuario la vea, al no tener ventana normal
        NSApp.activate(ignoringOtherApps: true)
        
        if alert.runModal() == .alertFirstButtonReturn {
            requestPermissionsManual()
        }
    }
}

extension NSImage {
    /// Genera dinámicamente un detallado icono de la barra de menú simulando el diseño de utilidad de Apple
    static var macDockMenuBarIcon: NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            NSColor.black.set()
            
            // 1. Dibujar el marco exterior de la ventana (Rectángulo con esquinas redondeadas)
            let windowRect = NSRect(x: 3, y: 6.5, width: 12, height: 7.5)
            let windowPath = NSBezierPath(roundedRect: windowRect, xRadius: 1.5, yRadius: 1.5)
            windowPath.lineWidth = 1.2
            windowPath.stroke()
            
            // 2. Dibujar la barra de título pequeña de la ventana
            let titleBarLine = NSBezierPath()
            titleBarLine.move(to: NSPoint(x: 3, y: 11.5))
            titleBarLine.line(to: NSPoint(x: 15, y: 11.5))
            titleBarLine.lineWidth = 1.0
            titleBarLine.stroke()
            
            // 3. Dibujar "botón" en la barra de título (simulando los traffic lights de macOS)
            let dotRect = NSRect(x: 4.5, y: 12.2, width: 1.0, height: 1.0)
            let dotPath = NSBezierPath(ovalIn: dotRect)
            dotPath.fill()
            
            // 4. Dibujar el Dock (rectángulo grueso en la base)
            let dockRect = NSRect(x: 4, y: 2.5, width: 10, height: 2.0)
            let dockPath = NSBezierPath(roundedRect: dockRect, xRadius: 1, yRadius: 1)
            dockPath.fill()
            
            // 5. Dibujar una flecha central empujando hacia el dock
            let arrowPath = NSBezierPath()
            arrowPath.lineWidth = 1.2
            arrowPath.lineCapStyle = .round
            arrowPath.lineJoinStyle = .round
            
            // Tronco de la flecha cruzando desde el centro al dock
            arrowPath.move(to: NSPoint(x: 9, y: 9.5))
            arrowPath.line(to: NSPoint(x: 9, y: 5))
            
            // Punta inferior de la flecha
            arrowPath.move(to: NSPoint(x: 7.0, y: 6.8))
            arrowPath.line(to: NSPoint(x: 9, y: 5))
            arrowPath.line(to: NSPoint(x: 11.0, y: 6.8))
            
            arrowPath.stroke()
            
            return true
        }
        
        image.isTemplate = true
        return image
    }
}
