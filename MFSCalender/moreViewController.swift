//
//  moreViewController.swift
//  MFSCalendar
//
//  Created by 戴元平 on 2017/4/23.
//  Copyright © 2017年 David. All rights reserved.
//

import UIKit
import UserNotifications
import MessageUI

class moreViewController: UITableViewController {
    let userDefaults = UserDefaults(suiteName: "group.org.dwei.MFSCalendar")
    
    @IBOutlet weak var profilePhoto: UIImageView!
    @IBOutlet weak var name: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        let photoPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let path = photoPath.appending("/ProfilePhoto.png")
        profilePhoto.image = UIImage(contentsOfFile: path)
        profilePhoto.contentMode = UIViewContentMode.scaleAspectFill
        let lastName = userDefaults?.string(forKey: "lastName")
        let firstName = userDefaults?.string(forKey: "firstName")
        name.text = firstName! + " " + lastName!
    }

}


class settingViewController: UITableViewController, UIActionSheetDelegate {
    let userDefaults = UserDefaults(suiteName: "group.org.dwei.MFSCalendar")


    @IBAction func logout(_ sender: Any) {
        let logOutActionSheet = UIAlertController(title: nil, message: "Are you sure you want to log out?", preferredStyle: .actionSheet)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (alertAction) -> Void in
            NSLog("Canceled")
        }

        let logOutAction = UIAlertAction(title: "Log Out", style: .default) { (alertAction) -> Void in
            NSLog("Logged Out")
            self.userDefaults?.set(false, forKey: "didLogin")
            self.userDefaults?.set(false, forKey: "courseInitialized")
//            self.userDefaults?.removeObject(forKey: "username")
//            self.userDefaults?.removeObject(forKey: "password")
            self.userDefaults?.removeObject(forKey: "firstName")
            self.userDefaults?.removeObject(forKey: "lastName")
            self.userDefaults?.removeObject(forKey: "lockerNumber")
            self.userDefaults?.removeObject(forKey: "lockerPassword")
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "MainTab")
            self.present(vc!, animated: false, completion: nil)
        }

        logOutActionSheet.addAction(cancelAction)
        logOutActionSheet.addAction(logOutAction)

        self.present(logOutActionSheet, animated: true, completion: nil)
    }

//    @IBAction func clearData(_ sender: Any) {
//        let clearDataActionSheet = UIAlertController(title: nil, message: "This will clear all the data.", preferredStyle: .actionSheet)
//
//        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (alertAction) -> Void in
//            NSLog("Canceled")
//        }
//
//        let clearDataAction = UIAlertAction(title: "Clear Data", style: .default) { (alertAction) -> Void in
//            NSLog("Data Cleared")
//            self.userDefaults?.set(false, forKey: "dataInitialized")
//            do {
//                let fileManager = FileManager()
//                let filePath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
//                let path = filePath.appending("/day.plist")
//                try fileManager.removeItem(atPath: path)
//            } catch {
//                print(error)
//            }
//            let vc = self.storyboard?.instantiateViewController(withIdentifier: "MainTab")
//            self.present(vc!, animated: false, completion: nil)
//        }
//
//        clearDataActionSheet.addAction(cancelAction)
//        clearDataActionSheet.addAction(clearDataAction)
//
//        self.present(clearDataActionSheet, animated: true, completion: nil)
//    }

}


class profileViewController: UITableViewController {
    @IBOutlet weak var firstName: UILabel!
    @IBOutlet weak var lastName: UILabel!
    @IBOutlet weak var lockerNumber: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        let userDefaults = UserDefaults(suiteName: "group.org.dwei.MFSCalendar")
        firstName.text = userDefaults?.string(forKey: "firstName")
        lastName.text = userDefaults?.string(forKey: "lastName")
        lockerNumber.text = userDefaults?.string(forKey: "lockerNumber")
    }


}

class classListController:UITableViewController {
    
    var classList:NSArray!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        let classPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let path = classPath.appending("/CourseList.plist")
        classList = NSArray(contentsOfFile: path)!
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.classList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "classList", for: indexPath as IndexPath)
        let row = indexPath.row
        let classObject = self.classList[row] as? NSDictionary
        let className = classObject?["className"] as? String
//        let block = classObject?["block"] as? String
        let roomNumber = classObject?["roomNumber"] as? String
        let teacherName = classObject?["teacherName"] as? String
        cell.textLabel?.text = className!
        var detail:String? = nil
        if !((roomNumber?.isEmpty)!) {
//            Room number 不为空的时候
            detail = "Room: " + roomNumber!
        }
        if !((teacherName?.isEmpty)!) {
//            Same
            detail = detail?.appending((" Teacher's name: " + teacherName!))
        }
        cell.detailTextLabel?.text = detail
        
        cell.selectionStyle = .none
        return cell
    }
}


class aboutView:UITableViewController, MFMailComposeViewControllerDelegate {
    
    @IBAction func sendEmail(_ sender: Any) {
        let mailComposeViewController = configuredMailComposeViewController()
        if MFMailComposeViewController.canSendMail() {
            self.present(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        
        mailComposerVC.setToRecipients(["zjdavid.2003@gmail.com", "daiw@mfriends.org"])
        mailComposerVC.setSubject("Bug reports and suggestions")
        mailComposerVC.setMessageBody("", isHTML: false)
        
        return mailComposerVC
    }
    
    func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertController(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        sendMailErrorAlert.addAction(okAction)
        self.present(sendMailErrorAlert, animated: true, completion: nil)
    }
    
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}













