//
//  Source.swift
//  XMPPNewSDK
//
//  Created by ashish on 5/30/19.
//  Copyright © 2019 Capanicus. All rights reserved.
//

import Foundation
import XMPPFramework

public class Service
{
    private init() {}
    
    public static func FirstMethod() -> String
    {
        return "Project is working"
    }
    
    public static func LoginAndAuthenticateWith(username: String, password: String)
    {
        XMPPConnectionManager.shared()?.authenticateUserWIthUSerName(username, withPassword: password)
    }
}

