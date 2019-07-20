//
//  MyMovieTableViewCell.swift
//  MyMovies
//
//  Created by Dongwoo Pae on 7/20/19.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import UIKit

protocol MyMovieTableViewCellDelegate {
    func seenButtonAction (for cell: MyMovieTableViewCell)
}

class MyMovieTableViewCell: UITableViewCell {

    @IBOutlet weak var myMovieTitleLabel: UILabel!
    @IBOutlet weak var updateButton: UIButton!
    
    var addedMovie: Movie? {
        didSet {
            updateView()
        }
    }
    
    var delegate: MyMovieTableViewCellDelegate?
    
    @IBAction func updateButtonTapped(_ sender: Any) {
        self.delegate?.seenButtonAction(for: self)
    }
    
    func updateView() {
        guard let addedMovie = addedMovie else {return}
        self.myMovieTitleLabel.text = addedMovie.title
        if addedMovie.hasWatched == false {
        self.updateButton.setTitle("Unwatched", for: .normal)
        } else {
        self.updateButton.setTitle("Watched", for: .normal)
        }
    }
}
