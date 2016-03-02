/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This view controller displays some descriptive text for a code sample, the input form for configuring the sample, and the button for running it. It also has all relevant event handlers.
*/

import UIKit
import CoreLocation

class CodeSampleViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, UITextFieldDelegate, CLLocationManagerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource {

    // Mark: - Properties
    
    var locationManager: CLLocationManager = CLLocationManager()
    var imagePickerController: UIImagePickerController = UIImagePickerController()
    
    @IBOutlet weak var pickerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var tableView: TableView!
    @IBOutlet weak var className: UILabel!
    @IBOutlet weak var methodName: UILabel!
    @IBOutlet weak var runButton: UIBarButtonItem!
    @IBOutlet weak var codeSampleDescription: UILabel!
    
    var selectedCodeSample: CodeSample?
    var groupTitle: String?
    
    var selectedLocationCellIndex: Int?
    var selectedImageCellIndex: Int?
    var selectedSelectionCellIndex: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let codeSample = selectedCodeSample {
            className.text = "Class: " + codeSample.className
            methodName.text = codeSample.methodName
            codeSampleDescription.text = codeSample.description
        }
        
        if let groupTitle = groupTitle {
            navigationItem.title = groupTitle
        }
        navigationItem.hidesBackButton = (navigationController!.viewControllers.first?.navigationItem.hidesBackButton)!
        
