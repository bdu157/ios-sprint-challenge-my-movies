//
//  CoreDataStack.swift
//  MyMovies
//
//  Created by Dongwoo Pae on 7/20/19.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStack {
    static let shared = CoreDataStack()
    
    // stored property
    lazy var container: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Movie")
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error {
                fatalError("Failed to load persistent stores: \(error)")
            }
        })
        //add merging from Parent context
        
        return container
    }()
    
    //computed property
    var mainContext: NSManagedObjectContext {
        return self.container.viewContext
    }
    
    //add save method for fetched data from firebase
    
}
