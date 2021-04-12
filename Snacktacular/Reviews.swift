//
//  Reviews.swift
//  Snacktacular
//
//  Created by Grace Carroll on 4/12/21.
//

import Foundation
import Firebase

class Reviews {
    
    var reviewArray: [Review] = []
    var db: Firestore!
    
    init() {
        db = Firestore.firestore()
    }
    
}