        let border = CALayer()
        border.backgroundColor = UIColor(red: 0.91, green: 0.91, blue: 0.91, alpha: 1).CGColor
        border.frame = CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 1.0)
        tableView.layer.addSublayer(border)
        
        locationManager.delegate = self
        
        imagePickerController.sourceType = .PhotoLibrary
        imagePickerController.delegate = self
        
        pickerView.delegate = self
        pickerView.dataSource = self
        
        validateInputs()

    }
    
    func validateInputs() {
        var runButtonIsEnabled = true
        if let codeSample = selectedCodeSample {
            for input in codeSample.inputs {
                if !input.isValid {
                    runButtonIsEnabled = false
                    break
                }
            }
        }
        runButton.enabled = runButtonIsEnabled
    }
    
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let codeSample = selectedCodeSample {
            return codeSample.inputs.filter({ !$0.isHidden }).count
        }
        return 0
    }
    

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let codeSample = selectedCodeSample {
            let inputs = codeSample.inputs.filter { !$0.isHidden }
            let input = inputs[indexPath.row]
            if let input = input as? TextInput, cell = tableView.dequeueReusableCellWithIdentifier("TextFieldCell", forIndexPath: indexPath) as? TextFieldTableViewCell {
                cell.textInput = input
                cell.fieldLabel.text = input.label
                cell.textField.text = input.value
                if input.type == .Email {
                    cell.textField.keyboardType = .EmailAddress
                }
                cell.textField.delegate = self
                if indexPath.row == 0 {
                    cell.textField.becomeFirstResponder()
                }
                return cell
            } else if let input = input as? LocationInput, cell = tableView.dequeueReusableCellWithIdentifier("LocationFieldCell", forIndexPath: indexPath) as? LocationFieldTableViewCell {
                cell.locationInput = input
                cell.fieldLabel.text = input.label
                cell.longitudeField.delegate = self
                cell.latitudeField.delegate = self
                if indexPath.row == 0 {
                    cell.latitudeField.becomeFirstResponder()
                }
                
                cell.lookUpButton.enabled = CLLocationManager.authorizationStatus() != .Denied
                
                return cell
            } else if let input = input as? ImageInput, cell = tableView.dequeueReusableCellWithIdentifier("ImageFieldCell", forIndexPath: indexPath) as? ImageFieldTableViewCell {
                cell.fieldLabel.text = input.label
                cell.imageInput = input
                return cell
            } else if let input = input as? BooleanInput, cell = tableView.dequeueReusableCellWithIdentifier("BooleanFieldCell", forIndexPath: indexPath) as? BooleanFieldTableViewCell {
                cell.fieldLabel.text = input.label
                cell.booleanField.on = input.value
                cell.booleanInput = input
                return cell
            } else if let input = input as? SelectionInput, cell = tableView.dequeueReusableCellWithIdentifier("SelectionFieldCell", forIndexPath: indexPath) as? SelectionFieldTableViewCell {
                cell.fieldLabel.text = input.label
                cell.selectedItemLabel.text = input.items.count > 0 ? (input.value != nil ? input.items[input.value!].label : input.items[0].label ) : ""
                cell.selectionInput = input
                return cell
            }
        }
        let cell = tableView.dequeueReusableCellWithIdentifier("FormFieldCell", forIndexPath: indexPath)
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let codeSample = selectedCodeSample, _ = codeSample.inputs[indexPath.row] as? ImageInput {
            return 236.0
        }
        return tableView.rowHeight
    }
    
    // Mark: - UITextFieldDelegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if let contentView = textField.superview {
            
            if let cell = contentView.superview as? TextFieldTableViewCell {
                cell.textInput.value = textField.text ?? ""
            } else if let stackView = contentView.superview, cell = stackView.superview as? LocationFieldTableViewCell, text = textField.text, value = Int(text) {
                if textField.tag == 0 {
                    cell.locationInput.latitude = value
                } else if textField.tag == 1 {
                    cell.locationInput.longitude = value
                }
            }
            
            validateInputs()
            
        }
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        if let contentView = textField.superview, stackView = contentView.superview, cell = stackView.superview as? LocationFieldTableViewCell, errorLabel = cell.errorLabel {
            errorLabel.hidden = true
            errorLabel.layoutIfNeeded()
        }
    }
    
    // MARK: - UIPickerViewDataSource
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if let selectedSelectionCellIndex = selectedSelectionCellIndex {
            let indexPath = NSIndexPath(forRow: selectedSelectionCellIndex, inSection: 0)
            if let cell = tableView.cellForRowAtIndexPath(indexPath) as? SelectionFieldTableViewCell {
                return cell.selectionInput.items.count
            }
        }
        return 0
    }
    
    // MARK: - UIPickerViewDelegate
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if let selectedSelectionCellIndex = selectedSelectionCellIndex {
            let indexPath = NSIndexPath(forRow: selectedSelectionCellIndex, inSection: 0)
            if let cell = tableView.cellForRowAtIndexPath(indexPath) as? SelectionFieldTableViewCell {
                return cell.selectionInput.items[row].label
            }
        }
        return nil
    }

    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if let selectedSelectionCellIndex = selectedSelectionCellIndex {
            let indexPath = NSIndexPath(forRow: selectedSelectionCellIndex, inSection: 0)
            if let cell = tableView.cellForRowAtIndexPath(indexPath) as? SelectionFieldTableViewCell {
                cell.selectedItemLabel.text = cell.selectionInput.items[row].label
                UIView.animateWithDuration(0.4, animations: {
                    self.pickerHeightConstraint.constant = 0
                    self.view.layoutIfNeeded()
                }) { completed in
                    if completed {
                        if let oldValue = cell.selectionInput.value {
                            for index in cell.selectionInput.items[oldValue].toggleIndexes {
                                self.selectedCodeSample!.inputs[index].isHidden = true
                            }
                        }
                        for index in cell.selectionInput.items[row].toggleIndexes {
                            self.selectedCodeSample!.inputs[index].isHidden = false
                        }
                        cell.selectionInput.value = row
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }
    
    // Mark: - CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if let index = selectedLocationCellIndex {
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! LocationFieldTableViewCell
            cell.lookUpButton.enabled = status != .Denied
            if status == .AuthorizedWhenInUse {
                requestLocationForCell(cell)
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        if let index = selectedLocationCellIndex {
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! LocationFieldTableViewCell
            endLocationLookupForCell(cell)
            cell.errorLabel.hidden = false
            cell.errorLabel.layoutIfNeeded()
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let index = selectedLocationCellIndex {
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! LocationFieldTableViewCell
            endLocationLookupForCell(cell)
            if let location = locations.last {
                cell.setCoordinate(location.coordinate)
                validateInputs()
            }
        }
    }
    
    func endLocationLookupForCell(cell: LocationFieldTableViewCell) {
        cell.latitudeField.enabled = true
        cell.longitudeField.enabled = true
        cell.lookUpButton.enabled = true
        cell.spinner.stopAnimating()
    }
    
    func requestLocationForCell(cell: LocationFieldTableViewCell) {
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager.requestLocation()
        cell.latitudeField.enabled = false
        cell.longitudeField.enabled = false
        cell.spinner.startAnimating()
        cell.spinner.layoutIfNeeded()
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String:AnyObject]) {
        if let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage, index = selectedImageCellIndex, imageURL = getImageURL() {
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! ImageFieldTableViewCell
            let imageData = UIImageJPEGRepresentation(selectedImage, 0.8)
            imageData?.writeToURL(imageURL, atomically: true)
            cell.assetView.image = selectedImage
            cell.imageInput.value = imageURL
            
        }
        picker.dismissViewControllerAnimated(true, completion: nil)
    }

    func getImageURL() -> NSURL? {
        if let index = selectedImageCellIndex {
            let manager = NSFileManager.defaultManager()
            do {
                let directoyURL = try manager.URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true)
                let tempImageName = "ck_catalog_tmp_image_\(index)"
                return directoyURL.URLByAppendingPathComponent(tempImageName)
            } catch {
                return nil
            }
            
        }
        return nil
    }
    
    // MARK: - Actions
    
    @IBAction func pickImage(sender: UIButton) {
        if let contentView = sender.superview, cell = contentView.superview as? ImageFieldTableViewCell {
            selectedImageCellIndex = tableView.indexPathForCell(cell)?.row
            presentViewController(imagePickerController, animated: true, completion: nil)
        }
    }
    
    @IBAction func runCode(sender: UIBarButtonItem) {
        if let codeSample = selectedCodeSample {
            
            if let error = codeSample.error {
                let alertController = UIAlertController(title: "Invalid Parameter", message: error, preferredStyle: .Alert)
                alertController.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: nil))
                self.presentViewController(alertController, animated: true, completion: nil)
            } else {
                self.navigationController!.performSegueWithIdentifier("ShowLoadingView", sender: codeSample)
            }
            
        }
    }

    @IBAction func lookUpLocation(sender: UIButton) {
        if let stackView = sender.superview, contentView = stackView.superview, cell = contentView.superview as? LocationFieldTableViewCell {
            cell.errorLabel.hidden = true
            cell.lookUpButton.enabled = false
            selectedLocationCellIndex = tableView.indexPathForCell(cell)?.row
            if CLLocationManager.authorizationStatus() == .NotDetermined {
                locationManager.requestWhenInUseAuthorization()
            } else {
                requestLocationForCell(cell)
            }
        }
    }
    
    
    @IBAction func selectOption(sender: UITapGestureRecognizer) {
        let location = sender.locationInView(tableView)
        if let indexPath = tableView.indexPathForRowAtPoint(location) {
            selectedSelectionCellIndex = indexPath.row
            pickerView.reloadComponent(0)
            UIView.animateWithDuration(0.4, animations: {
                self.pickerHeightConstraint.constant = 200
                self.view.layoutIfNeeded()
            })
        }
        
    }
    
    

}
