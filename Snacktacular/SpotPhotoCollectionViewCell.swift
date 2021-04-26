//
//  SpotPhotoCollectionViewCell.swift
//  Snacktacular
//
//  Created by Grace Carroll on 4/25/21.
//

import UIKit
import SDWebImage

class SpotPhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var photoImageView: UIImageView!
    
    var spot: Spot!
    var photo: Photo! {
        didSet {
            if let url = URL(string: self.photo.photoURL) {
                self.photoImageView.sd_imageTransition = .fade
                self.photoImageView.sd_imageTransition?.duration = 0.5
                self.photoImageView.sd_setImage(with: url)
            } else {
                print("ERROR: photoURL didn't work")
                self.photo.loadImsge(spot: self.spot) { (success) in
                    self.photo.saveData(spot: self.spot) { (success) in
                        print("image update with url")
                    }
                }
            }
        }
    }
}
