/*
     File: AddFilterController.m
 Abstract: View controller for the "Add Filter" table view.
  Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2013 Apple Inc. All Rights Reserved.
 
 */

#import <AssetsLibrary/AssetsLibrary.h>

#import "AddFilterController.h"
#import "CIFilter+FHAdditions.h"

@implementation AddFilterController
@synthesize delegate = _delegate;
@synthesize filterStack = _filterStack;
@synthesize controllerType = _controllerType;
@synthesize imagePickerPopoverController = _imagePickerPopoverController;
@synthesize imagePickerNavigationController = _imagePickerNavigationController;

enum {kAddFilterTableSectionSourceType, kAddFilterTableSectionFilterType};

- (NSArray *)filters
{
    return _filterStack.possibleNextFilters;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Add Filter";
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_handleFilterStackActiveFilterListDidChangeNotification:)
                                                 name:FilterStackActiveFilterListDidChangeNotification
                                               object:nil];
}

- (void) _handleFilterStackActiveFilterListDidChangeNotification:(NSNotification *)notification
{
    [self.tableView reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    else
        return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == kAddFilterTableSectionSourceType)
        return @"Sources";
    else
        return @"Filters";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return section == kAddFilterTableSectionSourceType ? [_filterStack.sources count] : [_filterStack.possibleNextFilters count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:CellIdentifier];
    
    NSArray *data = indexPath.section == kAddFilterTableSectionSourceType ? _filterStack.sources : _filterStack.possibleNextFilters;
    
    FilterDescriptor *d = [data objectAtIndex:indexPath.row];
    cell.textLabel.text = [d displayName];
    
    if ([d.filter isKindOfClass:[SourceFilter class]])
        cell.detailTextLabel.text = nil;
    else
        cell.detailTextLabel.text = [d name];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *data = indexPath.section == kAddFilterTableSectionSourceType ? _filterStack.sources : _filterStack.possibleNextFilters;
    
    FilterDescriptor *d = [data objectAtIndex:indexPath.row];
    CIFilter *filter = d.filter;
    if ([filter isKindOfClass:[SourcePhotoFilter class]])
    {
        if (self.imagePickerNavigationController == nil)
        {
            self.imagePickerNavigationController = [[UIImagePickerController alloc] init];
            self.imagePickerNavigationController.delegate = self;
        }
        
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
        {
            if (self.imagePickerPopoverController == nil)
                self.imagePickerPopoverController = [[UIPopoverController alloc]
                                                     initWithContentViewController:self.imagePickerNavigationController];
            
            [self.imagePickerPopoverController presentPopoverFromRect:self.navigationController.view.bounds
                                                               inView:self.view
                                             permittedArrowDirections:UIPopoverArrowDirectionAny
                                                             animated:YES];
        }
        else
            [self.navigationController presentViewController:self.imagePickerNavigationController animated:YES completion:nil];
        
        return;
    }
    
    [self.filterStack appendFilter:filter];
    [self.delegate didAddFilter:filter];
    [self.tableView reloadData];
}


#pragma mark UIImagePickerViewDelegate


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSURL *assetURL = [info objectForKey:UIImagePickerControllerReferenceURL];
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    [library assetForURL:assetURL
             resultBlock:^(ALAsset *__strong asset) {
                 // we need to be defensive
                 if (asset)
                 {
                     ALAssetRepresentation *rep = [asset defaultRepresentation];
                     
                     CGImageRef cgimage = [rep fullScreenImage];
                     //CGImageRef cgimage = [rep CGImageWithOptions:@{}];
                     //NSLog(@"picked %@ longsize %lld  cgimage=%zux%zu", [rep filename], [rep size], CGImageGetWidth(cgimage), CGImageGetHeight(cgimage));
            
                     if (cgimage)
                     {
                         CIImage* ciimage = [CIImage imageWithCGImage:cgimage];
                         
                         
                         CIFilter* filter = [CIFilter filterWithName:@"SourcePhotoFilter"];
                         [filter setValue:ciimage forKey:kCIInputImageKey];
 
                         [self.filterStack appendFilter:filter];
                         [self.delegate didAddFilter:filter];
                         [self.tableView reloadData];

                         //CGImageRelease(cgimage);
                     }
                     else
                         ;//handler(nil);
                 }
                 else
                     ;//handler([NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:-1 userInfo:nil]);
                 
                 
                 if (self.imagePickerPopoverController)
                 {
                     [self.imagePickerPopoverController dismissPopoverAnimated:YES];
                     self.imagePickerPopoverController = nil;
                 }
                 
             }
            failureBlock:^(NSError *__strong error) {
                ;//handler(error);
            }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    if (self.imagePickerPopoverController)
    {
        [self.imagePickerPopoverController dismissPopoverAnimated:YES];
        self.imagePickerPopoverController = nil;
    }
    else
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

@end
