//
//  UserDefaults.swift
//  MFSCalendar
//
//  Created by David on 10/24/17.
//  Copyright © 2017 David. All rights reserved.
//
// TODO: Add userdefault class


import Foundation

public class Preferences {
    public var username: String? {
        get {
            return userDefaults.string(forKey: "username" )
        }
        set(value) {
            userDefaults.set(value, forKey: "username" )
        }
    }
    
    public var password: String? {
        get {
            return userDefaults.string(forKey: "password" )
        }
        set(value) {
            userDefaults.set(value, forKey: "password" )
        }
    }
    
    public var baseURL: String {
        get {
            switch self.schoolName ?? "" {
            case "MFS":
                return "https://mfriends.myschoolapp.com"
            case "CMH":
                return "https://catholicmemorial-hs.myschoolapp.com"
            default:
                return ""
            }
        }
    }
    
//    public var termSuffix: String? {
//        get {
//            return userDefaults.string(forKey: "termSuffix")
//        }
//        set(value) {
//            userDefaults.set(value, forKey: "termSuffix" )
//        }
//    }
    
    public var photoLink: String? {
        get {
            return userDefaults.string(forKey: "photoLink")
        }
        set(value) {
            userDefaults.set(value, forKey: "photoLink" )
        }
    }
    
    public var davidBaseURL: String {
        get {
            return "https://dwei.org"
        }
        set(value) {
            userDefaults.set(value, forKey: "baseURL" )
        }
    }
    
    public var schoolCode: String? {
        get {
            return userDefaults.string(forKey: "schoolCode" )
        }
        set(value) {
            userDefaults.set(value, forKey: "schoolCode" )
        }
    }
    
    public var schoolName: String? {
        get {
            return userDefaults.string(forKey: "schoolName" ) ?? "MFS"
        }
        set(value) {
            userDefaults.set(value, forKey: "schoolName" )
        }
    }
    
    public var firstName: String? {
        get {
            return userDefaults.string(forKey: "firstName" )
        }
        set(value) {
            userDefaults.set(value, forKey: "firstName" )
        }
    }
    
    public var lastName: String? {
        get {
            return userDefaults.string(forKey: "lastName" )
        }
        set(value) {
            userDefaults.set(value, forKey: "lastName" )
        }
    }
    
    public var token: String? {
        get {
            return userDefaults.string(forKey: "token" )
        }
        set(value) {
            userDefaults.set(value, forKey: "token" )
        }
    }
    
    public var userID: String? {
        get {
            return userDefaults.string(forKey: "userID" )
        }
        set(value) {
            userDefaults.set(value, forKey: "userID" )
        }
    }
    
    public var email: String? {
        get {
            return userDefaults.string(forKey: "email" )
        }
        set(value) {
            userDefaults.set(value, forKey: "email" )
        }
    }
    
    public var lockerNumber: String? {
        get {
            return userDefaults.string(forKey: "lockerNumber" )
        }
        set(value) {
            userDefaults.set(value, forKey: "lockerNumber" )
        }
    }
    
    public var lockerCombination: String? {
        get {
            return userDefaults.string(forKey: "lockerCombination" )
        }
        set(value) {
            userDefaults.set(value, forKey: "lockerCombination" )
        }
    }
    
    public var emailName: String? {
        get {
            return userDefaults.string(forKey: "emailName" )
        }
        set(value) {
            userDefaults.set(value, forKey: "emailName" )
        }
    }
    
    public var currentDurationDescriptionOnline: String? {
        get {
            return userDefaults.string(forKey: "currentDurationDescriptionOnline" )
        }
        set(value) {
            userDefaults.set(value, forKey: "currentDurationDescriptionOnline" )
        }
    }
    
    public var durationDescription: String? {
        get {
            return userDefaults.string(forKey: "durationDescription" )
        }
        set(value) {
            userDefaults.set(value, forKey: "durationDescription" )
        }
    }
    
    public var emailPassword: String? {
        get {
            return userDefaults.string(forKey: "emailPassword" )
        }
        set(value) {
            userDefaults.set(value, forKey: "emailPassword" )
        }
    }
    
    public var emailIDToDisplay: String? {
        get {
            return userDefaults.string(forKey: "emailIDToDisplay" )
        }
        set(value) {
            userDefaults.set(value, forKey: "emailIDToDisplay" )
        }
    }
    
    public var refreshDate: String? {
        get {
            return userDefaults.string(forKey: "refreshDate" )
        }
        set(value) {
            userDefaults.set(value, forKey: "refreshDate" )
        }
    }
    
    public var servicePassword: String? {
        get {
            return userDefaults.string(forKey: "servicePassword" )
        }
        set(value) {
            userDefaults.set(value, forKey: "servicePassword" )
        }
    }
    
    public var serviceUsername: String? {
        get {
            return userDefaults.string(forKey: "serviceUsername" )
        }
        set(value) {
            userDefaults.set(value, forKey: "serviceUsername" )
        }
    }
    
    public var durationID: String? {
        get {
            return userDefaults.string(forKey: "durationID" )
        }
        set(value) {
            userDefaults.set(value, forKey: "durationID" )
        }
    }
    
    public var currentQuarter: Int {
        get {
            return userDefaults.integer(forKey: "currentQuarter" )
        }
        set(value) {
            userDefaults.set(value, forKey: "currentQuarter" )
        }
    }
    
