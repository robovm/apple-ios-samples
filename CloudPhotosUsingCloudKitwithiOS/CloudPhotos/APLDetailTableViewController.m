/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The detail view controller showing a specific CKRecord photo.
 */

#import "APLDetailTableViewController.h"
#import "APLMainTableViewController.h"
#import "APLMapViewController.h"
#import "APLPhotoViewController.h"

#import "APLCloudManager.h"
#import "APLAppDelegate.h"

@import MapKit;
@import AssetsLibrary;

// segue constants
static NSString * const kShowMapSegueID = @"showMap";
static NSString * const kShowPhotoSegueID = @"showPhoto";

static const CGSize kImageSize = {512, 512};    // the size we want for the stored image CKAsset

@interface APLDetailTableViewController () <UITextFieldDelegate,
                                            // needed for UIImagePickerViewController:
                                            UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UITextField *titleField;
@property (nonatomic, weak) IBOutlet UILabel *createdByLabel;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;
@property (nonatomic, weak) IBOutlet UILabel *locationLabel;

// keep track of these so we don't have to fetch them later from the asset library
@property (nonatomic, strong) CLLocation *photoLocation;    // photo asset geo-tagged location
@property (nonatomic, strong) NSDate *photoDate;            // photo asset creation date

@property (nonatomic, strong) UIBarButtonItem *cancelButton;
@property (assign) BOOL editCancelled;

@property (nonatomic, strong) UIImagePickerController *imagePicker;
@property (assign) BOOL photoPickerDismissed;

@property (nonatomic, strong) CLGeocoder *geocoder; // for location

@property (nonatomic, assign) BOOL restoringFromState;    // flag indicating we are performing UIStateRestoration (CKRecord queries are asynchronous)

@end


#pragma mark -

@implementation APLDetailTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // we want the table edit button to the right of the navigation bar
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.editButtonItem.enabled = NO;
    
    // used later when editing
    _cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                  target:self
                                                                  action:@selector(cancelAction:)];
    
    // access to chance the photo can be done in two places:
    //     1) bottom toolbar, 2) tap the actual image
    //
    // setup the toolbar
    UIBarButtonItem *cameraButton =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                                                      target:self
                                                      action:@selector(cameraAction:)];
    [self setToolbarItems:@[cameraButton] animated:YES];
    
    // setup the single tap on the image
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                action:@selector(imageTapDetected:)];
    singleTap.numberOfTapsRequired = 1;
    [self.imageView addGestureRecognizer:singleTap];
    
    // listen for text field changes, so we can update our Done button
    [[NSNotificationCenter defaultCenter] addObserverForName:UITextFieldTextDidChangeNotification
                                                      object:self.titleField
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
        // note: we change the edit button enable state in the nav bar only for the first text field has text content
        //
        // enable the Done button only if we have a title and image
        //
        self.editButtonItem.enabled = [self doneButtonAllowed];
    }];
}

