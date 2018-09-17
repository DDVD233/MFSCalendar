//
//  ClassTimetableViewController.swift
//  MFSCalendar
//
//  Created by David Dai on 2017/8/7.
//  Copyright © 2017 David. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class timeTableParentViewController: SegmentedPagerTabStripViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override public func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
//        var arrayToReturn = [UIViewController]()
//        for alphabet in "ABCDEF" {
//            let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "timeTableViewController") as! ADay
//            
//            viewController.daySelected = String(alphabet)
//            
//            arrayToReturn.append(viewController)
//        }
        return [UIViewController]()
    }
    
}

