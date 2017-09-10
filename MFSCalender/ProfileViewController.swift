//
//  ProfileViewController.swift
//  MFSCalendar
//
//  Created by 戴元平 on 2017/8/30.
//  Copyright © 2017年 David. All rights reserved.
//

import UIKit

class profileViewController: UITableViewController {
    @IBOutlet var profilePhoto: UIImageView!
    @IBOutlet var profileName: UILabel!
    @IBOutlet var headerView: UIView!
    
    var contentList = [String: Any]()
    var contentKey: [String] {
        return Array(contentList.keys).sorted(by: { $0 < $1 })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupHeaders()
        getProfileInformation()
        
        if let navigationBar = self.navigationController?.navigationBar {
            navigationBar.removeBottomLine()
        }
    }
    
    func setupHeaders() {
        let photoPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let path = photoPath.appending("/ProfilePhoto.png")
        profilePhoto.image = UIImage(contentsOfFile: path)
        profilePhoto.contentMode = UIViewContentMode.scaleAspectFill
        profilePhoto.cornerRadius = profilePhoto.frame.size.width / 2
        
        let firstName = userDefaults?.string(forKey: "firstName") ?? ""
        let lastName = userDefaults?.string(forKey: "lastName") ?? ""
        profileName.text = firstName + " " + lastName
    }
    
    func getProfileInformation() {
        let infoList = ["firstName", "lastName", "email", "lockerNumber", "lockerCombination"]
        
        for key in infoList {
            if let value = userDefaults?.value(forKey: key) {
                contentList[key] = value
            }
        }
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}

extension profileViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contentList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "profileTableCell", for: indexPath) as! profileTableCell
        var key = contentKey[indexPath.row]
        guard let value = contentList[key] as? String else {
            return cell
        }
        
        key.capitalizeFirstLetter()
        key.separatedByUpperCase()
        
        cell.key.text = key
        cell.value.text = value
        
        cell.selectionStyle = .none
        
        return cell
    }
}

class profileTableCell: UITableViewCell {
    @IBOutlet var value: UILabel!
    @IBOutlet var key: UILabel!
}
