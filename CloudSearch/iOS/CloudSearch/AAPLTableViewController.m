/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The primary view controller for displaying iCloud documents.
 */

#import "AAPLTableViewController.h"
#import "AAPLCloudDocumentsController.h"
#import "AAPLFilterViewController.h"

enum FilterTableItems
{
    kTXTItem = 0,
    kJPGItem,
    kPDFItem,
    kHTMLItem,
    kNoneItem
};

NSString *kItemURLKey    = @"itemURL";
NSString *kItemNameKey   = @"itemName";
NSString *kItemDateKey   = @"itemModDate";
NSString *kItemIconKey   = @"itemIcon";

@interface AAPLTableViewController () <AAPLCloudDocumentsControllerDelegate, AAPLFilterViewControllerDelegate>

@property (nonatomic, strong) id ubiquityToken;
@property (nonatomic, strong) NSArray *documents;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSIndexPath *currentExtension;

@end


#pragma mark -

@implementation AAPLTableViewController

// -------------------------------------------------------------------------------
//	viewDidLoad
// -------------------------------------------------------------------------------
- (void)viewDidLoad
{
	[super viewDidLoad];
    
    // remember our login token in case the user logs out or logs in with a different account
    _ubiquityToken = [[NSFileManager defaultManager] ubiquityIdentityToken];
    
    // listen for when the current ubiquity identity has changed (user logs in and out of iCloud)
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(ubiquityIdentityChanged:)
                                                 name:NSUbiquityIdentityDidChangeNotification
                                               object:nil];
    
    _dateFormatter = [[NSDateFormatter alloc] init];
    [self.dateFormatter setDateStyle:NSDateFormatterLongStyle];
    
    AAPLCloudDocumentsController *docsController = [AAPLCloudDocumentsController sharedInstance];
    docsController.fileType = @"txt";   // start by finding only 'txt' files
    docsController.delegate = self;     // we need to be notified when cloud docs are found
    _currentExtension = [NSIndexPath indexPathForRow:kTXTItem inSection:0];
    
    if (![docsController startScanning])
    {
        // present an error to say that it wasn't possible to start the iCloud query
        //
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                       message:NSLocalizedString(@"Search_Failed", nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *OKAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK_Button_Title", nil)
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil];
        [alert addAction:OKAction];
        
        [self.navigationController presentViewController:alert animated:YES completion:nil];
    }
}

// -------------------------------------------------------------------------------
//	dealloc
// -------------------------------------------------------------------------------
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSUbiquityIdentityDidChangeNotification
                                                  object:nil];
}


#pragma mark - UITableViewDataSource

// -------------------------------------------------------------------------------
//	numberOfRowsInSection:section
// -------------------------------------------------------------------------------
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.documents.count;
}

// -------------------------------------------------------------------------------
//	cellForRowAtIndexPath:indexPath
// -------------------------------------------------------------------------------
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellID" forIndexPath:indexPath];
	
    cell.textLabel.text = [self.documents[indexPath.row] valueForKey:kItemNameKey];
    cell.imageView.image = [self.documents[indexPath.row] valueForKey:kItemIconKey];
    cell.detailTextLabel.text = [self.dateFormatter stringFromDate:[self.documents[indexPath.row] valueForKey:kItemDateKey]];

    return cell;
}


#pragma mark - CloudDocumentsControllerDelegate

