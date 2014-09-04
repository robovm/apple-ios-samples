/*
     File: PaymentTransactionDetails.m
 Abstract: Provides details about a purchase. The purchase contains the product identifier, transaction id, and transaction
           date for a regular purchase. It includes the content identifier, content version, and content length for a
           hosted product. It contains the original transaction's id and date for a restored product.
 
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
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
*/

#import "MyModel.h"
#import "PaymentTransactionDetails.h"

@interface PaymentTransactionDetails ()
@end

@implementation PaymentTransactionDetails

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [self.details count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    MyModel *model = (self.details)[section];
    // Return the number of rows in the section.
    return [model.elements count];
}


-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
     MyModel *model = (self.details)[section];
    // Return the header title for this section
    return model.name;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MyModel *model = (self.details)[indexPath.section];
    NSArray *transactions = model.elements;
    NSDictionary *dictionary = transactions[indexPath.row];
    
    if ([model.name isEqualToString:@"DOWNLOAD"])
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"customCellID" forIndexPath:indexPath];
        
        switch (indexPath.row)
        {
            case 0:
                cell.textLabel.text = @"Identifier";
                cell.detailTextLabel.text = dictionary[@"Identifier"];
                break;
            case 1:
                cell.textLabel.text = @"Content Version";
                cell.detailTextLabel.text = dictionary[@"Version"];
                break;
            case 2:
                cell.textLabel.text = @"Content Length";
                cell.detailTextLabel.text = dictionary[@"Length"];
                break;
            default:
                break;
        }
        return cell;
    }
    else if ([model.name isEqualToString:@"ORIGINAL TRANSACTION"])
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"customCellID" forIndexPath:indexPath];
        
        switch (indexPath.row)
        {
            case 0:
                cell.textLabel.text = @"Transaction ID";
                cell.detailTextLabel.text = dictionary[@"Transaction ID"];
                break;
            case 1:
                cell.textLabel.text = @"Transaction Date";
                cell.detailTextLabel.text = dictionary[@"Transaction Date"];
                break;
            default:
                break;
        }
        return cell;
    }
    else
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"basicCellID" forIndexPath:indexPath];
        cell.textLabel.text = transactions[0];
        return cell;
    }
}

@end
