/*
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 
  This view controller lets you add items to a list.
  
*/

@import CloudKit;
#import "AAPLCKReferenceViewController.h"
#import "AAPLCKReferenceDetailViewController.h"
#import "AAPLCloudManager.h"

@interface AAPLCKReferenceViewController()

@property IBOutlet UITextField *nameTextField;
@property (nonatomic, readonly) NSMutableArray *list;

- (IBAction)add:(id)sender;

@end

@implementation AAPLCKReferenceViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _list = [[NSMutableArray alloc] init];
    
    [self.cloudManager fetchRecordsWithType:ReferenceItemsRecordType completionHandler:^(NSArray *records) {
        
        self.list.array = records;

        [self.tableView reloadData];
    }];
}

- (IBAction)add:(id)sender {
    if (self.nameTextField.text.length < 1) {
        [self.nameTextField resignFirstResponder];
    } else {
        CKRecord *newRecord = [[CKRecord alloc] initWithRecordType:ReferenceItemsRecordType];
        newRecord[NameField] = self.nameTextField.text;
        [self.cloudManager saveRecord:newRecord];
        
        [self.list insertObject:newRecord atIndex:0];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.nameTextField resignFirstResponder];
        self.nameTextField.text = @"";
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.list.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    CKRecord *record = self.list[indexPath.row];
    cell.textLabel.text = record[NameField];
    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [self.cloudManager deleteRecord:self.list[indexPath.row]];
        [self.list removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
    CKRecord *record = self.list[indexPath.row];
    
    AAPLCKReferenceDetailViewController *detail = segue.destinationViewController;
    detail.parentRecordID = record.recordID;
    detail.cloudManager = self.cloudManager;
}

@end