    public var currentQuarterOnline: Int {
        get {
            return userDefaults.integer(forKey: "currentQuarterOnline" )
        }
        set(value) {
            userDefaults.set(value, forKey: "currentQuarterOnline" )
        }
    }
    
    public var currentDurationIDOnline: Int {
        get {
            return userDefaults.integer(forKey: "currentDurationIDOnline" )
        }
        set(value) {
            userDefaults.set(value, forKey: "currentDurationIDOnline" )
        }
    }
    
    public var indexForCourseToPresent: Int {
        get {
            return userDefaults.integer(forKey: "indexForCourseToPresent" )
        }
        set(value) {
            userDefaults.set(value, forKey: "indexForCourseToPresent" )
        }
    }
    
    public var indexIdForAssignmentToPresent: Int {
        get {
            return userDefaults.integer(forKey: "indexIdForAssignmentToPresent" )
        }
        set(value) {
            userDefaults.set(value, forKey: "indexIdForAssignmentToPresent" )
        }
    }
    
    public var idForAssignmentToPresent: Int {
        get {
            return userDefaults.integer(forKey: "idForAssignmentToPresent" )
        }
        set(value) {
            userDefaults.set(value, forKey: "idForAssignmentToPresent" )
        }
    }
    
    public var topicID: Int {
        get {
            return userDefaults.integer(forKey: "topicID" )
        }
        set(value) {
            userDefaults.set(value, forKey: "topicID" )
        }
    }
    
    public var gradeLevel: Int {
        get {
            return userDefaults.integer(forKey: "gradeLevel" )
        }
        set(value) {
            userDefaults.set(value, forKey: "gradeLevel" )
        }
    }
    
    public var dataBuild: Int {
        get {
            return userDefaults.integer(forKey: "dataBuild" )
        }
        set(value) {
            userDefaults.set(value, forKey: "dataBuild" )
        }
    }
    
    public var topicIndexID: Int {
        get {
            return userDefaults.integer( forKey: "topicIndexID" )
        }
        set(value) {
            userDefaults.set( value, forKey: "topicIndexID" )
        }
    }
    
    public var version: Int {
        get {
            return userDefaults.integer( forKey: "version" )
        }
        set(value) {
            userDefaults.set( value, forKey: "version" )
        }
    }
    
    public var isFirstTimeLogin: Bool {
        get {
            return userDefaults.object(forKey: "isFirstTimeLogin" ) as? Bool ?? true
        }
        set(value) {
            userDefaults.set(value, forKey: "isFirstTimeLogin" )
        }
    }
    
    public var doUpdateQuarter: Bool {
        get {
            return userDefaults.object(forKey: "doUpdateQuarter" ) as? Bool ?? true
        }
        set(value) {
            userDefaults.set(value, forKey: "doUpdateQuarter" )
        }
    }
    
    public var doPresentServiceView: Bool {
        get {
            return userDefaults.bool(forKey: "doPresentServiceView" )
        }
        set(value) {
            userDefaults.set(value, forKey: "doPresentServiceView" )
        }
    }
    
    public var didPresentCapstoneAd: Bool {
        get {
            return userDefaults.bool(forKey: "didPresentCapstoneAd" )
        }
        set(value) {
            userDefaults.set(value, forKey: "didPresentCapstoneAd" )
        }
    }
    
    public var didLogin: Bool {
        get {
            return userDefaults.bool(forKey: "didLogin" )
        }
        set(value) {
            userDefaults.set(value, forKey: "didLogin" )
        }
    }
    
    public var isDev: Bool {
        get {
            return userDefaults.bool(forKey: "isDev" )
        }
        set(value) {
            userDefaults.set(value, forKey: "isDev" )
        }
    }
    
    public var isInStepChallenge: Bool {
        get {
            return userDefaults.bool(forKey: "isInStepChallenge" )
        }
        set(value) {
            userDefaults.set(value, forKey: "isInStepChallenge" )
        }
    }
    
    public var isStudent: Bool {
        get {
            return userDefaults.object(forKey: "isStudent" ) as? Bool ?? true
        }
        set(value) {
            userDefaults.set(value, forKey: "isStudent" )
        }
    }
    
    // Update any necessary data after opening, then mark the value as true.
    public var didOpenAfterUpdate: Bool {
        get {
            return userDefaults.bool(forKey: "didOpenAfterUpdate" )
        }
        set(value) {
            userDefaults.set(value, forKey: "didOpenAfterUpdate" )
        }
    }
    
    public var isiPhoneX: Bool {
        get {
            return userDefaults.bool(forKey: "isiPhoneX" )
        }
        set(value) {
            userDefaults.set(value, forKey: "isiPhoneX" )
        }
    }
    
    public var courseInitialized: Bool {
        get {
            return userDefaults.bool(forKey: "courseInitialized" )
        }
        set(value) {
            userDefaults.set(value, forKey: "courseInitialized" )
        }
    }
    
    public var loginTime: Date? {
        get {
            return userDefaults.object(forKey: "loginTime" ) as? Date
        }
        set(value) {
            userDefaults.set(value, forKey: "loginTime" )
        }
    }
    
    public var reviewDate: Date? {
        get {
            return userDefaults.object(forKey: "reviewDate" ) as? Date
        }
        set(value) {
            userDefaults.set(value, forKey: "reviewDate" )
        }
    }
    
    public var lastEmailUpdate: Date? {
        get {
            return userDefaults.object(forKey: "lastEmailUpdate" ) as? Date
        }
        set(value) {
            userDefaults.set(value, forKey: "lastEmailUpdate" )
        }
    }
}
