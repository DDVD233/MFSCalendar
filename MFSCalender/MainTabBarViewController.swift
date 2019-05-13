//
//  MainTabBarViewController.swift
//  MFSMobile
//
//  Created by 戴元平 on 5/13/19.
//  Copyright © 2019 David. All rights reserved.
//

import UIKit
import NotificationCenter
import ChatSDK

class MainTabBarViewController: UITabBarController, UITabBarControllerDelegate {
    let bMessagesBadgeValueKey = "bMessagesBadgeValueKey"
    let indexOfPrivateThread = 3
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: bNotificationBadgeUpdated), object: nil, queue: nil) { (notification) in
            DispatchQueue.main.async {
                self.updateBadge()
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: bNotificationMessageRemoved), object: nil, queue: nil) { (notification) in
            DispatchQueue.main.async {
                self.updateBadge()
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: bNotificationThreadRead), object: nil, queue: nil) { (notification) in
            DispatchQueue.main.async {
                self.updateBadge()
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: bNotificationThreadDeleted), object: nil, queue: nil) { (notification) in
            DispatchQueue.main.async {
                self.updateBadge()
            }
        }
        
//        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: bNotificationPresentChatView), object: nil, queue: nil) { (notification) in
//            DispatchQueue.main.async {
//                if BChatSDK.config()!.shouldOpenChatWhenPushNotificationClicked {
//                    if !BChatSDK.config()!.shouldOpenChatWhenPushNotificationClickedOnlyIfTabBarVisible || (canUpdateView(viewController: self)) {
//                        if let thread = notification.userInfo?[bNotificationPresentChatView_PThread] as? PThread {
//                            self.presentChatViewWithThread(thread: thread)
//                        }
//                    }
//                }
//            }
//        }
        
        let badge = UserDefaults.standard.integer(forKey: bMessagesBadgeValueKey)
        self.setPrivateThreadsbadge(badge: badge)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateBadge()
        BChatSDK.core()!.save()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Handle push notifications - open the relevant chat
        if let action = BChatSDK.shared()?.pushQueue()?.tryFirst() {
            if action.type == bPushActionTypeOpenThread {
                BChatSDK.shared()!.pushQueue()!.popFirst()
                if let threadEntityID = action.payload[bPushThreadEntityID] as? String {
                    if let thread = BChatSDK.db()!.fetchOrCreateEntity(withID: threadEntityID , withType: bThreadEntity) as? PThread {
                        presentChatViewWithThread(thread: thread)
                    }
                }
            }
        }
        
        self.updateBadge()
    }
    
    // If the user changes tab they must be online
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        BChatSDK.core()?.setUserOnline()
        BChatSDK.core()?.save()
        if let nav = viewController as? UINavigationController {
            // Should we enable or disable local notifications? We want to show them on every tab that isn't the thread view
            let showNotification = !(nav.viewControllers.first?.isEqual(BChatSDK.ui()!.privateThreadsViewController()) ?? true) || !(nav.viewControllers.first?.isEqual(ChatViewController()) ?? true)
            BChatSDK.ui()!.setShowLocalNotifications(showNotification)
        }
        
        BChatSDK.ui()!.setShowLocalNotifications(false)
    }
    
    func presentChatViewWithThread(thread: PThread) {
        self.selectedIndex = indexOfPrivateThread
        
        // Reset navigation stack
        for nav in self.viewControllers ?? [UIViewController]() {
            if let navObj = nav as? UINavigationController {
                if let firstVC = navObj.viewControllers.first {
                    navObj.setViewControllers([firstVC], animated: false)
                }
            }
        }
        
        if let navigationControllerAtIndex = self.viewControllers?[indexOfPrivateThread] as? UINavigationController, let chatViewController = MyChatViewController(thread: thread) { navigationControllerAtIndex.pushViewController(chatViewController, animated: true)
        }
    }
    
    func updateBadge() {
        let privateThreadsMessageCount = unreadMessagesCount(type: bThreadFilterPrivate)
        self.setPrivateThreadsbadge(badge: privateThreadsMessageCount)
        
        BChatSDK.core()?.save()
    }
    
    func unreadMessagesCount(type: bThreadType) -> Int {
        var i = 0
        let threads = BChatSDK.core()!.threads(with: type) ?? [Any]()
        for thread in threads {
            guard let threadObj = thread as? PThread else { continue }
            for message in threadObj.allMessages() {
                guard let messageObj = message as? PMessage else { continue }
                print(messageObj.readStatus?())
                print(messageObj.read())
                if !(messageObj.read()?.boolValue ?? true) {
                    i += 1
                }
            }
        }
        
        return i
    }
    
    func setBadge(badge: Int, index: Int) {
        let badgeString: String? = badge == 0 ? nil : String(format: "%i", badge)
        self.tabBar.items?[index].badgeValue = badgeString
    }
    
    func setPrivateThreadsbadge(badge: Int) {
        self.setBadge(badge: badge, index: indexOfPrivateThread)
        UserDefaults.standard.set(badge, forKey: bMessagesBadgeValueKey)
        
        if BChatSDK.shared()!.configuration.appBadgeEnabled {
            UIApplication.shared.applicationIconBadgeNumber = badge
        }
    }
}
