//
//  settingViewController.swift
//  MFSCalendar
//
//  Created by David Dai on 2017/6/22.
//  Copyright © 2017 David. All rights reserved.
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
    
    @IBAction func changeQuarter(_ sender: Any) {
        let quarterActionSheet = UIAlertController(title: "Are you sure you want to change quarter?", message: "This will clear all the course data.", preferredStyle: .actionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (alertAction) -> Void in
            NSLog("Canceled")
        }
        
        let changeQuarterAction = UIAlertAction(title: "Yes, change it!", style: .default) { (alertAction) -> Void in
            NSLog("Quarter Changed")
            print(self.currentQuarter.selectedSegmentIndex)
            Preferences().currentQuarter = self.currentQuarter.selectedSegmentIndex + 1
            Preferences().courseInitialized = false
            Preferences().doUpdateQuarter = false
            self.tabBarController?.selectedIndex = 0
        }
        
        quarterActionSheet.addAction(cancelAction)
        quarterActionSheet.addAction(changeQuarterAction)
        
        if let segmentedView = sender as? UIView {
            quarterActionSheet.popoverPresentationController?.sourceView = segmentedView
            quarterActionSheet.popoverPresentationController?.sourceRect = segmentedView.frame
        }
        
        self.present(quarterActionSheet, animated: true, completion: nil)
    }
}