- (void)setupInitialUI
{
    // we might be called as a result of the photo picker dismissal
    if (!self.photoPickerDismissed)
    {
        [self updateNavigationBar]; // this will update our UI to reflect user login
        
        // initial view appeared
        if (self.record != nil)
        {
            [self setupTableElements];
        }
        else
        {
            // we are opening for creation since there is no CKRecord handed to us
            self.title = NSLocalizedString(@"Add Title", nil);
            [self setEditing:YES animated:NO];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // if we are restoring our state, delay the initial UI setup until we have an actual CKRecord to restore
    if (!self.restoringFromState)
    {
        [self setupInitialUI];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UITextFieldTextDidChangeNotification
                                                  object:self.titleField];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];
}

- (void)setupTableElements
{
    // we are opening with an existing record handed to us
    //
    // set the CKAsset photo of this record to our image view
    CKAsset *photoAsset = self.record[[APLCloudManager PhotoAssetAttribute]];
    if (photoAsset != nil)
    {
        self.imageView.image = [UIImage imageWithContentsOfFile:photoAsset.fileURL.path];
    }
    
    self.title = self.record[[APLCloudManager PhotoTitleAttribute]];
    self.titleField.text = self.record[[APLCloudManager PhotoTitleAttribute]];
    
    // we provide the owner of the current record in the subtite of our cell
    [CloudManager fetchUserNameFromRecordID:self.record.creatorUserRecordID completionHandler:^(NSString *firstName, NSString *lastName) {
        if (firstName == nil && lastName == nil)
        {
            self.createdByLabel.text = [NSString stringWithFormat:@"%@", NSLocalizedString(@"Unknown User Name", nil)];
        }
        else
        {
            self.createdByLabel.text = [NSString stringWithFormat:@"%@", [NSString stringWithFormat:@"%@ %@", firstName, lastName]];
        }
    }];
    
    // set the date field to match this photo
    NSDate *date = self.record[[APLCloudManager PhotoDateAttribute]];
    [self updateDateFieldFromDate:date];
    
    // setup the map's location and label
    self.photoLocation = self.record[[APLCloudManager PhotoLocationAttribute]];
    [self updateLocationNameFromLocation:self.photoLocation];
}


#pragma mark - Actions

- (void)cancelAction:(id)sender
{
    _editCancelled = YES;
    
    [self setEditing:NO animated:YES];
    
    _editCancelled = NO;
    
    if (self.record == nil)
    {
        // no record defined yet, go back, user cancelled
        [self.navigationController popViewControllerAnimated:YES];
    }
    else
    {
        [self setupTableElements];    // reset our cells back to initial state
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    // hide/show toolbar on edit toggle
    [self.navigationController setToolbarHidden:!editing animated:YES];
    
    if (editing)
    {
        // entering edit mode
        self.navigationItem.leftBarButtonItem = self.cancelButton;
        
        // we always want to focus the title field when first editing
        [self.titleField becomeFirstResponder];
    }
    else
    {
        // leaving edit mode: Done button pressed or Cancel button is pressed
        
        // dismiss keyboard if our title field is first responder
        if ([self.titleField isFirstResponder])
        {
            [self.titleField resignFirstResponder];
        }
        
        // save the record
        //
        if (!self.editCancelled)    // don't continue here if user cancelled
        {
            if (self.record != nil)
            {
                // we have an existing record to save out the edit
                //
                self.record[[APLCloudManager PhotoTitleAttribute]] = self.titleField.text;
                
                // this will create a sized down/compressed cached image in the caches folder
                NSURL *imageURL = [self createCachedImageFromImage:self.imageView.image size:kImageSize];
                if (imageURL != nil)
                {
                    CKAsset *asset = [[CKAsset alloc] initWithFileURL:imageURL];
                    self.record[[APLCloudManager PhotoAssetAttribute]] = asset;
                    self.record[[APLCloudManager PhotoDateAttribute]] = self.photoDate;
                    self.record[[APLCloudManager PhotoLocationAttribute]] = self.photoLocation;
                }
                
                [CloudManager modifyRecord:self.record completionHandler:^(CKRecord *record, NSError *error) {
                    
                    if (error != nil)
                    {
                        NSLog(@"Error modifying existing record in %@: error[%ld] %@",
                              NSStringFromSelector(_cmd), (long)error.code, error.localizedDescription);
                    }
                    else
                    {
                        // assign our newly returned record
                        _record = record;
                        
                        //NSLog(@"\nSave record succeeded: recordID = %@", record.recordID);
                        
                        [self setupTableElements];  // update our table cells
                        
                        // inform our delegate to re-fetch since we changed an existing record
                        [self.delegate detailViewController:self didChangeCloudRecord:self.record];
                    }
                }];
            }
            else
            {
                // we don't have a record yet, (user tapped + button in the main table), so add it and save
                //
                __weak __typeof(self) weakSelf = self;
                [self addRecordWithImage:self.imageView.image
                                   title:self.titleField.text
                                    date:self.photoDate
                                location:self.photoLocation
                       completionHandler:^(CKRecord *record, NSError *error) {
                           if (record != nil && error == nil)
                           {
                               weakSelf.record = record;
    
                               [weakSelf setupTableElements];  // update our table cells
                               
                               // inform our delegate to refetch since added a new record
                               [weakSelf.delegate detailViewController:weakSelf didAddCloudRecord:weakSelf.record];
                           }
                       }];
            }
        }
        
        // remove the cancel button
        self.navigationItem.leftBarButtonItem = nil;
    }
}

- (BOOL)isMyRecord
{
    BOOL isMyRecord = NO;
    
    if (self.record != nil)
    {
        isMyRecord = [CloudManager isMyRecord:self.record.creatorUserRecordID];
    }
    else
    {
        // we don't have a record yet, which means we are editing an unsaved record of our own
        isMyRecord = YES;
    }
    return isMyRecord;
}

// in order to finish editing (allow the Done button to be enabled)
// to save this record, we must have a title, image and the record owner is us
//
- (BOOL)doneButtonAllowed
{
    return (self.titleField.text.length > 0 && self.imageView.image != nil && [self isMyRecord]);
}


#pragma mark - MKMapView

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    BOOL shouldPerform = NO;
    if ([identifier isEqualToString:kShowMapSegueID])
    {
        shouldPerform = (self.photoLocation != nil);
    }
    return shouldPerform;
}


#pragma mark - Segue support

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kShowMapSegueID])
    {
        // navigate to APLMapViewController: the detail screen of the map
        APLMapViewController *mapViewController = (APLMapViewController *)segue.destinationViewController;
        mapViewController.title = self.record[[APLCloudManager PhotoTitleAttribute]];
        mapViewController.location = self.photoLocation;
    }
    else if ([segue.identifier isEqualToString:kShowPhotoSegueID])
    {
        // navigate to APLPhotoViewController: the detail photo screen
        APLPhotoViewController *photoViewController = (APLPhotoViewController *)segue.destinationViewController;
        photoViewController.title = self.record[[APLCloudManager PhotoTitleAttribute]];
        photoViewController.photo = self.imageView.image;
    }
}


