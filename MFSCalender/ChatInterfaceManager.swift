//
//  ChatInterfaceManager.swift
//  MFSMobile
//
//  Created by 戴元平 on 5/11/19.
//  Copyright © 2019 David. All rights reserved.
//

import UIKit
import ChatSDK

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
    
}
