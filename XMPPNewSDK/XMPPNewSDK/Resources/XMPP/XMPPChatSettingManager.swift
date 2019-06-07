//
//  XMPPChatSettingManager.swift
//  GoIDD
//
//  Created by ashish on 4/1/19.
//  Copyright © 2019 Goidd. All rights reserved.
//

import UIKit
import CoreData
import XMPPFramework

@objcMembers
class XMPPChatSettingManager: NSObject
{
    //var chatSettings = ChatSettings()
    
    /*--------- initiate shared manager   ------------*/
    class var sharedInstance: XMPPChatSettingManager
    {
        struct Static
        {
            static let instance : XMPPChatSettingManager = XMPPChatSettingManager()
        }
        return Static.instance
    }
}
