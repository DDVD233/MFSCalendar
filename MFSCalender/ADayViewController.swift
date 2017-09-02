//
//  A Day.swift
//  MFSCalender
//
//  Created by David Dai on 2017/2/25.
//  Copyright © 2017年 David. All rights reserved.
//

import UIKit

class customCell: UITableViewCell {

    @IBOutlet weak var ClassName: UILabel!

    @IBOutlet weak var PeriodNumber: UILabel!

    @IBOutlet weak var RoomNumber: UILabel!

    @IBOutlet weak var PeriodTime: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}

class ADay: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    var listClasses: NSMutableArray = []

    override func viewDidLoad() {
        // Do any additional setup after loading the view, typically from a nib.
        super.viewDidLoad()
        dataFetching()
        self.tableView.separatorStyle = .none

        if !UIAccessibilityIsReduceTransparencyEnabled() {
            self.view.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName:"background.png"))
            let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.light)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            //always fill the view
            blurEffectView.frame = self.view.bounds
            blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            self.view.insertSubview(blurEffectView, at: 0)
        }
    }

    override func viewDidAppear(_ animated: Bool) {

        if userDefaults?.bool(forKey: "reloadTable") != false {
            self.dataFetching()
            self.tableView.reloadData()
            userDefaults?.set(false, forKey: "reloadTable")
            NSLog("table reloaded")
        }
    }

    func dataFetching() {

        let daySelected = userDefaults?.string(forKey: "daySelect")
        self.title = daySelected! + " Day"
        NSLog("Day: %@", daySelected!)
        let plistPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let fileName = "/Class" + daySelected! + ".plist"
        NSLog(fileName)
        let path = plistPath.appending(fileName)
        NSLog(path)

        self.listClasses = NSMutableArray(contentsOfFile: path)!
        print(listClasses)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func unWindSegueBack(segue: UIStoryboardSegue) {
    }
}

extension ADay: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection selection: Int) -> Int {
        return self.listClasses.count
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        self.tableView.setEditing(editing, animated: true)
    }


    //    Icon Setup
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }

    //    Delete Rows
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        NSLog("Rows", self.listClasses.count)
        let IndexPaths = NSArray(array: [indexPath])
        let plistPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let path = plistPath.appending("/ClassA.plist")
        self.listClasses.removeObject(at: indexPath.row)
        NSLog("Rows", self.listClasses.count)
        self.listClasses.write(toFile: path, atomically: false)
        self.tableView.deleteRows(at: IndexPaths as! [IndexPath], with: .fade)
    }

    @IBAction func Edit(_ sender: Any) {
        setEditing(true, animated: true)
    }


    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "cellIdentifier", for: indexPath as IndexPath) as? customCell

        let row = indexPath.row

        let rowDict = self.listClasses[row] as! NSDictionary

        cell?.ClassName.text = rowDict["className"] as? String
        if let period = rowDict["period"] as? Int {
            cell?.PeriodNumber.text = String(describing: period)

            var meetTime: String = ""

            switch period {
            case 1: meetTime = "8:00 - 8:43"
            case 2: meetTime = "8:47 - 9:30"
            case 3: meetTime = "9:34 - 10:34"
            case 4: meetTime = "10:44 - 11:27"
            case 5: meetTime = "11:31 - 12:14"
            case 6: meetTime = "12:14 - 12:57"
            case 7: meetTime = "13:40 - 14:23"
            case 8: meetTime = "14:27 - 15: 10"
            default: meetTime = "Error!"
            }

            cell?.PeriodTime.text = meetTime
        }

        let roomN = rowDict["roomNumber"] as? String
        cell?.RoomNumber.text = roomN

        return cell!
    }
}