// -------------------------------------------------------------------------------
//	didRetrieveCloudDocuments
// -------------------------------------------------------------------------------
- (void)didRetrieveCloudDocuments
{
    AAPLCloudDocumentsController *docsController = [AAPLCloudDocumentsController sharedInstance];
    
    // clear out the old documents
    NSMutableArray *foundDocuments = [NSMutableArray arrayWithCapacity:docsController.numberOfDocuments];
    
    for (NSInteger idx = 0; idx < [docsController numberOfDocuments]; idx++)
    {
        // get the file name and URL
        NSURL *itemURL = [docsController urlForDocumentAtIndex:idx];
        NSString *itemName = [docsController titleForDocumentAtIndex:idx];
        
        // get the file modification date
        NSDate *modDate = [docsController modDateForDocumentAtIndex:idx];

        UIImage *image = [docsController iconForDocumentAtIndex:idx];
        
        NSMutableDictionary *newItem = [[NSDictionary dictionaryWithObjectsAndKeys:itemURL, kItemURLKey, itemName, kItemNameKey, image, kItemIconKey, nil] mutableCopy];
        if (modDate != nil)
        {
            [newItem setValue:modDate forKey:kItemDateKey];
        }
        [foundDocuments addObject:newItem];
    }

    // sort the documents by name
    _documents = [foundDocuments sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *firstItem, NSDictionary *secondItem) {
        NSString *firstTitle = firstItem[kItemNameKey];
        NSString *secondTitle = secondItem[kItemNameKey];
        return [[firstTitle lowercaseString] compare:[secondTitle lowercaseString]];
    }];

    [self.tableView reloadData];
    
    // we have stopped looking for documents, stop progress
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

// -------------------------------------------------------------------------------
//	didRetrieveCloudDocuments
// -------------------------------------------------------------------------------
- (void)didStartRetrievingCloudDocuments
{
    // we are looking for documents, show progress
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

// -------------------------------------------------------------------------------
//	prepareForSegue:Sender
// -------------------------------------------------------------------------------
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // setup ourselves as delegate to "didSelectExtension" will be called
    UINavigationController *navController = (UINavigationController *)segue.destinationViewController;
    AAPLFilterViewController *filterViewController = (AAPLFilterViewController *)navController.visibleViewController;
    filterViewController.filterDelegate = self;
    filterViewController.extensionToFilter = self.currentExtension;
}


#pragma mark - AAPLFilterViewControllerDelegate

// -------------------------------------------------------------------------------
//	didSelectExtension:extension
// -------------------------------------------------------------------------------
- (void)filterViewController:(AAPLFilterViewController *)viewController didSelectExtension:(NSIndexPath *)extension
{
    _currentExtension = extension;
    
    AAPLCloudDocumentsController *docsController = [AAPLCloudDocumentsController sharedInstance];
    
    NSString *extensionToUse = nil;
    switch (extension.row)
    {
        case kTXTItem:
            extensionToUse = @"txt";
            break;
        case kJPGItem:
            extensionToUse = @"jpg";
            break;
        case kPDFItem:
            extensionToUse = @"pdf";
            break;
        case kHTMLItem:
            extensionToUse = @"html";
            break;
        case kNoneItem:
            extensionToUse = @"";
            break;
    }
    
    docsController.fileType = extensionToUse;
    [docsController restartScan];
}


#pragma mark - Notifications

//----------------------------------------------------------------------------------------
// ubiquityIdentityChanged
//
// Notification that the user has either logged in our out of iCloud.
//----------------------------------------------------------------------------------------
- (void)ubiquityIdentityChanged:(NSNotification *)note
{
    id token = [[NSFileManager defaultManager] ubiquityIdentityToken];
    if (token == nil)
    {
        // present an error to say that it wasn't possible to start the iCloud query
        //
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Logged_Out_Message", nil)
                                                                       message:NSLocalizedString(@"Logged_Out_Message_Explain", nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *OKAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK_Button_Title", nil)
                                                           style:UIAlertActionStyleDefault
                                                         handler:nil];
        [alert addAction:OKAction];
        [self.navigationController presentViewController:alert animated:YES completion:nil];

        // no more documents
        _documents = nil;
        [self.tableView reloadData];
    }
    else
    {
        if ([self.ubiquityToken isEqual:token])
        {
            NSLog(@"user has stayed logged in with same account");
        }
        else
        {
            // user logged in with a different account
            NSLog(@"user logged in with a new account");
        }
        
        // store off this token to compare later
        self.ubiquityToken = token;
        
        // startup our Spotlight search again
        [[AAPLCloudDocumentsController sharedInstance] restartScan];
    }
}

@end

