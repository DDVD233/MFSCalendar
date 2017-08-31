//
//  moreViewController.swift
//  MFSCalendar
//
//  Created by David Dai on 2017/4/23.
//  Copyright © 2017年 David. All rights reserved.
//

import UIKit
import UserNotifications
import SafariServices

class moreViewController: UITableViewController {

    @IBOutlet weak var profilePhoto: UIImageView!
    @IBOutlet weak var name: UILabel!

    @IBOutlet weak var settingImage: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        let photoPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let path = photoPath.appending("/ProfilePhoto.png")
        profilePhoto.image = UIImage(contentsOfFile: path)
        profilePhoto.contentMode = UIViewContentMode.scaleAspectFill

        name.text = ""
        if let firstName = userDefaults?.string(forKey: "firstName") {
            name.text?.append(firstName + " ")
        }

        if let lastName = userDefaults?.string(forKey: "lastName") {
            name.text?.append(lastName)
        }
    }

}

extension moreViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 && indexPath.row == 2 {
            let url = URL(string: "https://mfriends.myschoolapp.com/app/student#resourceboard")!
            let safariPage = SFSafariViewController(url: url)
            self.present(safariPage, animated: true, completion: nil)
        }
    }
}
