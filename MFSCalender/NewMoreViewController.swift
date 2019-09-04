//
//  NewMoreViewController.swift
//  MFSCalendar
//
//  Created by David Dai on 10/17/17.
//  Copyright © 2017 David. All rights reserved.
//

import UIKit
import SCLAlertView
import SVProgressHUD
import Alamofire
import Crashlytics
import SafariServices
import M13ProgressSuite
import ChatSDK
import SCLAlertView

class NewMoreViewController: UICollectionViewController  {
    var contentList = [String]()
    let myCourses = NSLocalizedString("My Courses", comment: "")
    let lunchMenu = NSLocalizedString("Lunch Menu", comment: "")
    let serviceHourS = NSLocalizedString("Service Hour", comment: "")
    let logout = NSLocalizedString("Logout", comment: "")
    let about = NSLocalizedString("About", comment: "")
    let settings = NSLocalizedString("Settings", comment: "")
    let stepChallenge = NSLocalizedString("Step Challenge", comment: "")
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        if Preferences().isiPhoneX {
//            hidesBottomBarWhenPushed = true
//        } else {
//            hidesBottomBarWhenPushed = false
//        }
        if Preferences().schoolName == "MFS" {
            contentList = [myCourses, lunchMenu, serviceHourS, logout, about, settings, stepChallenge]
        } else {
            contentList = [myCourses, lunchMenu, logout, about, settings]
        }
        
        if Preferences().isDev {
            contentList.append("DON'T TOUCH")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        if Preferences().doPresentServiceView {
            Preferences().doPresentServiceView = false
            DispatchQueue.global().async {
                self.serviceHour()
            }
        }
    }
}

// Data Source
extension NewMoreViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return contentList.count
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "profile", for: indexPath) as? ProfileCollectionCell else {
                return UICollectionViewCell()
            }
            
            let photoPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
            let path = photoPath.appending("/ProfilePhoto.png")
            cell.imageView.image = UIImage(contentsOfFile: path)
            cell.imageView.contentMode = UIView.ContentMode.scaleAspectFill
            
            cell.nameLabel.text = ""
            if let firstName = Preferences().firstName {
                cell.nameLabel.text?.append(firstName + " ")
            }
            
            if let lastName = Preferences().lastName {
                cell.nameLabel.text?.append(lastName)
            }
            
            return cell
        } else if indexPath.section == 1 {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "menu", for: indexPath) as? MenuCollectionCell else {
                return UICollectionViewCell()
            }
            
            cell.imageView.contentMode = .scaleAspectFit
            let row = indexPath.row
            let contentTitle = contentList[safe: row]
            cell.nameLabel.text = contentTitle
            
            switch contentTitle {
            case myCourses:
                cell.imageView.image = UIImage(named: "MenuCourses.png")
            case lunchMenu:
                cell.imageView.image = UIImage(named: "MenuLunch.png")
            case serviceHourS:
                cell.imageView.image = UIImage(named: "MenuService.png")
            case logout:
                cell.imageView.image = UIImage(named: "MenuLogout.png")
            case about:
                cell.imageView.image = UIImage(named: "MenuAbout.png")
            case settings:
                cell.imageView.image = UIImage(named: "MenuSettings.png")
            case stepChallenge:
                cell.imageView.image = UIImage(named: "running.png")
            case "DON'T TOUCH":
                cell.imageView.image = UIImage(named: "MenuWarning.png")
            default:
                break
            }
            
            return cell
        } else {
            return UICollectionViewCell()
        }
    }
}

// Delegate
extension NewMoreViewController {
    override func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? MenuCollectionCell {
            cell.view.backgroundColor = UIColor(hexString: 0xF0F0F0)
        } else if let cell = collectionView.cellForItem(at: indexPath) as? ProfileCollectionCell {
            cell.view.backgroundColor = UIColor(hexString: 0xF0F0F0)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? MenuCollectionCell {
            cell.view.backgroundColor = UIColor.white
        } else if let cell = collectionView.cellForItem(at: indexPath) as? ProfileCollectionCell {
            cell.view.backgroundColor = UIColor.white
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            if let profileVC = storyboard?.instantiateViewController(withIdentifier: "profile") {
                show(profileVC, sender: self)
            }
        } else if indexPath.section == 1 {
            let contentTitle = contentList[safe: indexPath.row]
            switch contentTitle {
            case myCourses:
                if let courseVC = storyboard?.instantiateViewController(withIdentifier: "courseList") {
                    show(courseVC, sender: self)
                }
            case lunchMenu:
                DispatchQueue.global().async {
                    self.getLunchMenu()
                }
            case serviceHourS:
                DispatchQueue.global().async {
                    self.serviceHour()
                }
            case logout:
                if let cell = collectionView.cellForItem(at: indexPath) {
                    logout(sender: cell)
                }
            case about:
                if let infoVC = storyboard?.instantiateViewController(withIdentifier: "about") {
                    show(infoVC, sender: self)
                }
            case settings:
                if let settingsVC = storyboard?.instantiateViewController(withIdentifier: "settings") {
                    show(settingsVC, sender: self)
                }
            case stepChallenge:
                if let stepChallengeVC = storyboard?.instantiateViewController(withIdentifier: "stepChallenge") {
                    guard Preferences().schoolName == "MFS" else { return }
                    show(stepChallengeVC, sender: self)
                }
            case "DON'T TOUCH":
                userDefaults.set(false, forKey: "didShowMobileServe")
                self.tabBarController?.selectedIndex = 0
            default:
                break
            }
        }
    }
    
