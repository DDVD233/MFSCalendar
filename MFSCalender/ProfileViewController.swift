//
//  ProfileViewController.swift
//  MFSCalendar
//
//  Created by 戴元平 on 2017/8/30.
//  Copyright © 2017年 David. All rights reserved.
//

import UIKit

class profileViewController: UITableViewController {
    @IBOutlet weak var lockerNumber: UILabel!
    @IBOutlet var profilePhoto: UIImageView!
    @IBOutlet var profileName: UILabel!
    @IBOutlet var headerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let photoPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let path = photoPath.appending("/ProfilePhoto.png")
        profilePhoto.image = UIImage(contentsOfFile: path)
        profilePhoto.contentMode = UIViewContentMode.scaleAspectFill
        profilePhoto.cornerRadius = profilePhoto.frame.size.width / 2
        
        let firstName = userDefaults?.string(forKey: "firstName") ?? ""
        let lastName = userDefaults?.string(forKey: "lastName") ?? ""
        profileName.text = firstName + " " + lastName
        
        lockerNumber.text = userDefaults?.string(forKey: "lockerNumber")
    }
    
//    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        if scrollView.contentOffset.y < 0 {
//            let height = -scrollView.contentOffset.y + 215
//            headerView.frame = CGRect(x: 0, y: scrollView.contentOffset.y, width: view.frame.width, height: height)
//            UIView.commitAnimations()
//        }
//    }
}
