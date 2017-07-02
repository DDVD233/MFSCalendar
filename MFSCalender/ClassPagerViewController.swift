//
//  ClassPagerViewController.swift
//  MFSCalendar
//
//  Created by 戴元平 on 2017/7/2.
//  Copyright © 2017年 David. All rights reserved.
//

import UIKit
import XLPagerTabStrip

class classPagerViewController: ButtonBarPagerTabStripViewController {
    override func viewDidLoad() {
        settings.style.buttonBarMinimumLineSpacing = 0
        settings.style.buttonBarBackgroundColor = .white
        settings.style.buttonBarItemBackgroundColor = .white
        settings.style.buttonBarItemFont = .boldSystemFont(ofSize: 14)
        settings.style.buttonBarItemsShouldFillAvailiableWidth = true
        settings.style.buttonBarItemTitleColor = .black
        settings.style.selectedBarBackgroundColor = UIColor(hexString: 0xFF7E79)
        settings.style.selectedBarHeight = 5
        
        changeCurrentIndexProgressive = { (oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) -> Void in
            guard changeCurrentIndex == true else { return }
            oldCell?.label.textColor = .black
            newCell?.label.textColor = UIColor(hexString: 0xFF7E79)
        }
        
//        Important: Settings should be called before viewDidLoad is called.
        super.viewDidLoad()
    }
    
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let overviewViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "overview")
        let topicViewCOntroller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "topic")
        return [overviewViewController, topicViewCOntroller]
    }
}
