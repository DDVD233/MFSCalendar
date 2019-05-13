//
//  AppDelegate.swift
//  MFSCalender
//
//  Created by David Dai on 2016/12/1.
//  Copyright © 2016年 David. All rights reserved.
//

import UIKit
import CoreData
import Firebase
import Fabric
import Crashlytics
import AirshipKit
import ChatSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
//        FirebaseApp.configure()
        Fabric.with([Crashlytics()])
        logUser()
        if (UIDevice().userInterfaceIdiom == .phone) && (UIScreen.main.nativeBounds.height == 2436) {
            Preferences().isiPhoneX = true
        }
        
        UIApplication.shared.setMinimumBackgroundFetchInterval(1800)
        
        let config = BConfiguration.init();
        config.rootPath = "test"
        config.googleMapsApiKey = "AIzaSyAcNgntmKUbMZRAgany5xwTU6zRh-zfDtg"
        
        config.allowUsersToCreatePublicChats = false
        config.shouldAskForNotificationsPermission = false
        BChatSDK.initialize(config, app: application, options: launchOptions)
//        self.window = UIWindow.init(frame: UIScreen.main.bounds)
//        self.window?.rootViewController = BChatSDK.ui()?.splashScreenNavigationController()
//        self.window?.makeKeyAndVisible();

        //setPushNotification()
        if BChatSDK.auth()?.isAuthenticated() ?? false {
            _ = BChatSDK.auth()?.authenticate()
        }
        
        BChatSDK.shared()?.interfaceAdapter = MyAppInterfaceAdapter()
        
        return true
    }
    
//    func setPushNotification() {
//        UAirship.takeOff()
//        UAirship.push().userPushNotificationsEnabled = true
//        if #available(iOS 10.0, *) {
//            UAirship.push().defaultPresentationOptions = [.alert, .badge, .sound]
//        } else {
//            // Fallback on earlier versions
//        }
//        if Preferences().isDev {
//            UAirship.push().addTag("developer")
//        }
//        
//        if let firstName = Preferences().firstName, let lastName = Preferences().lastName {
//            UAirship.namedUser().identifier = firstName + " " + lastName
//        }
//        
//        let classPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
//        let path = classPath.appending("/CourseList.plist")
//        if let classList = NSArray(contentsOfFile: path) as? [[String: Any]] {
//            for classes in classList {
//                if let classID = classes["id"] as? String {
//                    UAirship.push().addTags([classID], group: "registeredClass")
//                }
//            }
//        }
////        print("Channel ID: " + (UAPus ?? "None"))
//    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        BChatSDK.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        BChatSDK.application(application, didReceiveRemoteNotification: userInfo)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        BChatSDK.application(application, didReceiveRemoteNotification: userInfo)
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return BChatSDK.application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return BChatSDK.application(app, open: url, options: options)
    }
    
    func logUser() {
//        Crashlytics.sharedInstance().setUserEmail("user@fabric.io")
//        Crashlytics.sharedInstance().setUserIdentifier("12345")
        let firstName = Preferences().firstName ?? ""
        let lastName = Preferences().lastName ?? ""
        let fullName = firstName + lastName
        Crashlytics.sharedInstance().setUserName(fullName)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        let visibleViewController = getVisibleViewController(nil)
        if visibleViewController?.restorationIdentifier == "Main" {
            visibleViewController?.viewDidAppear(true)
        }


        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func getVisibleViewController(_ rootViewController: UIViewController?) -> UIViewController? {

        var rootVC = rootViewController
        if rootVC == nil {
            rootVC = UIApplication.shared.keyWindow?.rootViewController
        }
        
        if (rootVC?.presentedViewController == nil) && ((rootVC as? UITabBarController)?.selectedViewController == nil) {
            return rootVC
        }
        
        if let presented = rootVC?.presentedViewController {
            return getSubViewController(presented: presented)
        } else if let presented = (rootVC as? UITabBarController)?.selectedViewController {
            return getSubViewController(presented: presented)
        }
        return nil
    }
    
    func getSubViewController(presented: UIViewController) -> UIViewController? {
        if presented.isKind(of: UINavigationController.self) {
            let navigationController = presented as! UINavigationController
            return navigationController.viewControllers.last!
        }
        
        if presented.isKind(of: UITabBarController.self) {
            let tabBarController = presented as! UITabBarController
            if tabBarController.selectedViewController!.isKind(of: UINavigationController.self) {
                return getVisibleViewController(tabBarController.selectedViewController)
            } else {
                return tabBarController
            }
        }
        
        return getVisibleViewController(presented)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        if #available(iOS 10.0, *) {
            self.saveContext()
        }
    }
    
    func application(_ application: UIApplication,
                     performFetchWithCompletionHandler completionHandler:
        @escaping (UIBackgroundFetchResult) -> Void) {
        // Check for new data.
        if Preferences().isInStepChallenge {
            StepChallenge().reportSteps()
        }
        
        completionHandler(.newData)
    }

    // MARK: - Core Data stack

    @available(iOS 10.0, *)
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "MFSCalender")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    @available(iOS 10.0, *)
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

