//
//  ClassListViewController.swift
//  MFSCalendar
//
//  Created by 戴元平 on 2017/6/22.
//  Copyright © 2017年 David. All rights reserved.
//

import UIKit


class classListController:UIViewController {
    
    @IBOutlet var classListCollectionView: UICollectionView!
    let path = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
    
    var majorClasslist = [NSDictionary]()
    var minorClassList = [NSDictionary]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.classListCollectionView.delegate = self
        self.classListCollectionView.dataSource = self
        
        let classPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let path = classPath.appending("/CourseList.plist")
        if let classList = NSArray(contentsOfFile: path) {
            sortClasses(classList: classList)
        }
    }
    
    func sortClasses(classList: NSArray) {
        let notImportantClasses = ["Study Hall", "Assembly", "Break", "1st Period Prep", "Advisor", "USCoun", "US Dean"]
        
        majorClasslist = [NSDictionary]()
        minorClassList = [NSDictionary]()
        
        for (index, items) in classList.enumerated() {
            let classObject = items as! NSMutableDictionary
            classObject["index"] = index
            var isMinorClass = false
            
            guard let className = classObject["className"] as? String else {
                continue
            }
            
            for notImportantClass in notImportantClasses {
                if className.contains(notImportantClass) {
                    minorClassList.append(classObject)
                    isMinorClass = true
                    break
                }
            }
            
            if !isMinorClass {
                majorClasslist.append(classObject)
            }
        }
    }
}

extension classListController: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return majorClasslist.count
        case 1:
            return minorClassList.count
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "classListViewCell", for: indexPath) as! classListViewCell
        
        let row = indexPath.row
        
        var classObject: NSDictionary = [:]
        
        switch indexPath.section {
        case 0:
            classObject = majorClasslist[row]
        case 1:
            classObject = minorClassList[row]
        default:
            break
        }
        
        cell.title.text = classObject["className"] as? String
        
        if let sectionId = classObject["leadsectionid"] as? Int {
            let imagePath = path.appending("/\(sectionId)_profile.png")
            if let backgroundImage = UIImage(contentsOfFile: imagePath) {
                cell.backgroundImage.isHidden = false
                cell.darkCover.isHidden = false
                cell.backgroundImage.image = backgroundImage
            } else {
                cell.backgroundImage.isHidden = true
                cell.darkCover.isHidden = true
            }
            
            cell.backgroundImage.contentMode = .scaleAspectFill
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let row = indexPath.row
        var classObject: NSDictionary = [:]
        
        switch indexPath.section {
        case 0:
            classObject = majorClasslist[row]
        case 1:
            classObject = minorClassList[row]
        default:
            break
        }
        
        userDefaults?.set(classObject["index"], forKey: "indexForCourseToPresent")
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "classListHeaderViewCell", for: indexPath) as! classListHeaderViewCell
        if indexPath.section == 0 {
            view.textLabel.text = "Frequently Used"
        } else {
            view.textLabel.text = "Others"
        }
        
        return view
    }
}

extension classListController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let viewSize = UIScreen.main.bounds.size.width / 2
        return CGSize(width: viewSize, height: viewSize)
    }
}

class classListViewCell: UICollectionViewCell {
    @IBOutlet var backgroundImage: UIImageView!
    @IBOutlet var title: UILabel!
    
    @IBOutlet var darkCover: UIView!
}

class classListHeaderViewCell: UICollectionReusableView {
    @IBOutlet var textLabel: UILabel!
}
