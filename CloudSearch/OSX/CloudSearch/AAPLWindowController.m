/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Primary NSWindowController for this sample, used to display search results.
 */

#import "AAPLWindowController.h"
#import "AAPLCloudDocumentsController.h"

// keys to our document data found in our table view search results
NSString *kItemURLKey    = @"itemURL";
NSString *kItemNameKey   = @"itemName";
NSString *kItemDateKey   = @"itemModDate";
NSString *kItemIconKey   = @"itemIcon";

// filter NSPopUpButton menu item indexes:
enum FilterMenuItems
{
    kTXTItem = 0,
    kJPGItem,
    kPDFItem,
    kHTMLItem,
    kNoneItem = 5
};

@interface AAPLWindowController ()

@property (nonatomic, strong) IBOutlet NSTableView *tableView;
@property (nonatomic, strong) IBOutlet NSArrayController *contentArray;
@property (nonatomic, strong) IBOutlet NSPopUpButton *filterPopup;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end


#pragma mark -

@implementation AAPLWindowController

//•• (make table view-based!)

// -------------------------------------------------------------------------------
//  init
// -------------------------------------------------------------------------------
- (id)init
{
    if (self = [super initWithWindowNibName:@"AAPLWindowController"])
    {
        _dateFormatter = [[NSDateFormatter alloc] init];
    }
    return self;
}

// -------------------------------------------------------------------------------
//  windowDidLoad
// -------------------------------------------------------------------------------
- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // implement this method to handle any initialization after your window
    // controller's window has been loaded from its nib file.
    
    // Add any code here that need to be executed once the windowController has loaded the document's window.
    //
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:kItemNameKey ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    [self.contentArray setSortDescriptors:sortDescriptors];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

// -------------------------------------------------------------------------------
//	clearItems
// -------------------------------------------------------------------------------
- (void)clearDocuments
{
    NSArray *objs = self.contentArray.arrangedObjects;
    [self.contentArray removeObjects:objs];
}

// -------------------------------------------------------------------------------
//	addDocument:itemDisplayName:modificationDate:icon
// -------------------------------------------------------------------------------
- (void)addDocument:(NSURL *)url withName:itemName modificationDate:(NSDate *)modificationDate icon:(NSImage *)icon
{
    // configure the modification date
    [self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    NSString *dateStr = [self.dateFormatter stringFromDate:modificationDate];

    // build all this info into a dictionary for later use (bindings in NSTableView)
    NSMutableDictionary *itemDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                     url, kItemURLKey,
                                     itemName, kItemNameKey,
                                     dateStr, kItemDateKey,
                                     icon, kItemIconKey,    //•• apply this to the NSTableView!
                                     nil];
    [self.contentArray addObject:itemDict];
    
    [self.contentArray setSelectedObjects:nil]; // no selection while adding
}

// -------------------------------------------------------------------------------
//	shouldEditTableColumn:aTableColumn:rowIndex
// -------------------------------------------------------------------------------
- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    return NO;
}


#pragma mark - Actions

// -------------------------------------------------------------------------------
//	filterAction:sender
//
//  User chose an extension to filter the search.
// -------------------------------------------------------------------------------
- (IBAction)filterAction:(id)sender
{
    NSPopUpButton *popupButton = sender;
    AAPLCloudDocumentsController *docsController = [AAPLCloudDocumentsController sharedInstance];
    
    NSString *fileType = nil;
    switch ([popupButton indexOfSelectedItem])
    {
        case kTXTItem:
            fileType = @"txt";
            break;
        case kJPGItem:
            fileType = @"jpg";
            break;
        case kPDFItem:
            fileType = @"pdf";
            break;
        case kHTMLItem:
            fileType = @"html";
            break;
        case kNoneItem:
            fileType = @"";
            break;
    }
    
    docsController.fileType = fileType;
    [docsController restartScan];
}

@end
