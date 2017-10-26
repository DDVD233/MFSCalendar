//
//  NewMoreViewController.swift
//  MFSCalendar
//
//  Created by 戴元平 on 10/17/17.
//  Copyright © 2017 David. All rights reserved.
//

import UIKit
import SCLAlertView
import SVProgressHUD
import Alamofire

class NewMoreViewController: UICollectionViewController  {
    override func viewDidLoad() {
        super.viewDidLoad()
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
            if Preferences().isDev {
                return 6
            } else {
                return 5
            }
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
            cell.imageView.contentMode = UIViewContentMode.scaleAspectFill
            
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
            
            switch indexPath.row {
            case 0:
                cell.nameLabel.text = "My Courses"
                cell.imageView.image = UIImage(named: "MenuCourses.png")
            case 1:
                cell.nameLabel.text = "Lunch Menu"
                cell.imageView.image = UIImage(named: "MenuLunch.png")
            case 2:
                cell.nameLabel.text = "Service Hour"
                cell.imageView.image = UIImage(named: "MenuService.png")
            case 3:
                cell.nameLabel.text = "Logout"
                cell.imageView.image = UIImage(named: "MenuLogout.png")
            case 4:
                cell.nameLabel.text = "About"
                cell.imageView.image = UIImage(named: "MenuAbout.png")
            case 5:
                cell.nameLabel.text = "DON'T TOUCH"
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
            switch indexPath.row {
            case 0:
                if let courseVC = storyboard?.instantiateViewController(withIdentifier: "courseList") {
                    show(courseVC, sender: self)
                }
            case 1:
                DispatchQueue.global().async {
                    self.getLunchMenu()
                }
            case 2:
                DispatchQueue.global().async {
                    self.serviceHour()
                }
            case 3:
                if let cell = collectionView.cellForItem(at: indexPath) {
                    logout(sender: cell)
                }
            case 4:
                if let infoVC = storyboard?.instantiateViewController(withIdentifier: "about") {
                    show(infoVC, sender: self)
                }
            case 5:
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
        guard let username = Preferences().serviceUsername, let password = Preferences().servicePassword else {
            //presentServiceLoginView()
            return 997
        }
        
        
        let url = URL(string: "https://dwei.org/serviceHour/\(username)/\(password)")!
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
        let appearance = SCLAlertView.SCLAppearance(shouldAutoDismiss: false)
        
        let loginView = SCLAlertView(appearance: appearance)
        let username = loginView.addTextField("Username")
        if Preferences().serviceUsername.existsAndNotEmpty() {
            username.text = Preferences().username
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
        
        loginView.showInfo("Log in to Mobileserve", subTitle: "Please use your Mobileserve account to login.", closeButtonTitle: "Cancel", animationStyle: .bottomToTop)
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
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            SVProgressHUD.show()
        }
        
        guard loginAuthentication().success else {
            return
        }
        
        let requestURL = URL(string: "https://mfriends.myschoolapp.com/api/resourceboardcontainer/usercontainersget/?personaId=2&dateMask=0&levels=1151")!
        let semaphore = DispatchSemaphore(value: 0)
        
        let task = URLSession.shared.dataTask(with: requestURL, completionHandler: { (data, response, error) in
            self.navigationController?.cancelProgress()
            guard error == nil else {
                presentErrorMessage(presentMessage: error!.localizedDescription, layout: .cardView)
                return
            }
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [[String: Any]] else {
                    presentErrorMessage(presentMessage: "Internal error: incorrect data format", layout: .statusLine)
                    return
                }
                
                guard let lunchObject = json.filter({ $0["ShortDescription"] as? String == "What's For Lunch?" }).first else {
                    presentErrorMessage(presentMessage: "Cannot find lunch menu", layout: .statusLine)
                    return
                }
                
                guard let lunchUrl = lunchObject["Url"] as? String else {
                    return
                }
                
                let (fileName, _) = NetworkOperations().downloadFile(url: URL(string: lunchUrl)!, withName: "LunchMenu.pdf")
                if fileName != nil {
                    NetworkOperations().openFile(fileUrl: fileName!, from: self)
                }
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
    }
    
    func logout(sender: UIView) {
        let logOutActionSheet = UIAlertController(title: nil, message: "Are you sure you want to log out?", preferredStyle: .actionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (alertAction) -> Void in
            NSLog("Canceled")
        }
        
        let logOutAction = UIAlertAction(title: "Log Out", style: .default) { (alertAction) -> Void in
            NSLog("Logged Out")
            let preferences = Preferences()
            preferences.didLogin = false
            preferences.courseInitialized = false
            preferences.firstName = nil
            preferences.lastName = nil
            preferences.lockerNumber = nil
            preferences.lockerCombination = nil
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "MainTab")
            self.present(vc!, animated: false, completion: nil)
        }
        
        logOutActionSheet.addAction(cancelAction)
        logOutActionSheet.addAction(logOutAction)
        
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
