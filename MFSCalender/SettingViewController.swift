//
//  settingViewController.swift
//  MFSCalendar
//
//  Created by 戴元平 on 2017/6/22.
//  Copyright © 2017年 David. All rights reserved.
//

import UIKit

class settingViewController: UITableViewController, UIActionSheetDelegate {
    
    @IBOutlet var themeColorLabel: UILabel!
    
    override func viewWillAppear(_ animated: Bool) {
        themeColorLabel.text = userDefaults?.string(forKey: "themeColor") ?? "Salmon"
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            let logOutActionSheet = UIAlertController(title: nil, message: "Select one theme color.", preferredStyle: .actionSheet)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (alertAction) -> Void in
                NSLog("Canceled")
            }
            
            let salmonAction = UIAlertAction(title: "Salmon", style: .default) { (alertAction) -> Void in
                
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "MainTab")
                self.present(vc!, animated: false, completion: nil)
            }
            
//            let indigoAction = UIAlertAction(title: "Indigo", style: .default) { (alertAction) -> Void in
//                let vc = self.storyboard?.instantiateViewController(withIdentifier: "MainTab")
//                self.present(vc!, animated: false, completion: nil)
//            }
            
            logOutActionSheet.addAction(cancelAction)
            logOutActionSheet.addAction(salmonAction)
            
            self.present(logOutActionSheet, animated: true, completion: nil)
        }
    }
    
    @IBAction func logout(_ sender: Any) {
        let logOutActionSheet = UIAlertController(title: nil, message: "Are you sure you want to log out?", preferredStyle: .actionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (alertAction) -> Void in
            NSLog("Canceled")
        }
        
        let logOutAction = UIAlertAction(title: "Log Out", style: .default) { (alertAction) -> Void in
            NSLog("Logged Out")
            userDefaults?.set(false, forKey: "didLogin")
            userDefaults?.set(false, forKey: "courseInitialized")
            //            userDefaults?.removeObject(forKey: "username")
            //            userDefaults?.removeObject(forKey: "password")
            userDefaults?.removeObject(forKey: "firstName")
            userDefaults?.removeObject(forKey: "lastName")
            userDefaults?.removeObject(forKey: "lockerNumber")
            userDefaults?.removeObject(forKey: "lockerPassword")
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "MainTab")
            self.present(vc!, animated: false, completion: nil)
        }
        
        logOutActionSheet.addAction(cancelAction)
        logOutActionSheet.addAction(logOutAction)
        
        self.present(logOutActionSheet, animated: true, completion: nil)
    }
    
}
