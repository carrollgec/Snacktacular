//
//  SpotPhotoCollectionViewCell.swift
//  Snacktacular
//
//  Created by Grace Carroll on 4/25/21.
//

import UIKit

class SpotPhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var photoImageView: UIImageView!
    
    var spot: Spot!
    var photo: Photo! {
        didSet {
            photo.loadImsge(spot: spot) { (success) in
                if success {
                    self.photoImageView.image = self.photo.image
                } else {
                    print("ERROR: no success in loading photo")
                }
            }
        }
    }
    
    
}
