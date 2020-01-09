//
//  NonBleedingView.swift
//  JamfConnectLogin
//
//  Created by Adrian Kubisztal on 22/07/2019.
//  Copyright © 2019 Jamf. All rights reserved.
//

import Foundation
import Cocoa

class NonBleedingView : NSView {
    // In order to prevent a NSView from bleeding it's mouse events to the parent, one must implement the empty methods.
    override func mouseDown(with event: NSEvent) {}

    override func mouseDragged(with event: NSEvent) {}

    override func mouseUp(with event: NSEvent) {}
}