#pragma mark - UIImageView

// this will create a sized down/compressed cached image in the caches folder
- (NSURL *)createCachedImageFromImage:(UIImage *)image size:(CGSize)size
{
    NSURL *resultURL = nil;
    
    if (self.imageView.image != nil)
    {
        if (image.size.width > image.size.height)
        {
            size.height = round(size.width * image.size.height / image.size.width);
        }
        else
        {
            size.width = round(size.height * image.size.width / image.size.height);
        }
        
        UIGraphicsBeginImageContext(size);
        [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
        
        NSData *data = UIImageJPEGRepresentation(UIGraphicsGetImageFromCurrentImageContext(), 0.75);
        UIGraphicsEndImageContext();
        
        // write the image out to a cache file
        NSURL *cachesDirectory = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory
                                                                        inDomain:NSUserDomainMask
                                                               appropriateForURL:nil
                                                                          create:YES
                                                                           error:nil];
        NSString *temporaryName = [[NSUUID UUID].UUIDString stringByAppendingPathExtension:@"jpeg"];
        resultURL = [cachesDirectory URLByAppendingPathComponent:temporaryName];
        [data writeToURL:resultURL atomically:YES];
    }
    
    return resultURL;
}

- (void)pickImage
{
    if ([self isMyRecord])     // only allow editing our photos
    {
        if (!self.isEditing)    // user can tap the photo for editing while not in edit mode, so we must enter edit mode
        {
            [self setEditing:YES animated:NO];
        }
        
        if (self.imagePicker == nil)
        {
            _imagePicker = [[UIImagePickerController alloc] init];
            self.imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            self.imagePicker.delegate = self;
            self.imagePicker.allowsEditing = YES;
        }
        
        [self presentViewController:self.imagePicker animated:YES completion:^ {
            
            // do something after it's done presenting...
        }];
    }
}

- (void)cameraAction:(id)sender
{
    [self pickImage];
}

