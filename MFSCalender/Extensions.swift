//
//  UIView+O2CornerRadius.swift
//  MFSCalender
//
//  Created by David Dai on 2017/3/26.
//  Copyright © 2017年 David. All rights reserved.
//

import UIKit

extension UIView {
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        // also  set(newValue)
        set {
            layer.cornerRadius = newValue
        }
    }
    
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.next
            if parentResponder is UIViewController {
                return parentResponder as! UIViewController!
            }
        }
        return nil
    }
}

extension String {
    func replace(target: String, withString: String) -> String {
        return self.replacingOccurrences(of: target, with: withString, options: NSString.CompareOptions.literal, range: nil)
    }
}

extension String {
    subscript(r: Range<Int>) -> String {
        get {
            let startIndex = self.index(self.startIndex, offsetBy: r.lowerBound)
            let endIndex = self.index(self.startIndex, offsetBy: r.upperBound+1)
            
            return self[Range(uncheckedBounds: (startIndex, endIndex))]
        }
    }
    
    subscript(start: Int, end: Int) -> String {
        get {
            let startIndex = self.index(self.startIndex, offsetBy: start)
            let endIndex = self.index(self.startIndex, offsetBy: end+1)
            return self[Range(uncheckedBounds: (startIndex, endIndex))]
        }
    }
    
    var utf8Encoded: Data {
        return self.data(using: .utf8)!
    }
    
    func convertToHtml() -> NSAttributedString? {
        let htmlString = "<html>" +
            "<head>" +
            "<style>" +
            "body {" +
            "font-family: 'Helvetica';" +
            "font-size:15px;" +
            "text-decoration:none;" +
            "}" +
            "</style>" +
            "</head>" +
            "<body>" +
            self +
        "</body></head></html>"
        
        if let data = htmlString.data(using: .utf8, allowLossyConversion: true) {
            if let formattedHtmlString = try? NSAttributedString(data: data, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil) {
                return formattedHtmlString
            }
        }
        
        return nil
    }
}

extension UIColor {
    public convenience init(hexString: UInt32, alpha: CGFloat = 1.0) {
        let red     = CGFloat((hexString & 0xFF0000) >> 16) / 255.0
        let green   = CGFloat((hexString & 0x00FF00) >> 8 ) / 255.0
        let blue    = CGFloat((hexString & 0x0000FF)      ) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}


extension UIView
{
    func copyView() -> AnyObject
    {
        return NSKeyedUnarchiver.unarchiveObject(with: NSKeyedArchiver.archivedData(withRootObject: self))! as AnyObject
    }
}


extension UIImage {
    
    func imageResize (sizeChange:CGSize)-> UIImage{
        
        let hasAlpha = true
        let scale: CGFloat = 0.0 // Use scale factor of main screen
        
        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        self.draw(in: CGRect(origin: CGPoint.zero, size: sizeChange))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        return scaledImage!
    }
    
}

extension UITableView {
    func reloadData(with animation: UITableViewRowAnimation) {
        reloadSections(IndexSet(integersIn: 0..<numberOfSections), with: animation)
    }
}

public let userDefaults = UserDefaults(suiteName: "group.org.dwei.MFSCalendar")
public let userDocumentPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
