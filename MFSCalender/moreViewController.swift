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
import JSQWebViewController

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
            guard let cookie = NetworkOperations().loginUsingPost() else {
                return
            }
            let url = URL(string: "https://mfriends.myschoolapp.com/app/student#resourceboard")!
            
            var request = URLRequest(url: url)
            HTTPCookieStorage.shared.setCookies(cookie, for: url, mainDocumentURL: URL(string: "https://mfriends.myschoolapp.com"))
            //request.addValue(cookie, forHTTPHeaderField: "cookie")
            let cookies = HTTPCookieStorage.shared.cookies(for: url)
            let headers = HTTPCookie.requestHeaderFields(with: cookies!)
            request.allHTTPHeaderFields = headers
            let webPage = WebViewController(urlRequest: request)
            self.show(webPage, sender: self)
        }
    }
}