- (void)imageTapDetected:(UIGestureRecognizer *)gestureRecognizer
{
    if (self.isEditing)
    {
        // open the image picker to pick a new photo
        [self pickImage];
    }
    else
    {
        // call our segue to display the photo
        [self performSegueWithIdentifier:kShowPhotoSegueID sender:self];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *originalImage = [info valueForKey:UIImagePickerControllerEditedImage];
    if (originalImage != nil)
    {
        self.imageView.image = originalImage;
        
        // handle the ALAsset that's returned
        ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset)
        {
            // obtain the creation date property from the asset
            _photoDate = [myasset valueForProperty:ALAssetPropertyDate];
            [self updateDateFieldFromDate:self.photoDate];
            
            // obtain the location property from the asset
            _photoLocation = [myasset valueForProperty:ALAssetPropertyLocation];
            
            // then change location label
            [self updateLocationNameFromLocation:self.photoLocation];
            
            self.navigationItem.rightBarButtonItem.enabled = [self doneButtonAllowed];
        };
        
        // handle errors
        ALAssetsLibraryAccessFailureBlock failureblock  = ^(NSError *error)
        {
            NSString *message = error.localizedDescription;
            NSLog(@"Could not get asset in %@: error[%ld] %@", NSStringFromSelector(_cmd), (long)error.code, message);
        };
        
        // use the url to get the asset from ALAssetsLibrary, the blocks above will handle results
        ALAssetsLibrary *assetslibrary = [[ALAssetsLibrary alloc] init];
        NSURL *url = info[UIImagePickerControllerReferenceURL];
        [assetslibrary assetForURL:url
                       resultBlock:resultblock
                      failureBlock:failureblock];
    }
    
    _photoPickerDismissed = YES;
    
    [self dismissViewControllerAnimated:YES completion:^{
        
        _photoPickerDismissed = NO;
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    _photoPickerDismissed = YES;
    
    [self dismissViewControllerAnimated:YES completion:^{
        
        _photoPickerDismissed = NO;
    }];
}


#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;  // no deletion or reordering in this view controller
}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return [self isMyRecord];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    // the user can tap the name field while not in edit mode, which will allow the edit session to start
    if (!self.isEditing)
    {
        [self setEditing:YES animated:YES];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}


#pragma mark - NSDate

- (void)updateDateFieldFromDate:(NSDate *)date
{
    if (date != nil)
    {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        self.dateLabel.text = [dateFormatter stringFromDate:date];
    }
}


#pragma mark - CLLocation

- (void)updateLocationNameFromLocation:(CLLocation *)location
{
    UITableViewCell *locationCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:2]];
    if (location != nil)
    {
        if (self.geocoder == nil)
        {
            _geocoder = [[CLGeocoder alloc] init];
        }
        
        // get nearby address
        [self.geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
            if (placemarks != nil && placemarks.count > 0)
            {
                CLPlacemark *placemark = placemarks[0];
                if (placemark.locality != nil && placemark.administrativeArea != nil)
                {
                    self.locationLabel.text = [NSString stringWithFormat:@"%@, %@, %@", placemark.thoroughfare, placemark.locality, placemark.administrativeArea];
                }
            }
        }];
        
        // since we have a location, we can navigate to a detail map
        locationCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else
    {
        self.locationLabel.text = NSLocalizedString(@"Location Unavailable", nil);
        
        // no location, so we block navigating to a detail map
        locationCell.accessoryType = UITableViewCellAccessoryNone;
    }
}


#pragma mark - CloudKit

- (void)addRecordWithImage:(UIImage *)image
                     title:(NSString *)title
                      date:(NSDate *)date
                  location:(CLLocation *)location
         completionHandler:(void (^)(CKRecord *record, NSError *error))completionHandler
{
    CKRecord *newRecord = [[CKRecord alloc] initWithRecordType:[APLCloudManager PhotoRecordType]];
    newRecord[[APLCloudManager PhotoTitleAttribute]] = title;
    newRecord[[APLCloudManager PhotoDateAttribute]] = date;
    newRecord[[APLCloudManager PhotoLocationAttribute]] = location;
    
    // this will create a sized down/compressed cached image in the caches folder
    NSURL *imageURL = [self createCachedImageFromImage:image size:kImageSize];
    if (imageURL != nil)
    {
        CKAsset *asset = [[CKAsset alloc] initWithFileURL:imageURL];
        newRecord[[APLCloudManager PhotoAssetAttribute]] = asset;
    }
    
    [CloudManager saveRecord:newRecord completionHandler:^(CKRecord *record, NSError *error) {
        if (error != nil)
        {
            // if there are no records defined in iCloud dashboard you will get this error:
            /* error 9 {
             NSDebugDescription = "CKInternalErrorDomain: 1004";
             NSLocalizedDescription = "Account couldn't get container scoped user id, no underlying error received"
             */
            
            if (error != nil)
            {
                NSLog(@"Error saving record in %@: error[%ld] %@", NSStringFromSelector(_cmd), (long)error.code, error.localizedDescription);
            }
            else
            {
                //NSLog(@"\nSave record succeeded: recordID = %@", record.recordID);
            }
        }
        else
        {
            completionHandler(record, error);
        }
    }];
}

