//
//  ErrorView.swift
//  JamfConnectLogin
//
//  Created by Bartosz Odrzywolek on 27/03/2019.
//  Copyright © 2019 Jamf. All rights reserved.
//

import Cocoa

class ErrorView: NSView, NibLoadable {

    @IBOutlet weak var errorView: NSView!
    @IBOutlet weak var errorTextField: NSTextField!
    @IBOutlet weak var dismissButton: NSButton!
    @IBOutlet weak var errorBackgroundView: NSView!
    private var defaultFadeDuration: TimeInterval = 0.1
    private var completionHandler: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configureAppearance()
    }
    
    override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        fadeInBackgroundView()
    }
    
    func configureUI(message: String, buttonTitle: String? = nil, fadeDuration: TimeInterval? = nil) {
        errorTextField.stringValue = message
        dismissButton.title = buttonTitle ?? "OK"
        if let fadeDuration = fadeDuration {
            self.defaultFadeDuration = fadeDuration
        }
    }
    
    func add(to view: NSView) {
        guard !isErrorVisible(in: view) else {
            os_log("Attempt to add ErrorView. Deny: view %{public}@ already contains one", log: uiLog, type: .debug, view.debugDescription)
            return
        }
        view.addSubview(self)
        if view.subviews.contains(self) {
            os_log("ErrorView added to main window", log: uiLog, type: .debug)
        } else {
            os_log("ErrorView NOT added to main window", log: uiLog, type: .debug)
        }
        if view.subviews.last == self {
            os_log("ErrorView is LAST subview of main window", log: uiLog, type: .debug)
        }
        if view.subviews.first == self {
            os_log("ErrorView is FIRST subview of main window.", log: uiLog, type: .debug)
        }
        view.setAccessibilityTopLevelUIElement(self)
    }
    
    /* Checks if other instances of ErrorView are already visible */
    func isErrorVisible(in view: NSView) -> Bool {
        for subview in view.subviews {
            if subview.isKind(of: ErrorView.self) {
                os_log("View %{public}@ contains ErrorView instance", log: uiLog, type: .debug, view.debugDescription)
                return true
            }
        }
        return false
    }
    
    func set(completionHandler: (() -> Void)?) {
        self.completionHandler = completionHandler
    }
    
    /* Implemented to disable user interaction with views underneath the error view overlay */
    override func mouseDown(with event: NSEvent) { }
    
    @IBAction func dismiss(_ sender: Any) {
        dismiss()
    }
    
    public func dismiss() {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = defaultFadeDuration
        animator().removeFromSuperview()
        NSAnimationContext.endGrouping()
        completionHandler?()
    }

    private func configureAppearance() {
        errorView.wantsLayer = true
        errorView.layer?.backgroundColor = NSColor.white.cgColor
        errorView.layer?.cornerRadius = 5
        errorView.alphaValue = 1
        
        errorBackgroundView.wantsLayer = true
        errorBackgroundView.layer?.backgroundColor = NSColor.lightGray.cgColor
        errorBackgroundView.alphaValue = 0
    }
    
    private func fadeInBackgroundView() {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.duration = defaultFadeDuration
        errorBackgroundView.animator().alphaValue = 0.7
        NSAnimationContext.endGrouping()
    }
}
