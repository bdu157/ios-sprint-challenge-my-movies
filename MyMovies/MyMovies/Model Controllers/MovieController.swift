//
//  MovieController.swift
//  MyMovies
//
//  Created by Spencer Curtis on 8/17/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import Foundation
import CoreData

class MovieController {
    
    init() {
        fetchMoviesFromServer()
    }
    
    private let apiKey = "4cc920dab8b729a619647ccc4d191d5e"
    private let baseURL = URL(string: "https://api.themoviedb.org/3/search/movie")!
    
    func searchForMovie(with searchTerm: String, completion: @escaping (Error?) -> Void) {
        
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        
        let queryParameters = ["query": searchTerm,
                               "api_key": apiKey]
        
        components?.queryItems = queryParameters.map({URLQueryItem(name: $0.key, value: $0.value)})
        
        guard let requestURL = components?.url else {
            completion(NSError())
            return
        }
        
        URLSession.shared.dataTask(with: requestURL) { (data, _, error) in
            
            if let error = error {
                NSLog("Error searching for movie with search term \(searchTerm): \(error)")
                completion(error)
                return
            }
            
            guard let data = data else {
                NSLog("No data returned from data task")
                completion(NSError())
                return
            }
            
            do {
                let movieRepresentations = try JSONDecoder().decode(MovieRepresentations.self, from: data).results
                self.searchedMovies = movieRepresentations
                completion(nil)
            } catch {
                NSLog("Error decoding JSON data: \(error)")
                completion(error)
            }
        }.resume()
    }
    
    // MARK: - Properties
    
    var searchedMovies: [MovieRepresentation] = []
    
    
    // MARK: - Adding, updating, and deleting movies to/from CoreData and Firebase
    
    let baseURL2 = URL(string: "https://task-coredata.firebaseio.com/")!
    
    //Add Movie
    func addMoive(for selectedMovie: MovieRepresentation) {
        let movie = Movie(title: selectedMovie.title)
        self.put(movie: movie)
        
        self.saveToPersistentStore()
    }
    
    
        // PUT
    func put(movie: Movie, completion: @escaping (Error?) -> Void = {_ in}) {
        let identifier = movie.identifier?.uuidString
        
        let requestURL = baseURL2.appendingPathComponent(identifier!).appendingPathExtension("json")
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "PUT"
        
        do {
            guard let representation = movie.movieRepresentation else {
                completion(NSError())
                return
            }
            request.httpBody = try JSONEncoder().encode(representation)
        } catch {
            NSLog("Error encoding task \(movie): \(error)")
            completion(error)
            return
        }
        URLSession.shared.dataTask(with: request) { (_, _, error) in
            if let error = error {
                NSLog("Error PUTing task to server: \(error)")
                completion(error)
                return
            }
            completion(nil)
        }.resume()
    }
    
    
        // savetopersistentstore
    func saveToPersistentStore() {
        do {
            let moc = CoreDataStack.shared.mainContext
            try moc.save()
        } catch {
            NSLog("Error saving managed object context:\(error)")
        }
    }
    
    
    
    //(?) on Tasks, delete on tableview crashed without using performAndWait but mine is not crashing why?
    //Delete Movie from persistentStore
    func deleteMovie(for movie: Movie) {
        self.deleteTaskFromServer(for: movie)
        let moc = CoreDataStack.shared.mainContext
        moc.delete(movie)
        
        do {
            try moc.save()
        } catch {
            moc.reset()
            NSLog("Error saving managed object context:\(error)")
        }
    }
       //Delete from firebase
    func deleteTaskFromServer(for movie: Movie, completion: @escaping (Error?) -> Void = { _ in }) {
        guard let identifier = movie.identifier?.uuidString else {
            completion(NSError())
            return
        }
        let requestURL = baseURL2.appendingPathComponent(identifier).appendingPathExtension("json")
        var request = URLRequest(url: requestURL)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { (_, _, error) in
            if let error = error {
                NSLog("Error in deleting movie:\(error)")
                completion(error)
                return
            }
            completion(nil)
        }.resume()
    }
    
    
    //toggleButton
    func toggleSeen(for movie: Movie) {
        movie.hasWatched = !movie.hasWatched
    }
    
    //fetchMovieFromServer(firebase)
    func fetchMoviesFromServer(completion: @escaping (Error?) -> Void = { _ in}) {
        let requestURL = baseURL2.appendingPathExtension("json")
        
        URLSession.shared.dataTask(with: requestURL) { (data, _, error) in
            if let error = error {
                NSLog("Error fetching movie: \(error)")
                completion(error)
                return
            }
            
            guard let data = data else {
                NSLog("Error getting data")
                completion(error)
                return
            }
            
            var movieRepresentation: [MovieRepresentation] = []
            
            do {
                movieRepresentation = Array(try JSONDecoder().decode([String: MovieRepresentation].self, from: data).values)
                let backgroundContext = CoreDataStack.shared.container.newBackgroundContext()
                //for loop to check each one of movie to see if it already exsits in coreData. if it does then update if not create a new one
                var error: Error? = nil
                backgroundContext.performAndWait {
                    for movieRep in movieRepresentation {
                        let movie = self.fetchSingleMovieFromPersistentStore(forIdentifier: movieRep.identifier?.uuidString ?? "", backgroundContext: backgroundContext)
                        if let movie = movie {
                            if movie.title != movieRep.title || movie.identifier != movieRep.identifier || movie.hasWatched != movieRep.hasWatched {
                                self.update(for: movie, with: movieRep)
                            }
                        } else {
                            //use failable initializer to create new movies  (?) should this be assigned to addMovie so it can be created and saved??
                            let _ = Movie(movieRepresentation: movieRep, backgroundContext: backgroundContext)
                            //self.addMoive(for: movie!.movieRepresentation!)  - this actually creates itself
                        }
                    }
                    
                    do {
                        try backgroundContext.save()
                    } catch let saveError {
                        error = saveError
                    }
                }
                if let error = error { throw error}
                completion(nil)
            } catch {
                NSLog("Error decoding entry representations: \(error)")
                completion(error)
                return
            }
        }.resume()
    }
    
    //Update Movie
    func update(for movie: Movie, with movieRepresentation: MovieRepresentation) {
        movie.title = movieRepresentation.title
        movie.identifier = movieRepresentation.identifier
        movie.hasWatched = movieRepresentation.hasWatched!
    }
    
    //fetch from persistentstore that has same identifier as idenfitiers from fetched data from firebase
    func fetchSingleMovieFromPersistentStore(forIdentifier identifier: String, backgroundContext: NSManagedObjectContext) -> Movie? {
        let fetchRequest: NSFetchRequest<Movie> = Movie.fetchRequest()
        
        fetchRequest.predicate = NSPredicate(format: "identifier == %@", identifier) //based on identifier for fetchedData from firebase, "sort/filter" a movie that has same identiifer as one from firebase
        
        var result: Movie? = nil
        backgroundContext.performAndWait {
            do {
                result = try backgroundContext.fetch(fetchRequest).first
            } catch {
                NSLog("Error fetching task with uuid \(identifier): \(error)")
            }
        }
        return result
    }
}