// update our navigation bar so that the edit and add button states are correct according to user login
- (void)updateNavigationBar
{
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    [CloudManager accountAvailable:^(BOOL available) {
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        if (available && [CloudManager userLoginIsValid])
        {
            // we are logged in, iCloud drive is on, allow for edits
            //
            // but we still need to check if it's our record (we can edit only our records)
            //
            [CloudManager fetchLoggedInUserRecord:^(CKRecordID *loggedInUserRecordID) {
                self.editButtonItem.enabled = [CloudManager isMyRecord:self.record.creatorUserRecordID];
            }];
        }
        else
        {
            // we are not logged in, don't allow for changes
            self.editButtonItem.enabled = NO;
        }
    }];
}


#pragma mark - Account Change Notification

// called when we receive notification from our App Delegate that the user logged in our out
- (void)iCloudAccountAvailabilityChanged
{
    // the user signs out of iCloud (such as by turning off Documents & Data in Settings), or has signed back in
    // so we need to refresh our UI, this will update our UI to reflect user login
    //
    [CloudManager updateUserLogin:^() {
        [self updateNavigationBar];
    }];
}


#pragma mark - Push Notifications

// called by our AppDelegate to handle a specific push notification of a specifc CKRecordID (our record),
// that record could have beed added, deleted or updated
//
- (void)handlePushWithRecordID:(CKRecordID *)recordID reason:(CKQueryNotificationReason)reason reasonMessage:(NSString *)reasonMessage
{
    if (self.isEditing)
    {
        // don't bother the user while editing this photo
    }
    else
    {
        // we are not editing our current photo record, so process this notification
        //
        if (reason == CKQueryNotificationReasonRecordDeleted)
        {
            // alert user that our current record was deleted, and then we leave this view controller
            //
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:reasonMessage
                                                                           message:nil
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
            UIAlertAction *OKAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK Button Title", nil)
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction *action) {
                // dissmissal of alert completed, update the table (remove the record)
                [self.delegate detailViewController:self didDeleteCloudRecord:self.record];

                // pop this view controller back to our root table
                [self.navigationController popToRootViewControllerAnimated:YES];
            }];
            
            [alert addAction:OKAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
        else if (reason == CKQueryNotificationReasonRecordUpdated)
        {
            // for updates of our record: 'recordID' was modified, so search only for our updated record
            //
            [CloudManager fetchRecordWithID:recordID completionHandler:^(CKRecord *foundRecord, NSError *error) {
                 
                if (error != nil)
                {
                    // error fetching the record that was changed or added
                    NSLog(@"An error occured in '%@': error[%ld] %@",
                          NSStringFromSelector(_cmd), (long)error.code, error.localizedDescription);
                }
                else
                {
                    if (foundRecord != nil)
                    {
                        _record = foundRecord;
                        [self setupTableElements];
                    }
                }
            }];
        }
    }
}


#pragma mark - UIStateRestoration

static NSString * const DetailViewControllerRecordKey = @"DetailViewControllerRecordID";

// please note that this can be called when we receive any push notifications in the background
//
- (void)encodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super encodeRestorableStateWithCoder:coder];
    
    // encode just the recordID for state restoration
    [coder encodeObject:self.record.recordID forKey:DetailViewControllerRecordKey];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder
{
    [super decodeRestorableStateWithCoder:coder];
    
    // restore the product
    CKRecordID *recordID = [coder decodeObjectForKey:DetailViewControllerRecordKey];
    if (recordID != nil)
    {
        // flag ourselves that we are performing UIStateRestoration
        // (a CKRecord query is asynchronous and viewWillAppear will be called before we are ready)
        //
        _restoringFromState = YES;
        
        // find our CKRecord we had in this view controller from last time
        [CloudManager fetchRecordWithID:recordID completionHandler:^(CKRecord *foundRecord, NSError *error) {
            
            if (error != nil)
            {
                // error fetching the record that was changed or added
                NSLog(@"An error occured while restoring view controller: error[%ld] %@", (long)error.code, error.localizedDescription);
            }
            else
            {
                if (foundRecord != nil)
                {
                    // we found the restord to restore in this view controller
                    _record = foundRecord;
                    _restoringFromState = NO;
                    [self setupInitialUI];
                }
                else
                {
                    // oops, the record we expected from last time no longer exists
                    [self.navigationController popViewControllerAnimated:NO];
                }
            }
        }];
    }
    else
    {
        // oops, the record we expected from last time no longer exists
        [self.navigationController popViewControllerAnimated:NO];
    }
}

@end