    func serviceHour() {
        if Preferences().servicePassword != nil {
            var serviceHour = 999
            serviceHour = self.getServiceHour()
            let serviceHourString = serviceHour > 990 ? "Error" : String(describing: serviceHour)
            DispatchQueue.main.async {
                self.presentServiceHourView(hour: serviceHourString)
            }
        } else {
            DispatchQueue.main.async {
                self.presentServiceHourLoginView()
            }
        }
    }
    
    //    996: Data not received/incorrect format
    //    997: Username/password Not found
    //    998: Server internal error. Csrf_middleware_token not found
    //    999: Incorrect username/password
    func getServiceHour() -> Int {
        guard let username = Preferences().serviceUsername?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed), let password = Preferences().servicePassword?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            return 997
        }
        
        let url = "https://mfs-calendar.appspot.com/serviceHour/\(username)/\(password)"
        Crashlytics.sharedInstance().setObjectValue(url, forKey: "MobileServe_URL")
        print(url)
        
        var serviceHour: Int? = nil
        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            SVProgressHUD.show()
        }
        
        Alamofire.request(url).response(queue: DispatchQueue.global(), completionHandler: { (result) in
            guard result.error == nil else {
                presentErrorMessage(presentMessage: result.error!.localizedDescription, layout: .cardView)
                semaphore.signal()
                return
            }
            
            guard let serviceHourString = String(data: result.data!, encoding: .utf8) else {
                presentErrorMessage(presentMessage: "Incorrect data format", layout: .statusLine)
                semaphore.signal()
                return
            }
            
            serviceHour = Int(serviceHourString)
            semaphore.signal()
        })
        
        semaphore.wait()
        
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            SVProgressHUD.dismiss()
        }
        
        return serviceHour ?? 996
    }
    
    func presentServiceHourLoginView() {
        let appearance = SCLAlertView.SCLAppearance(shouldAutoDismiss: true)
        
        let loginView = SCLAlertView(appearance: appearance)
        let username = loginView.addTextField("Username")
        username.autocorrectionType = .no
        username.autocapitalizationType = .none
        if Preferences().serviceUsername.existsAndNotEmpty() {
            username.text = Preferences().serviceUsername
        }
        
        let password = loginView.addTextField("Password")
        password.isSecureTextEntry = true
        
        loginView.addButton("Login") {
            Preferences().serviceUsername = username.text
            Preferences().servicePassword = password.text
            
            let hour = self.getServiceHour()
            switch hour {
            case 999:
                presentErrorMessage(presentMessage: "Login failed. Your username/password maybe incorrect.", layout: .cardView)
                Preferences().servicePassword = nil
            case 996, 998:
                presentErrorMessage(presentMessage: "Login failed. Server internal error. Please try again later.", layout: .cardView)
                Preferences().servicePassword = nil
            default:
                loginView.hideView()
            }
        }
        
        loginView.showInfo(NSLocalizedString("Log in to Mobileserve", comment: ""), subTitle: NSLocalizedString("Please use your Mobileserve account to login.", comment: ""), closeButtonTitle: NSLocalizedString("Cancel", comment: ""), animationStyle: .bottomToTop)
    }
    
    func presentServiceHourView(hour: String) {
        let appearance = SCLAlertView.SCLAppearance(kTitleFont: UIFont.boldSystemFont(ofSize: 40),
                                                    kTextFont: UIFont(name: "HelveticaNeue", size: 17)!)
        let alertView = SCLAlertView(appearance: appearance)
        alertView.addButton("Log Out") {
            Preferences().servicePassword = nil
        }
        
        alertView.showInfo(hour, subTitle: "TOTAL SERVICE HOURS", animationStyle: .bottomToTop)
    }
    
    func getLunchMenu() {
        switch Preferences().schoolName {
        case "MFS":
            let lunchMenuURL = URL(string: "http://www.sagedining.com/sites/menu/menu.php?org=moorestownfriendsschool")!
            let safariViewController = SFSafariViewController(url: lunchMenuURL)
            self.present(safariViewController, animated: true, completion: nil)
        case "CMH":
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                SVProgressHUD.show()
            }
            
            guard loginAuthentication().success else {
                return
            }
            
            let requestURL = URL(string: Preferences().baseURL + "/api/link/forresourceboard/?format=json&categoryId=51487&itemCount=0")!
            let semaphore = DispatchSemaphore(value: 0)
            
            let task = URLSession.shared.dataTask(with: requestURL, completionHandler: { (data, response, error) in
                self.navigationController?.cancelProgress()
                guard error == nil else {
                    presentErrorMessage(presentMessage: error!.localizedDescription, layout: .cardView)
                    return
                }
                
                do {
//                    print(String(data: data!, encoding: .utf8))
                    guard let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [[String: Any]] else {
                        presentErrorMessage(presentMessage: "Internal error: incorrect data format", layout: .statusLine)
                        return
                    }
                    
                    guard let itemData = json[0]["ItemData"] as? [[String: Any]] else {
                        presentErrorMessage(presentMessage: "Internal error: ItemData not found", layout: .statusLine)
                        return
                    }
                    guard let lunchObject = itemData.filter({ ($0["ShortDescription"] as? String ?? "").contains("Lunch Menu") }).first else {
                        presentErrorMessage(presentMessage: "Cannot find lunch menu", layout: .statusLine)
                        return
                    }
                    
                    guard var lunchUrl = lunchObject["Url"] as? String else {
                        return
                    }
                    
                    NetworkOperations().openLink(url: &lunchUrl, from: self)
                } catch {
                    presentErrorMessage(presentMessage: error.localizedDescription, layout: .statusLine)
                }
                
                semaphore.signal()
            })
            
            task.resume()
            semaphore.wait()
            
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                SVProgressHUD.dismiss()
            }
        default:
            return
        }
    }
    
    func logout(sender: UIView) {
        let logOutActionSheet = UIAlertController(title: nil, message: NSLocalizedString("Do you want to log out Class Chat or the app?", comment: ""), preferredStyle: .actionSheet)
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { (action) in
            NSLog("Canceled")
        }
        
        let logoutClassChatAction = UIAlertAction(title: NSLocalizedString("Log out Class Chat", comment: ""), style: .default) { (alertAction) -> Void in
            _ = BIntegrationHelper.logout()?.thenOnMain({ (result) in
                let loginNotice = SCLAlertView()
                loginNotice.showInfo(NSLocalizedString("Success", comment: ""), subTitle: NSLocalizedString("You've successfully logged out of Class Chat.", comment: ""), animationStyle: .bottomToTop)
                return result
            }, { error in
                presentErrorMessage(presentMessage: error?.localizedDescription ?? "Unknown Error", layout: .cardView)
                return error
            })
            NSLog("Class Chat Logged Out")
        }
        
        let logOutAction = UIAlertAction(title: NSLocalizedString("Log Out the App", comment: ""), style: .default) { (alertAction) -> Void in
            NSLog("Logged Out")
            _ = BIntegrationHelper.logout()?.thenOnMain({ result in
                let preferences = Preferences()
                preferences.didLogin = false
                preferences.courseInitialized = false
                preferences.firstName = nil
                preferences.lastName = nil
                preferences.lockerNumber = nil
                preferences.lockerCombination = nil
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "MainTab")
                self.present(vc!, animated: false, completion: nil)
                return result
            }, { error in
                presentErrorMessage(presentMessage: error?.localizedDescription ?? "Unknown Error", layout: .cardView)
                return error
            })
        }
        
        logOutActionSheet.addAction(logoutClassChatAction)
        logOutActionSheet.addAction(logOutAction)
        logOutActionSheet.addAction(cancelAction)
        
        logOutActionSheet.popoverPresentationController?.sourceView = sender
        logOutActionSheet.popoverPresentationController?.sourceRect = sender.frame
        
        self.present(logOutActionSheet, animated: true, completion: nil)
    }
}

// Flow Layout
extension NewMoreViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let screenWidth = UIScreen.main.bounds.width
        if indexPath.section == 0 {
            return CGSize(width: screenWidth, height: 120)
        } else {
            let viewSize = Layout().squareSize(estimatedWidth: 120) - 4
            return CGSize(width: viewSize, height: viewSize)
        }
    }
}

extension NewMoreViewController: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
}

class ProfileCollectionCell: UICollectionViewCell {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var view: UIView!
}

class MenuCollectionCell: UICollectionViewCell {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var view: UIView!
    
}
