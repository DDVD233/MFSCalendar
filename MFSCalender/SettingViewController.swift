//
//  settingViewController.swift
//  MFSCalendar
//
//  Created by David Dai on 2017/6/22.
//  Copyright © 2017年 David. All rights reserved.
//

import UIKit

class settingViewController: UITableViewController, UIActionSheetDelegate {
    @IBOutlet var currentQuarter: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        currentQuarter.selectedSegmentIndex = Preferences().currentQuarter - 1
    }

    override func viewWillAppear(_ animated: Bool) {
//        themeColorLabel.text = userDefaults?.string(forKey: "themeColor") ?? "Salmon"
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        if indexPath.section == 0 {
//            let logOutActionSheet = UIAlertController(title: nil, message: "Select one theme color.", preferredStyle: .actionSheet)
//
//            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (alertAction) -> Void in
//                NSLog("Canceled")
//            }
//
//            let salmonAction = UIAlertAction(title: "Salmon", style: .default) { (alertAction) -> Void in
//
//                let vc = self.storyboard?.instantiateViewController(withIdentifier: "MainTab")
//                self.present(vc!, animated: false, completion: nil)
//            }
//
////            let indigoAction = UIAlertAction(title: "Indigo", style: .default) { (alertAction) -> Void in
////                let vc = self.storyboard?.instantiateViewController(withIdentifier: "MainTab")
////                self.present(vc!, animated: false, completion: nil)
////            }
//
//            logOutActionSheet.addAction(cancelAction)
//            logOutActionSheet.addAction(salmonAction)
//            
//            logOutActionSheet.popoverPresentationController?.sourceView = self.view
//            logOutActionSheet.popoverPresentationController?.sourceRect = self.view.bounds
//
//            self.present(logOutActionSheet, animated: true, completion: nil)
//        }
        
    }
    
    @IBAction func quarterButtonTouched(_ sender: Any) {
        print(currentQuarter.selectedSegmentIndex)
        Preferences().currentQuarter = currentQuarter.selectedSegmentIndex + 1
        Preferences().courseInitialized = false
        Preferences().doUpdateQuarter = false
        self.tabBarController?.selectedIndex = 0
    }
    
}
