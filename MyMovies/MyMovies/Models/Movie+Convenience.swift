//
//  Movie+Convenience.swift
//  MyMovies
//
//  Created by Dongwoo Pae on 7/20/19.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import Foundation
import CoreData

extension Movie {
    
    //computed property for sectionTitle
    var sectionMovie: String {
        if hasWatched == true {
            return "Watched"
        } else {
            return "Unwatched"
        }
    }
    
    var movieRepresentation: MovieRepresentation? {
        guard let title = title else {return nil}
        
        return MovieRepresentation(title: title, identifier: identifier, hasWatched: hasWatched)
    }
    
    
    convenience init(title: String, identifier: UUID = UUID(), hasWatched: Bool = false, context: NSManagedObjectContext = CoreDataStack.shared.mainContext) {
        self.init(context: context)
        self.title = title
        self.identifier = identifier
        self.hasWatched = hasWatched
    }
}
