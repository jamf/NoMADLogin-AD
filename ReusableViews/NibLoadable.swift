//
//  NibLoadable.swift
//  JamfConnectLogin
//
//  Created by Bartosz Odrzywolek on 27/03/2019.
//  Copyright © 2019 Jamf. All rights reserved.
//
import Cocoa

protocol NibName {
    static var nibName: String? { get }
}

extension NibName {
    static var nibName: String? {
        return String(describing: Self.self)
    }
}

protocol NibLoadable: NibName {
    static func createFromNib(in bundle: Bundle) -> Self?
}

extension NibLoadable where Self: NSView {
    static func createFromNib(in bundle: Bundle = Bundle.main) -> Self? {
        guard let nibName = nibName else { return nil }
        var topLevelArray: NSArray? = nil
        bundle.loadNibNamed(NSNib.Name(nibName), owner: self, topLevelObjects: &topLevelArray)
        guard let results = topLevelArray else { return nil }
        let views = Array<Any>(results).filter { $0 is Self }
        return views.last as? Self
    }
}
