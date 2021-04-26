//
//  Photo.swift
//  Snacktacular
//
//  Created by Grace Carroll on 4/25/21.
//

import UIKit
import Firebase

class Photo {
    var image: UIImage
    var description: String
    var photoUserID: String
    var photoUserEmail: String
    var date: Date
    var photoURL: String
    var documentID: String
    
    var dictionary: [String: Any] {
        let timeIntervalDate = date.timeIntervalSince1970
        return ["description": description, "photoUserID": photoUserID, "photoUserEmail": photoUserEmail, "date": timeIntervalDate, "photoURL": photoURL]
    }
    
    init(image: UIImage, description: String, photoUserID: String, photoUserEmail: String, date: Date, photoURL: String, documentID: String) {
        self.image = image
        self.description = description
        self.photoUserID = photoUserID
        self.photoUserEmail = photoUserEmail
        self.date = date
        self.photoURL = photoURL
        self.documentID = documentID
    }
    
    convenience init() {
        let photoUserID = Auth.auth().currentUser?.uid ?? ""
        let photoUserEmail = Auth.auth().currentUser?.email ?? "unknown email"
        self.init(image: UIImage(), description: "", photoUserID: photoUserID, photoUserEmail: photoUserEmail, date: Date(), photoURL: "", documentID: "")
    }
    
    convenience init(dictionary: [String: Any]) {
        let description = dictionary["description"] as! String? ?? ""
        let photoUserID = dictionary["photoUserID"] as! String? ?? ""
        let photoUserEmail = dictionary["photoUserEmail"] as! String? ?? ""
        let timeIntervalDate = dictionary["date"] as! TimeInterval? ?? TimeInterval()
        let date = Date(timeIntervalSince1970: timeIntervalDate)
        let photoURL = dictionary["photoURL"] as! String? ?? ""
        self.init(image: UIImage(), description: description, photoUserID: photoUserID, photoUserEmail: photoUserEmail, date: date, photoURL: photoURL, documentID: "")
    }
    
    func saveData(spot: Spot, completion: @escaping (Bool) -> ()) {
        let db = Firestore.firestore()
        let storage = Storage.storage()
        // convert photo.image to data type to be saved in firebase storage
        guard let photoData = self.image.jpegData(compressionQuality: 0.5) else {
            print("ERROR: could not convert photo.image to Data.")
            return
        }
        // create meta data to be able to see image in firebase storage console
        let uploadMetaData = StorageMetadata()
        uploadMetaData.contentType = "image/jpeg"
        // create filename if necessary
        if documentID == "" {
            documentID = UUID().uuidString
        }
        // create storage reference to upload image file to spot's folder
        let storageRef = storage.reference().child(spot.documentID).child(documentID)
        // create upload task
        let uploadTask = storageRef.putData(photoData, metadata: uploadMetaData) { (metadata, error) in
            if let error = error {
                print("ERROR: upload for ref \(uploadMetaData) failed. \(error.localizedDescription)")
            }
        }
        // add observers
        uploadTask.observe(.success) { (snapshot) in
            print("Upload to firebase storage was successful.")
            //TODO: update with photourl for smoother image loading
            let dataToSave: [String: Any] = self.dictionary
            let ref = db.collection("spots").document(spot.documentID).collection("photos").document(self.documentID)
            ref.setData(dataToSave) { (error) in
                guard error == nil else {
                    print("ERROR: updating document \(error!.localizedDescription)")
                    return completion(false)
                }
                print("Updated document: \(self.documentID) in spot: \(spot.documentID)")
                completion(true)
            }
        }
        
        uploadTask.observe(.failure) { (snapshot) in
            if let error = snapshot.error {
                print("ERROR: upload task for file \(self.documentID) failed, in spot \(spot.documentID) with error \(error.localizedDescription).")
            }
            completion(false)
        }
    }
    
    func loadImsge(spot: Spot, completion: @escaping (Bool) -> ()) {
        guard spot.documentID != "" else {
            print("ERROR: did not pass a valid spot into loadImage")
            return
        }
        let storage = Storage.storage()
        let storageRef = storage.reference().child(spot.documentID).child(documentID)
        storageRef.getData(maxSize: 25*1024*1024) { (data, error) in
            if let error = error {
                print("ERROR: an error occured while reading data from file ref \(storageRef). error: \(error.localizedDescription)")
                return completion(false)
            } else {
                self.image = UIImage(data: data!) ?? UIImage()
                return completion(true)
            }
        }
    }
}
