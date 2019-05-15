//
//  ChatInterfaceManager.swift
//  MFSMobile
//
//  Created by 戴元平 on 5/11/19.
//  Copyright © 2019 David. All rights reserved.
//

import UIKit
import ChatSDK
import SCLAlertView

class MyAppInterfaceAdapter: BDefaultInterfaceAdapter {
    
    override func chatViewController(with thread: PThread!) -> UIViewController! {
        let chatViewController = MyChatViewController(thread: thread)!
        return chatViewController
    }
}

class MyProfileViewController: BProfileTableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
}

class MyChatViewController: BChatViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel.textColor = UIColor.white
    }
    
    override func setMessageFlagged(_ message: PElmMessage!, isFlagged flagged: Bool) -> RXPromise! {
        if flagged {
            return BChatSDK.moderation()!.unflagMessage(message.entityID())
        } else {
            let flagNotice = SCLAlertView()
            flagNotice.showInfo("Success", subTitle: "You have successfully flagged the message! We will process this report as soon as possible.", animationStyle: .bottomToTop)
            return BChatSDK.moderation()!.flagMessage(message.entityID())
        }
    }
}
