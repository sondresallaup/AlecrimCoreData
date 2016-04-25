//
//  DataContextOptions.swift
//  AlecrimCoreData
//
//  Created by Vanderlei Martinelli on 2015-02-26.
//  Copyright (c) 2015 Alecrim. All rights reserved.
//

import Foundation
import CoreData

public enum StoreType {
    case SQLite
    case InMemory
}

public struct DataContextOptions {
    
    // MARK: - options valid for all instances
    
    public static var defaultBatchSize: Int = 20
    public static var defaultComparisonPredicateOptions: NSComparisonPredicateOptions = [.CaseInsensitivePredicateOption, .DiacriticInsensitivePredicateOption]

    @available(*, unavailable, renamed="defaultBatchSize")
    public static var batchSize: Int = 20
    
    @available(*, unavailable, renamed="defaultComparisonPredicateOptions")
    public static var stringComparisonPredicateOptions: NSComparisonPredicateOptions = [.CaseInsensitivePredicateOption, .DiacriticInsensitivePredicateOption]

    // MARK: -

    public let managedObjectModelURL: NSURL?
    public let persistentStoreURL: NSURL?
    
    // MARK: -
    
    public var storeType: StoreType = .SQLite
    public var configuration: String? = nil
    public var options: [NSObject : AnyObject] = [NSMigratePersistentStoresAutomaticallyOption : true, NSInferMappingModelAutomaticallyOption : true]
    
    // MARK: - THE constructor
    
    public init(managedObjectModelURL: NSURL, persistentStoreURL: NSURL) {
        self.managedObjectModelURL = managedObjectModelURL
        self.persistentStoreURL = persistentStoreURL
    }
    
    // MARK: - "convenience" initializers
    
    public init(managedObjectModelURL: NSURL) throws {
        let mainBundle = NSBundle.mainBundle()
        
        self.managedObjectModelURL = managedObjectModelURL
        self.persistentStoreURL = try mainBundle.defaultPersistentStoreURL()
    }
    
    public init(persistentStoreURL: NSURL) throws {
        let mainBundle = NSBundle.mainBundle()
        
        self.managedObjectModelURL = try mainBundle.defaultManagedObjectModelURL()
        self.persistentStoreURL = persistentStoreURL
    }
    
    public init() throws {
        let mainBundle = NSBundle.mainBundle()
        
        self.managedObjectModelURL = try mainBundle.defaultManagedObjectModelURL()
        self.persistentStoreURL = try mainBundle.defaultPersistentStoreURL()
    }
    
    // MARK: -

    public init(managedObjectModelBundle: NSBundle, managedObjectModelName: String, bundleIdentifier: String) throws {
        self.managedObjectModelURL = try managedObjectModelBundle.managedObjectModelURLForManagedObjectModelName(managedObjectModelName)
        self.persistentStoreURL = try managedObjectModelBundle.persistentStoreURLForManagedObjectModelName(managedObjectModelName, bundleIdentifier: bundleIdentifier)
    }
    
    /// Initializes ContextOptions with properties filled for use by main app and its extensions.
    ///
    /// - parameter managedObjectModelBundle:   The managed object model bundle. You can use `NSBundle(forClass: MyModule.MyDataContext.self)`, for example.
    /// - parameter managedObjectModelName:     The managed object model name without the extension. Example: `"MyGreatApp"`.
    /// - parameter bundleIdentifier:           The bundle identifier for use when creating the directory for the persisent store. Example: `"com.mycompany.MyGreatApp"`.
    /// - parameter applicationGroupIdentifier: The application group identifier (see Xcode target settings). Example: `"group.com.mycompany.MyGreatApp"` for iOS or `"12ABCD3EF4.com.mycompany.MyGreatApp"` for OS X where `12ABCD3EF4` is your team identifier.
    ///
    /// - returns: An initialized ContextOptions with properties filled for use by main app and its extensions.
    public init(managedObjectModelBundle: NSBundle, managedObjectModelName: String, bundleIdentifier: String, applicationGroupIdentifier: String) throws {
        self.managedObjectModelURL = try managedObjectModelBundle.managedObjectModelURLForManagedObjectModelName(managedObjectModelName)
        self.persistentStoreURL = try managedObjectModelBundle.persistentStoreURLForManagedObjectModelName(managedObjectModelName, bundleIdentifier: bundleIdentifier, applicationGroupIdentifier: applicationGroupIdentifier)
    }
    
}

