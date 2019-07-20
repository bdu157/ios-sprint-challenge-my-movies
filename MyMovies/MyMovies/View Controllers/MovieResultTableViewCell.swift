//
//  MovieResultTableViewCell.swift
//  MyMovies
//
//  Created by Dongwoo Pae on 7/20/19.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import UIKit

class MovieResultTableViewCell: UITableViewCell {

    var movieController:  MovieController?
    
    var movieRepresentation: MovieRepresentation?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBAction func addMovieTapped(_ sender: Any) {
        guard let movieRep = movieRepresentation else {return}
        self.movieController!.addMoive(for: movieRep)
    }
}
