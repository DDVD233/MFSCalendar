//
//  UIView+O2CornerRadius.swift
//  MFSCalender
//
//  Created by David Dai on 2017/3/26.
//  Copyright © 2017年 David. All rights reserved.
//

import UIKit
import Crashlytics
import Kanna

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
            
            if let viewController = parentResponder as? UIViewController {
                return viewController
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
    func convertToDictionary() -> [String: Any]? {
        if let data = self.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
}

extension String {
    subscript(r: Range<Int>) -> String {
        get {
            let startIndex = self.index(self.startIndex, offsetBy: r.lowerBound)
            let endIndex = self.index(self.startIndex, offsetBy: r.upperBound + 1)

            return String(self[Range(uncheckedBounds: (startIndex, endIndex))])
        }
    }

    subscript(start: Int, end: Int) -> String {
        get {
            let startIndex = self.index(self.startIndex, offsetBy: start)
            let endIndex = self.index(self.startIndex, offsetBy: end + 1)
            return String(self[Range(uncheckedBounds: (startIndex, endIndex))])
        }
    }

    var utf8Encoded: Data {
        return self.data(using: .utf8)!
    }

    func convertToHtml(isTitle: Bool = false) -> NSAttributedString? {
        let font = UIFont.systemFont(ofSize: 15).fontName
        let fontSize = isTitle ? "23" : "16"
        CLSLogv("String to convert to HTML: %@", getVaList([self]))
        let htmlString = "<html>" +
                "<head>" +
                "<style>" +
                "body {" +
                "font-family: '\(font)';" +
                "font-size:\(fontSize)px;" +
                "text-decoration:none;" +
                "}" +
                "</style>" +
                "</head>" +
                "<body>" +
                self +
                "</body></head></html>"
        
        if let data = htmlString.data(using: .utf8, allowLossyConversion: true) {
            if let formattedHtmlString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil) {
                return formattedHtmlString
            }
        }

        return nil
    }
}



public extension UIColor {
    public convenience init(hexString: UInt32, alpha: CGFloat = 1.0) {
        let red = CGFloat((hexString & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((hexString & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat((hexString & 0x0000FF)) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    convenience init(hex: Int, a: CGFloat = 1.0) {
        self.init(
            red: (hex >> 16) & 0xFF,
            green: (hex >> 8) & 0xFF,
            blue: hex & 0xFF,
            a: a
        )
    }
    
    convenience init(red: Int, green: Int, blue: Int, a: CGFloat = 1.0) {
        self.init(
            red: CGFloat(red) / 255.0,
            green: CGFloat(green) / 255.0,
            blue: CGFloat(blue) / 255.0,
            alpha: a
        )
    }
}


extension UIView {
    func copyView() -> AnyObject {
        return NSKeyedUnarchiver.unarchiveObject(with: NSKeyedArchiver.archivedData(withRootObject: self))! as AnyObject
    }
}


extension UIImage {

    func imageResize(sizeChange: CGSize) -> UIImage {

        let hasAlpha = true
        let scale: CGFloat = 0.0 // Use scale factor of main screen

        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        self.draw(in: CGRect(origin: CGPoint.zero, size: sizeChange))

        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        return scaledImage!
    }

}

extension UITableView {
    func reloadData(with animation: UITableView.RowAnimation) {
        reloadSections(IndexSet(integersIn: 0..<numberOfSections), with: animation)
    }
}

extension Array where Element: Equatable {

    // Remove first collection element that is equal to the given `object`:
    mutating func remove(object: Element) {
        if let index = index(of: object) {
            remove(at: index)
        }
    }
}

extension Optional where Wrapped == String {
    func existsAndNotEmpty() -> Bool {
        if self == nil {
            return false
        } else if self!.isEmpty {
            return false
        } else {
            return true
        }
    }
}

extension Dictionary where Value == Any {
    mutating func removeNil() {
        for (key, value) in self {
            if value is NSNull {
                self[key] = ""
            }
        }
    }
}

extension Date {
    struct Gregorian {
        static let calendar = Calendar(identifier: .gregorian)
    }
    var startOfWeek: Date? {
        return Gregorian.calendar.date(from: Gregorian.calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self))
    }
}

extension Sequence {
    func splitBefore(
        separator isSeparator: (Iterator.Element) throws -> Bool
        ) rethrows -> [AnySequence<Iterator.Element>] {
        var result: [AnySequence<Iterator.Element>] = []
        var subSequence: [Iterator.Element] = []
        
        var iterator = self.makeIterator()
        while let element = iterator.next() {
            if try isSeparator(element) {
                if !subSequence.isEmpty {
                    result.append(AnySequence(subSequence))
                }
                subSequence = [element]
            }
            else {
                subSequence.append(element)
            }
        }
        result.append(AnySequence(subSequence))
        return result
    }
}

extension UINavigationBar {
    func removeBottomLine() {
        self.barStyle = .black
        self.barTintColor = UIColor(hexString: 0xFF7E79)
        self.isTranslucent = false
        self.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        self.shadowImage = UIImage()
    }
}

extension Character {
    var isUpperCase: Bool { return String(self) == String(self).uppercased() }
}

public extension Sequence {
    func group<U: Hashable>(by key: (Iterator.Element) -> U) -> [U:[Iterator.Element]] {
        var categories: [U: [Iterator.Element]] = [:]
        for element in self {
            let key = key(element)
            if case nil = categories[key]?.append(element) {
                categories[key] = [element]
            }
        }
        return categories
    }
}


