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
    
    public var doPresentServiceView: Bool {
        get {
            return userDefaults.bool(forKey: "doPresentServiceView" )
        }
        set(value) {
            userDefaults.set(value, forKey: "doPresentServiceView" )
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
    
    public var isStudent: Bool {
        get {
            return userDefaults.bool(forKey: "isStudent" )
        }
        set(value) {
            userDefaults.set(value, forKey: "isStudent" )
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
}
