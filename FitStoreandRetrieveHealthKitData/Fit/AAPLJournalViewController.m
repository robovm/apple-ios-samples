/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                Displays information retrieved from HealthKit about the food items consumed today.
            
*/

#import "AAPLJournalViewController.h"
#import "AAPLFoodPickerViewController.h"
#import "AAPLFoodItem.h"

@interface AAPLJournalViewController()

@property (nonatomic) NSMutableArray *foodItems;

@end


NSString *const AAPLJournalViewControllerTableViewCellReuseIdentifier = @"cell";


@implementation AAPLJournalViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.foodItems = [NSMutableArray array];

    [self updateJournal];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateJournal) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

#pragma mark - Reading HealthKit Data

- (void)updateJournal {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDate *now = [NSDate date];
    
    NSDateComponents *components = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:now];
    
    NSDate *startDate = [calendar dateFromComponents:components];
    
    NSDate *endDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startDate options:0];
    
    HKCorrelationType *foodType = [HKObjectType correlationTypeForIdentifier:HKCorrelationTypeIdentifierFood];
    
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionNone];

    HKSampleQuery *query = [[HKSampleQuery alloc] initWithSampleType:foodType predicate:predicate limit:HKObjectQueryNoLimit sortDescriptors:nil resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
        if (!results) {
            NSLog(@"An error occured fetching the user's tracked food. In your app, try to handle this gracefully. The error was: %@.", error);
            abort();
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.foodItems removeAllObjects];
            
            for (HKCorrelation *foodCorrelation in results) {
                // Create an AAPLFoodItem instance that contains the information we care about that's
                // stored in the food correlation.
                AAPLFoodItem *foodItem = [self foodItemFromFoodCorrelation:foodCorrelation];

                [self.foodItems addObject:foodItem];
            }
            
            [self.tableView reloadData];
        });
    }];
    
    [self.healthStore executeQuery:query];
}

- (AAPLFoodItem *)foodItemFromFoodCorrelation:(HKCorrelation *)foodCorrelation {
    // Fetch the name fo the food.
    NSString *foodName = foodCorrelation.metadata[HKMetadataKeyFoodType];
    
    // Fetch the total energy from the food.
    HKQuantityType *energyConsumedType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryEnergyConsumed];
    NSSet *energyConsumedSamples = [foodCorrelation objectsForType:energyConsumedType];
    
    // Note that we only have one energy consumed sample correlation (for Fit specifically).
    HKQuantitySample *energyConsumedSample = [energyConsumedSamples anyObject];
    
    HKQuantity *energyQuantityConsumed = [energyConsumedSample quantity];
    
    double joules = [energyQuantityConsumed doubleValueForUnit:[HKUnit jouleUnit]];
    
    return [AAPLFoodItem foodItemWithName:foodName joules:joules];
}

#pragma mark - Writing HealthKit Data

- (void)addFoodItem:(AAPLFoodItem *)foodItem {
    // Create a new food correlation for the given food item.
    HKCorrelation *foodCorrelationForFoodItem = [self foodCorrelationForFoodItem:foodItem];
    
    [self.healthStore saveObject:foodCorrelationForFoodItem withCompletion:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [self.foodItems insertObject:foodItem atIndex:0];
                
                NSIndexPath *indexPathForInsertedFoodItem = [NSIndexPath indexPathForRow:0 inSection:0];
                
                [self.tableView insertRowsAtIndexPaths:@[indexPathForInsertedFoodItem] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
            else {
                NSLog(@"An error occured saving the food %@. In your app, try to handle this gracefully. The error was: %@.", foodItem.name, error);

                abort();
            }
        });
    }];
}

- (HKCorrelation *)foodCorrelationForFoodItem:(AAPLFoodItem *)foodItem {
    NSDate *now = [NSDate date];
    
    HKQuantity *energyQuantityConsumed = [HKQuantity quantityWithUnit:[HKUnit jouleUnit] doubleValue:foodItem.joules];
    
    HKQuantityType *energyConsumedType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryEnergyConsumed];
    
    HKQuantitySample *energyConsumedSample = [HKQuantitySample quantitySampleWithType:energyConsumedType quantity:energyQuantityConsumed startDate:now endDate:now];
    NSSet *energyConsumedSamples = [NSSet setWithObject:energyConsumedSample];
    
    HKCorrelationType *foodType = [HKObjectType correlationTypeForIdentifier:HKCorrelationTypeIdentifierFood];

    NSDictionary *foodCorrelationMetadata = @{HKMetadataKeyFoodType: foodItem.name};

    HKCorrelation *foodCorrelation = [HKCorrelation correlationWithType:foodType startDate:now endDate:now objects:energyConsumedSamples metadata:foodCorrelationMetadata];
    
    return foodCorrelation;
}

#pragma mark - UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.foodItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [tableView dequeueReusableCellWithIdentifier:AAPLJournalViewControllerTableViewCellReuseIdentifier forIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    AAPLFoodItem *foodItem = self.foodItems[indexPath.row];
    
    cell.textLabel.text = foodItem.name;
    
    NSEnergyFormatter *energyFormatter = [self energyFormatter];
    cell.detailTextLabel.text = [energyFormatter stringFromJoules:foodItem.joules];
}

#pragma mark - Segue Interaction

- (IBAction)performUnwindSegue:(UIStoryboardSegue *)segue {
    AAPLFoodPickerViewController *foodPickerViewController = [segue sourceViewController];
    
    AAPLFoodItem *selectedFoodItem = foodPickerViewController.selectedFoodItem;
    
    [self addFoodItem:selectedFoodItem];
}

#pragma mark - Convenience

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
