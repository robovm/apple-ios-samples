/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                A UIViewController subclass that manages the selection of a food item.
            
*/

#import "AAPLFoodPickerViewController.h"
#import "AAPLFoodItem.h"

NSString *const AAPLFoodPickerViewControllerTableViewCellIdentifier = @"cell";
NSString *const AAPLFoodPickerViewControllerUnwindSegueIdentifier = @"AAPLFoodPickerViewControllerUnwindSegueIdentifier";

@interface AAPLFoodPickerViewController()

@property (nonatomic, strong) NSArray *foodItems;

@end


@implementation AAPLFoodPickerViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // A hard-coded list of possible food items. In your application, you can decide how these should
    // be represented / created.
    self.foodItems = @[
        [AAPLFoodItem foodItemWithName:@"Wheat Bagel" joules:240000.0],
        [AAPLFoodItem foodItemWithName:@"Bran with Raisins" joules:190000.0],
        [AAPLFoodItem foodItemWithName:@"Regular Instant Coffee" joules:1000.0],
        [AAPLFoodItem foodItemWithName:@"Banana" joules:439320.0],
        [AAPLFoodItem foodItemWithName:@"Cranberry Bagel" joules:416000.0],
        [AAPLFoodItem foodItemWithName:@"Oatmeal" joules:150000.0],
        [AAPLFoodItem foodItemWithName:@"Fruits Salad" joules:60000.0],
        [AAPLFoodItem foodItemWithName:@"Fried Sea Bass" joules:200000.0],
        [AAPLFoodItem foodItemWithName:@"Chips" joules:190000.0],
        [AAPLFoodItem foodItemWithName:@"Chicken Taco" joules:170000.0]
    ];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.foodItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [tableView dequeueReusableCellWithIdentifier:AAPLFoodPickerViewControllerTableViewCellIdentifier forIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    AAPLFoodItem *foodItem = self.foodItems[indexPath.row];
    
    cell.textLabel.text = foodItem.name;
    
    NSEnergyFormatter *energyFormatter = [self energyFormatter];
    cell.detailTextLabel.text = [energyFormatter stringFromJoules:foodItem.joules];
}

#pragma mark - Convenience

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:AAPLFoodPickerViewControllerUnwindSegueIdentifier]) {
        NSIndexPath *indexPathForSelectedRow = self.tableView.indexPathForSelectedRow;

        self.selectedFoodItem = self.foodItems[indexPathForSelectedRow.row];
    }
}

- (NSEnergyFormatter *)energyFormatter {
    static NSEnergyFormatter *energyFormatter;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        energyFormatter = [[NSEnergyFormatter alloc] init];
        energyFormatter.unitStyle = NSFormattingUnitStyleLong;
        energyFormatter.forFoodEnergyUse = YES;
        energyFormatter.numberFormatter.maximumFractionDigits = 2;
    });
    
    return energyFormatter;
}

@end
