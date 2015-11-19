/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Provides details about a purchase. The purchase contains the product identifier, transaction id,
         and transaction date for a regular purchase. It includes the content identifier, content version,
         and content length for a hosted product. It contains the original transaction's id and date for
         a restored product.
 */


#import "MyModel.h"
#import "PaymentTransactionDetails.h"


@implementation PaymentTransactionDetails

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return self.details.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    MyModel *model = (self.details)[section];
    // Return the number of rows in the section.
    return model.elements.count;
}


-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    MyModel *model = (self.details)[section];
    // Return the header title for this section
    return model.name;
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    MyModel *model = (self.details)[indexPath.section];
    NSArray *transactions = model.elements;
    NSDictionary *dictionary = transactions[indexPath.row];

    if ([model.name isEqualToString:@"DOWNLOAD"])
    {
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
    }
    else if ([model.name isEqualToString:@"ORIGINAL TRANSACTION"])
    {
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
    }
    else
    {
        cell.textLabel.text = transactions[0];
    }
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MyModel *model = (self.details)[indexPath.section];
    
    if ([model.name isEqualToString:@"DOWNLOAD"])
    {
        return [tableView dequeueReusableCellWithIdentifier:@"customCellID" forIndexPath:indexPath];
    }
    else if ([model.name isEqualToString:@"ORIGINAL TRANSACTION"])
    {
       return [tableView dequeueReusableCellWithIdentifier:@"customCellID" forIndexPath:indexPath];
    }
    else
    {
        return [tableView dequeueReusableCellWithIdentifier:@"basicCellID" forIndexPath:indexPath];
    }
}


#pragma mark Memory management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
