//
//  FakeUser.swift
//  NoMADLogin
//
//  Created by Joel Rennich on 9/24/17.
//  Copyright © 2017 Joel Rennich. All rights reserved.
//

import Foundation

// quick mech to login as a pre-determined user, regardless of what you authed as

class FakeUser: NoLoMechanism {
    
    @objc func run() {
        
        //let defaults = UserDefaults.standard
        
        //let name = defaults.string(forKey: "FakeUser") ?? "admin"
        //let password = defaults.string(forKey: "FakePassword") ?? "apple1!"
        
        let name = "admin"
        let password = "apple1!"
        
        // set some contexts
        
        setUserContext(user: name)
        setPassContext(pass: password)
        
        defaults.set(Date(), forKey: "FakeUserRunTime")
        // let them in
        
        allowLogin()
    }
}
