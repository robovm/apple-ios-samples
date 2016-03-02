/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A LocationFieldTableViewCell is a FormFieldTableViewCell with controls for inputting a location.
*/

import UIKit
import CoreLocation

class LocationFieldTableViewCell: FormFieldTableViewCell {

    
    @IBOutlet weak var lookUpButton: UIButton!
    @IBOutlet weak var latitudeField: UITextField!
    @IBOutlet weak var longitudeField: UITextField!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var errorLabel: UILabel!
    
    var locationInput: LocationInput!
    
    func setCoordinate(coordinate: CLLocationCoordinate2D) {
        let latitude = coordinate.latitude
        let longitude = coordinate.longitude
        locationInput.latitude = Int(latitude)
        locationInput.longitude = Int(longitude)
        latitudeField.text = String(locationInput.latitude!)
        longitudeField.text = String(locationInput.longitude!)
        latitudeField.layoutIfNeeded()
        longitudeField.layoutIfNeeded()
    }

}
