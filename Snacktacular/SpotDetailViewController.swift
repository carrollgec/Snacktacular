//
//  SpotDetailViewController.swift
//  Snacktacular
//
//  Created by Grace Carroll on 3/31/21.
//

import UIKit
import GooglePlaces
import MapKit
import Contacts

class SpotDetailViewController: UIViewController {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var addressTextField: UITextField!
    @IBOutlet weak var ratingLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var saveBarButton: UIBarButtonItem!
    @IBOutlet weak var cancelBarButton: UIBarButtonItem!
    
    var locationManager: CLLocationManager!
    var spot: Spot!
    var photo: Photo!
    let regionDistance: CLLocationDegrees = 750.0
    var imagePickerController = UIImagePickerController()
    var reviews: Reviews!
    var photos: Photos!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //hide keyboard if tapped outside a field
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
        
        tableView.delegate = self
        tableView.dataSource = self
        collectionView.delegate = self
        collectionView.dataSource = self
        imagePickerController.delegate = self
        
        getLocation()
        
        if spot == nil {
            spot = Spot()
        } else {
            disableTextEditing()
            cancelBarButton.hide()
            saveBarButton.hide()
            navigationController?.setToolbarHidden(true, animated: true)
        }
        
        
        setupMapView()
        reviews = Reviews()
        photos = Photos()
        updateUserInterface()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if spot.documentID != "" {
            self.navigationController?.setToolbarHidden(true, animated: true)
        }
        reviews.loadData(spot: spot) {
            self.tableView.reloadData()
            if self.reviews.reviewArray.count == 0 {
                self.ratingLabel.text = "-.-"
            } else {
                let sum = self.reviews.reviewArray.reduce(0) {$0 + $1.rating}
                var avgRating = Double(sum) / Double(self.reviews.reviewArray.count)
                avgRating = ((avgRating * 10).rounded()) / 10
                self.ratingLabel.text = "\(avgRating)"
            }
        }
        photos.loadData(spot: spot) {
            self.collectionView.reloadData()
        }
    }
    
    func setupMapView() {
        let region = MKCoordinateRegion(center: spot.coordinate, latitudinalMeters: regionDistance, longitudinalMeters: regionDistance)
        mapView.setRegion(region, animated: true)
    }
    
    func updateUserInterface() {
        nameTextField.text = spot.name
        addressTextField.text = spot.address
        updateMap()
    }
    
    func disableTextEditing() {
        nameTextField.isEnabled = false
        addressTextField.isEnabled = false
        nameTextField.backgroundColor = .clear
        addressTextField.backgroundColor = .clear
        nameTextField.borderStyle = .none
        addressTextField.borderStyle = .none
    }
    
    func updateMap() {
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(spot)
        mapView.setCenter(spot.coordinate, animated: true)
    }
    
    func updateFromInterface() {
        spot.name = nameTextField.text!
        spot.address = addressTextField.text!
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        updateFromInterface()
        switch segue.identifier ?? "" {
        case "AddReview":
            let navigationController = segue.destination as! UINavigationController
            let destination = navigationController.viewControllers.first as! ReviewTableViewController
            destination.spot = spot
        case "ShowReview":
            let destination = segue.destination as! ReviewTableViewController
            let selectedIndexPath = tableView.indexPathForSelectedRow!
            destination.review = reviews.reviewArray[selectedIndexPath.row]
            destination.spot = spot
            destination.photo = photo
        case "AddPhoto":
            let navigationController = segue.destination as! UINavigationController
            let destination = navigationController.viewControllers.first as! PhotoViewController
            destination.spot = spot
        case "ShowPhoto":
            let destination = segue.destination as! PhotoViewController
            guard let selectedIndexPath = collectionView.indexPathsForSelectedItems?.first else {
                print("ERROR: couldn't get selected collectionView item")
                return
            }
            destination.photo = photos.photoArray[selectedIndexPath.row]
            destination.spot = spot
        default:
            print("Couldn't find a case for segue identifier: \(segue.identifier)")
        }
    }
    
    func saveCancelAlert(title: String, message: String, segueIdentifier: String) {
        let alertController = UIAlertController(title: title, message: message , preferredStyle: .alert)
        let saveAction = UIAlertAction(title: "Save", style: .default) { (_) in
            self.spot.saveData { (success) in
                self.saveBarButton.title = "Done"
                self.cancelBarButton.hide()
                self.navigationController?.setToolbarHidden(true, animated: true)
                self.disableTextEditing()
                if segueIdentifier == "AddReview" {
                    self.performSegue(withIdentifier: segueIdentifier, sender: nil)
                } else {
                    self.cameraOrLibraryAlert()
                }
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func leaveViewController() {
        let isPresentingInAddMode = presentingViewController is UINavigationController
        if isPresentingInAddMode {
            dismiss(animated: true, completion: nil)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    func cameraOrLibraryAlert() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let photoLibraryAction = UIAlertAction(title: "Photo Library", style: .default) { (_) in
            self.accessPhotoLibrary()
        }
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { (_) in
            self.accessCamera()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(photoLibraryAction)
        alertController.addAction(cameraAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil )
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        leaveViewController()
    }
    
    @IBAction func nameFieldChanged(_ sender: UITextField) {
        // prevent title containing only blank spaces from being saved
        let noSpaces = nameTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        if noSpaces != "" {
            saveBarButton.isEnabled = true
        } else {
            saveBarButton.isEnabled = false
        }
    }
    
    
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        updateFromInterface()
        spot.saveData { (success) in
            if success {
                self.leaveViewController()
            } else {
                self.oneButtonAlert(title: "Save Failed", message: "For some reason, data would not save to the cloud.")
            }
        }
    }
    
    @IBAction func lookupButtonPressed(_ sender: UIBarButtonItem) {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        present(autocompleteController, animated: true, completion: nil)
    }
    
    @IBAction func ratingButtonPressed(_ sender: UIButton) {
        if spot.documentID == "" {
            saveCancelAlert(title: "This Venue Has Not Been Saved", message: "You must save this venue before you can review it.", segueIdentifier: "AddReview")
        } else {
            performSegue(withIdentifier: "AddReview", sender: nil)
        }
    }
    
    @IBAction func photoButtonPressed(_ sender: UIButton) {
        if spot.documentID == "" {
            saveCancelAlert(title: "This Venue Has Not Been Saved", message: "You must save this venue before you can add a photo.", segueIdentifier: "AddPhoto")
        } else {
            cameraOrLibraryAlert()
        }
    }
    
    
    
}

extension SpotDetailViewController: GMSAutocompleteViewControllerDelegate {

  // Handle the user's selection.
  func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
    spot.name = place.name ?? "Unknown Place"
    spot.address = place.formattedAddress ?? "Unknown Address"
    spot.coordinate = place.coordinate
    updateUserInterface()
    dismiss(animated: true, completion: nil)
  }

  func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
    // TODO: handle the error.
    print("Error: ", error.localizedDescription)
  }

  // User canceled the operation.
  func wasCancelled(_ viewController: GMSAutocompleteViewController) {
    dismiss(animated: true, completion: nil)
  }

}

extension SpotDetailViewController: CLLocationManagerDelegate {
    
    func getLocation() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("Checking authentication status.")
        handleAuthenticalStatus(status: status)
    }
    
    func handleAuthenticalStatus(status: CLAuthorizationStatus){
        
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            self.oneButtonAlert(title: "Location Services Denied", message: "It may be that parental controls are restricting location use in this app.")
        case .denied:
            showAlertToPrivacySettings(title: "User has not authorized location settings.", message: "Select 'Settings' below to enable device settings and enable location  services for this app. ")
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        @unknown default:
            print("DEVELOPER ALERT: UNKNOWN CASE OF STATUS IN \(status)")
        }
    }
    
    func showAlertToPrivacySettings(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else{
            print("SOmething went wrong.")
            return
        }
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) in
            UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(settingsAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
       
        let currentLocation = locations.last ?? CLLocation()
        print("Current Location is \(currentLocation.coordinate.latitude) \(currentLocation.coordinate.longitude)")
        var name = ""
        var address = ""
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(currentLocation) { (placemarks, error) in
            if error != nil {
                print("ERROR Retrieving Place. \(error!.localizedDescription)")
            }
            if placemarks != nil{
                let placemark = placemarks?.last
                name = placemark?.name ?? "Name Unknown"
                if let postalAddress = placemark?.postalAddress {
                    address = CNPostalAddressFormatter.string(from: postalAddress, style: .mailingAddress)
                }
            } else {
                print("ERROR Retrieving Placemark.")
            }
            //if there is no spot data, make device location the spot
            if self.spot.name == "" && self.spot.address == "" {
                self.spot.name = name
                self.spot.address = address
                self.spot.coordinate = currentLocation.coordinate
            }
            self.mapView.userLocation.title = name
            self.mapView.userLocation.subtitle = address.replacingOccurrences(of: "\n", with: ", ")
            self.updateUserInterface()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("ERROR: \(error.localizedDescription). Failed to get location")
    }
}

extension SpotDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reviews.reviewArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReviewCell", for: indexPath) as! SpotReviewTableViewCell
        cell.review = reviews.reviewArray[indexPath.row]
        return cell
    }
}

extension SpotDetailViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.photoArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let photoCell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! SpotPhotoCollectionViewCell
        photoCell.spot = spot
        photoCell.photo = photos.photoArray[indexPath.row]
        return photoCell
    }
    
    
}

extension SpotDetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        photo = Photo()
        if let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            photo.image = editedImage
        } else if let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            photo.image = originalImage
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true) {
            self.performSegue(withIdentifier: "AddPhoto", sender: nil)
        }
    }
    
    func accessPhotoLibrary() {
        imagePickerController.sourceType = .photoLibrary
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func accessCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            imagePickerController.sourceType = .camera
            present(imagePickerController, animated: true, completion: nil)
        } else {
            self.oneButtonAlert(title: "Camera Not Available", message: "There is no camera available on this device.")
        }
    }
}
