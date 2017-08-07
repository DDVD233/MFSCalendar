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
        var i = 1
        let sortedClass: NSMutableArray = []
        for _ in 1...8 {
            for items in self.listClasses {
                let dict = items as! NSDictionary
                let periodNumber = Int(dict["period"] as! String)!
                if (periodNumber == i) {
                    sortedClass.add(dict)
                }
            }
            i += 1
        }
        self.listClasses = sortedClass
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func unWindSegueBack(segue: UIStoryboardSegue) {
    }
}

extension ADay: UITableViewDelegate, UITableViewDataSource {
    //    the number of the cell
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

        cell?.ClassName.text = rowDict["name"] as? String
        cell?.PeriodNumber.text = rowDict["period"] as? String
        let inFormatter = DateFormatter()
        inFormatter.dateFormat = "HH:mm"
        let PeriodNumberInt = Int(rowDict["period"] as! String)!
        var meetTime:String? = ""

        switch PeriodNumberInt {
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
        cell?.PeriodTime.text = meetTime!
        let roomN = rowDict["room"] as? String
        cell?.RoomNumber.text = roomN

        return cell!
    }
}


class AddClass: UITableViewController, UIPickerViewDelegate, UIPickerViewDataSource {


    @IBOutlet weak var txtClassName: UITextField!
    @IBOutlet weak var PeriodPicker: UIPickerView!
    @IBOutlet weak var roomNumber: UITextField!
    @IBOutlet weak var dayPicker: UIPickerView!


    var PickerData: NSDictionary!
    var PickerPeriod: NSArray!
    var PickerPeriodData: NSArray!

    var dayPickerData: NSDictionary!
    var dayPickerDay: NSArray!
    var dayPickerDayData: NSArray!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.dayPicker.delegate = self
        self.dayPicker.dataSource = self
        self.PeriodPicker.delegate = self
        self.PeriodPicker.dataSource = self

        var pickerPath = Bundle.main.path(forResource: "periodPicker", ofType: "plist")
        self.PickerData = NSDictionary(contentsOfFile: pickerPath!)

        pickerPath = Bundle.main.path(forResource: "dayPicker", ofType: "plist")
        self.dayPickerData = NSDictionary(contentsOfFile: pickerPath!)

        self.PickerPeriod = self.PickerData.allKeys as NSArray!
        self.dayPickerDay = self.dayPickerData.allKeys as NSArray!

        self.PickerPeriodData = self.PickerData[self.PickerPeriod[0] as! String] as! NSArray
        self.dayPickerDayData = self.dayPickerData[self.dayPickerDay[0] as! String] as! NSArray

//        if !UIAccessibilityIsReduceTransparencyEnabled() {
//        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.light)
//        let blurEffectView = UIVisualEffectView(effect: blurEffect)
//        //always fill the view
//        blurEffectView.frame = self.view.bounds
//        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        
//        self.view.insertSubview(blurEffectView, at: 0)
//        }
    }

    func numberOfComponents(in PeriodPicker: UIPickerView) -> Int {
        return 2
    }


    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == 1 {
            if (component == 0) {
                return self.PickerPeriod.count
            } else {
                return self.PickerPeriodData.count
            }
        } else {
            if (component == 0) {
                return self.dayPickerDay.count
            } else {
                return self.dayPickerDayData.count
            }
        }
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView.tag == 1 {
            if (component == 0) {
                return self.PickerPeriod[row] as? String
            } else {
                return self.PickerPeriodData[row] as? String
            }
        } else {
            if (component == 0) {
                return self.dayPickerDay[row] as? String
            } else {
                return self.dayPickerDayData[row] as? String
            }
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView.tag == 1 {
            if (component == 0) {
                let Select = self.PickerPeriod[row] as! String
                self.PickerPeriodData = self.PickerData[Select] as! NSArray
                self.PeriodPicker.reloadComponent(1)
            }
        } else {
            if (component == 0) {
                let Select = self.dayPickerDay[row] as! String
                self.dayPickerDayData = self.dayPickerData[Select] as! NSArray
                self.dayPicker.reloadComponent(1)
            }
        }
    }

    @IBAction func Save(_ sender: Any) {
        if (txtClassName.text?.isEmpty)! {

        } else {
            let row2 = self.PeriodPicker.selectedRow(inComponent: 1)
            let selectedPeriod = self.PickerPeriodData[row2] as! String
            let daySelected = self.dayPickerDayData[self.dayPicker.selectedRow(inComponent: 1)] as! String
            NSLog("running!")
            let plistPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
            let fileName = "/Class" + daySelected + ".plist"
            let path = plistPath.appending(fileName)
            let array = NSMutableArray(contentsOfFile: path)
            print(array!)
            var periodExists = false
            for (index, items) in array!.enumerated() {
                let classes = items as! NSDictionary
                if (classes["period"] as! String) == selectedPeriod {
                    periodExists = true
                    let alertController = UIAlertController(title: "Class exists",
                                                            message: "The class already exists! Do you want to override the class?", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                    let okAction = UIAlertAction(title: "Yes", style: .default, handler: {
                        action in
                        array?.removeObject(at: index)
                    })
                    alertController.addAction(cancelAction)
                    alertController.addAction(okAction)
                    self.present(alertController, animated: true, completion: nil)
                    break
                }
            }
            
            if periodExists {
                
            }
            let AddData = ["name": txtClassName.text!, "period": selectedPeriod, "room": roomNumber.text!]
            array?.add(AddData)
            NSLog(txtClassName.text!)
            array?.write(toFile: path, atomically: true)
            
            userDefaults?.set(true, forKey: "reloadTable")
            dismiss(animated: true)
        }
    }
}
