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

class moreViewController: UITableViewController, UIDocumentInteractionControllerDelegate {

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
    
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
}

extension moreViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 && indexPath.row == 1 {
            guard loginAuthentication().success else {
                return
            }
            
            let requestURL = URL(string: "https://mfriends.myschoolapp.com/api/resourceboardcontainer/usercontainersget/?personaId=2&dateMask=0&levels=1151")!
            let semaphore = DispatchSemaphore(value: 0)
            DispatchQueue.main.async {
                self.navigationController?.showProgress()
                self.navigationController?.setIndeterminate(true)
            }
            
            let task = URLSession.shared.dataTask(with: requestURL, completionHandler: { (data, response, error) in
                self.navigationController?.cancelProgress()
                guard error == nil else {
                    presentErrorMessage(presentMessage: error!.localizedDescription, layout: .CardView)
                    return
                }
                
                do {
                    guard let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [[String: Any]] else {
                        presentErrorMessage(presentMessage: "Internal error: incorrect data format", layout: .StatusLine)
                        return
                    }
                    
                    guard let lunchObject = json.filter({ $0["ShortDescription"] as? String == "What's For Lunch?" }).first else {
                        presentErrorMessage(presentMessage: "Cannot find lunch menu", layout: .StatusLine)
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
                    presentErrorMessage(presentMessage: error.localizedDescription, layout: .StatusLine)
                }
                
                semaphore.signal()
            })
            
            task.resume()
            semaphore.wait()
        } else if indexPath.section == 1 && indexPath.row == 2 {
            let token = loginAuthentication().token
            let url = URL(string: "https://mfriends.myschoolapp.com/app/student#resourceboard")!
            var request = URLRequest(url: url)
            
            let webView = WebViewController(urlRequest: request)
            request.setValue("t=\(token)", forHTTPHeaderField: "Cookie")
            self.show(webView, sender: self)
        }
    }
    
    
}