// MARK: - Ubiquity (iCloud) helpers

extension DataContextOptions {
    
    #if os(OSX) || os(iOS)
    
    public var ubiquityEnabled: Bool {
        return self.storeType == .SQLite && self.options[NSPersistentStoreUbiquitousContainerIdentifierKey] != nil
    }
    
    public mutating func configureUbiquityWithContainerIdentifier(containerIdentifier: String, contentRelativePath: String = "Data/TransactionLogs", contentName: String = "UbiquityStore") {
        self.options[NSPersistentStoreUbiquitousContainerIdentifierKey] = containerIdentifier
        self.options[NSPersistentStoreUbiquitousContentURLKey] = contentRelativePath
        self.options[NSPersistentStoreUbiquitousContentNameKey] = contentName
        
        self.options[NSMigratePersistentStoresAutomaticallyOption] = true
        self.options[NSInferMappingModelAutomaticallyOption] = true
    }
 
    #endif
}


// MARK: - private NSBundle extensions

extension NSBundle {
    
    /// This variable is used to guess a managedObjectModelName.
    /// The provided kCFBundleNameKey we are using to determine the name will include spaces, whereas managed object model name uses underscores in place of spaces by default - hence why we are replacing " " with "_" here
    private var inferredManagedObjectModelName: String? {
        return "Toktok_Kl_r"
//        return (self.infoDictionary?[String(kCFBundleNameKey)] as? String)?.stringByReplacingOccurrencesOfString(" ", withString: "_")
    }
    
}

extension NSBundle {
    
    private func defaultManagedObjectModelURL() throws -> NSURL {
        guard let managedObjectModelName = self.inferredManagedObjectModelName else {
            throw AlecrimCoreDataError.InvalidManagedObjectModelURL
        }
        
        return try self.managedObjectModelURLForManagedObjectModelName(managedObjectModelName)
    }
    
    private func defaultPersistentStoreURL() throws -> NSURL {
        guard let managedObjectModelName = self.inferredManagedObjectModelName, let bundleIdentifier = self.bundleIdentifier else {
            throw AlecrimCoreDataError.InvalidPersistentStoreURL
        }
        
        return try self.persistentStoreURLForManagedObjectModelName(managedObjectModelName, bundleIdentifier: bundleIdentifier)
    }
    
}

extension NSBundle {
    
    private func managedObjectModelURLForManagedObjectModelName(managedObjectModelName: String) throws -> NSURL {
        guard let url = self.URLForResource(managedObjectModelName, withExtension: "momd") else {
            throw AlecrimCoreDataError.InvalidManagedObjectModelURL
        }
        
        return url
    }
    
    private func persistentStoreURLForManagedObjectModelName(managedObjectModelName: String, bundleIdentifier: String) throws -> NSURL {
        guard let applicationSupportURL = NSFileManager.defaultManager().URLsForDirectory(.ApplicationSupportDirectory, inDomains: .UserDomainMask).last else {
            throw AlecrimCoreDataError.InvalidPersistentStoreURL
        }
        
        let url = applicationSupportURL
            .URLByAppendingPathComponent(bundleIdentifier, isDirectory: true)
            .URLByAppendingPathComponent("CoreData", isDirectory: true)
            .URLByAppendingPathComponent((managedObjectModelName as NSString).stringByAppendingPathExtension("sqlite")!, isDirectory: false)
        
        return url
    }
    
    private func persistentStoreURLForManagedObjectModelName(managedObjectModelName: String, bundleIdentifier: String, applicationGroupIdentifier: String) throws -> NSURL {
        guard let containerURL = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier(applicationGroupIdentifier) else {
            throw AlecrimCoreDataError.InvalidPersistentStoreURL
        }
        
        let url = containerURL
            .URLByAppendingPathComponent("Library", isDirectory: true)
            .URLByAppendingPathComponent("Application Support", isDirectory: true)
            .URLByAppendingPathComponent(bundleIdentifier, isDirectory: true)
            .URLByAppendingPathComponent("CoreData", isDirectory: true)
            .URLByAppendingPathComponent((managedObjectModelName as NSString).stringByAppendingPathExtension("sqlite")!, isDirectory: false)
        
        return url
    }
    
}

// MARK: -

@available(*, unavailable, renamed="DataContextOptions")
public struct ContextOptions {
    
}
