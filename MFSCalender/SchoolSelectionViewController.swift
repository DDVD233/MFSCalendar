//
//  SchoolSelectionViewController.swift
//  MFSMobile
//
//  Created by 戴元平 on 1/15/19.
//  Copyright © 2019 David. All rights reserved.
//

import UIKit

class SchoolSelectionViewController: UIViewController {
    @IBOutlet var schoolTable: UITableView!
    var schoolList = [[String: String]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        
        self.schoolTable.delegate = self
        self.schoolTable.dataSource = self
        
        schoolList = NSArray(contentsOfFile: FileList.supportedSchoolList.filePath) as? [[String: String]] ?? [[String: String]]()
    }
    
    func showLoginVC() {
        let loginVC = self.storyboard!.instantiateViewController(withIdentifier: "loginController")
        show(loginVC, sender: self)
    }
}

extension SchoolSelectionViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return schoolList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BasicTitle", for: indexPath)
        
        let schoolDict = schoolList[safe: indexPath.row] ?? [String: String]()
        cell.textLabel?.text = schoolDict["schoolName"]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Preferences().baseURL = schoolList[safe: indexPath.row]?["schoolURL"] ?? ""
        Preferences().schoolName = schoolList[safe: indexPath.row]?["schoolCode"] ?? ""
        
        showLoginVC()
    }
}
