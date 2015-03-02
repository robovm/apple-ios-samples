/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                Displays energy-related information retrieved from HealthKit.
            
*/

#import "AAPLEnergyViewController.h"
#import "HKHealthStore+AAPLExtensions.h"

@interface AAPLEnergyViewController()

@property (nonatomic, weak) IBOutlet UILabel *activeEnergyBurnedValueLabel;
@property (nonatomic, weak) IBOutlet UILabel *restingEnergyBurnedValueLabel;
@property (nonatomic, weak) IBOutlet UILabel *consumedEnergyValueLabel;
@property (nonatomic, weak) IBOutlet UILabel *netEnergyValueLabel;

@property (nonatomic) double activeEnergyBurned;
@property (nonatomic) double restingEnergyBurned;
@property (nonatomic) double energyConsumed;
@property (nonatomic) double netEnergy;

@end

@implementation AAPLEnergyViewController

#pragma mark - View Life Cycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.refreshControl addTarget:self action:@selector(refreshStatistics) forControlEvents:UIControlEventValueChanged];
    
    [self refreshStatistics];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshStatistics) name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

#pragma mark - Reading HealthKit Data

- (void)refreshStatistics {
    [self.refreshControl beginRefreshing];
    
    HKQuantityType *energyConsumedType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryEnergyConsumed];
    HKQuantityType *activeEnergyBurnType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned];
    
    // First, fetch the sum of energy consumed samples from HealthKit. Populate this by creating your
    // own food logging app or using the food journal view controller.
    [self fetchSumOfSamplesTodayForType:energyConsumedType unit:[HKUnit jouleUnit] completion:^(double totalJoulesConsumed, NSError *error) {
        
        // Next, fetch the sum of active energy burned from HealthKit. Populate this by creating your
        // own calorie tracking app or the Health app.
        [self fetchSumOfSamplesTodayForType:activeEnergyBurnType unit:[HKUnit jouleUnit] completion:^(double activeEnergyBurned, NSError *error) {

            // Last, calculate the user's basal energy burn so far today.
            [self fetchTotalBasalBurn:^(HKQuantity *basalEnergyBurn, NSError *error) {
            
                if (!basalEnergyBurn) {
                    NSLog(@"An error occurred trying to compute the basal energy burn. In your app, handle this gracefully. Error: %@", error);
                }
                
                // Update the UI with all of the fetched values.
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.activeEnergyBurned = activeEnergyBurned;
                    
                    self.restingEnergyBurned = [basalEnergyBurn doubleValueForUnit:[HKUnit jouleUnit]];
                    
                    self.energyConsumed = totalJoulesConsumed;
                    
                    self.netEnergy = self.energyConsumed - self.activeEnergyBurned - self.restingEnergyBurned;
                    
                    [self.refreshControl endRefreshing];
                });
            }];
        }];
    }];
}

- (void)fetchSumOfSamplesTodayForType:(HKQuantityType *)quantityType unit:(HKUnit *)unit completion:(void (^)(double, NSError *))completionHandler {
    NSPredicate *predicate = [self predicateForSamplesToday];
    
    HKStatisticsQuery *query = [[HKStatisticsQuery alloc] initWithQuantityType:quantityType quantitySamplePredicate:predicate options:HKStatisticsOptionCumulativeSum completionHandler:^(HKStatisticsQuery *query, HKStatistics *result, NSError *error) {
        HKQuantity *sum = [result sumQuantity];
        
        if (completionHandler) {
            double value = [sum doubleValueForUnit:unit];
            
            completionHandler(value, error);
        }
    }];
    
    [self.healthStore executeQuery:query];
}

// Calculates the user's total basal (resting) energy burn based off of their height, weight, age,
// and biological sex. If there is not enough information, return an error.
- (void)fetchTotalBasalBurn:(void(^)(HKQuantity *basalEnergyBurn, NSError *error))completion {
    NSPredicate *todayPredicate = [self predicateForSamplesToday];
    
    HKQuantityType *weightType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
    HKQuantityType *heightType = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
    
    [self.healthStore aapl_mostRecentQuantitySampleOfType:weightType predicate:nil completion:^(HKQuantity *weight, NSError *error) {
        if (!weight) {
            completion(nil, error);
            
            return;
        }
        
        [self.healthStore aapl_mostRecentQuantitySampleOfType:heightType predicate:todayPredicate completion:^(HKQuantity *height, NSError *error) {
            if (!height) {
                completion(nil, error);
                
                return;
            }
            
            NSDate *dateOfBirth = [self.healthStore dateOfBirthWithError:&error];
            if (!dateOfBirth) {
                completion(nil, error);
                
                return;
            }
            
            HKBiologicalSexObject *biologicalSexObject = [self.healthStore biologicalSexWithError:&error];
            if (!biologicalSexObject) {
                completion(nil, error);
                
                return;
            }
            
            // Once we have pulled all of the information without errors, calculate the user's total basal energy burn
            HKQuantity *basalEnergyBurn = [self calculateBasalBurnTodayFromWeight:weight height:height dateOfBirth:dateOfBirth biologicalSex:biologicalSexObject];
            
            completion(basalEnergyBurn, nil);
        }];
    }];
}

- (HKQuantity *)calculateBasalBurnTodayFromWeight:(HKQuantity *)weight height:(HKQuantity *)height dateOfBirth:(NSDate *)dateOfBirth biologicalSex:(HKBiologicalSexObject *)biologicalSex {
    // Only calculate Basal Metabolic Rate (BMR) if we have enough information about the user
    if (!weight || !height || !dateOfBirth || !biologicalSex) {
        return nil;
    }

    // Note the difference between calling +unitFromString: vs creating a unit from a string with
    // a given prefix. Both of these are equally valid, however one may be more convenient for a given
    // use case.
    double heightInCentimeters = [height doubleValueForUnit:[HKUnit unitFromString:@"cm"]];
    double weightInKilograms = [weight doubleValueForUnit:[HKUnit gramUnitWithMetricPrefix:HKMetricPrefixKilo]];
    
    NSDate *now = [NSDate date];
    NSDateComponents *ageComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:dateOfBirth toDate:now options:NSCalendarWrapComponents];
    NSUInteger ageInYears = ageComponents.year;

    // BMR is calculated in kilocalories per day.
    double BMR = [self calculateBMRFromWeight:weightInKilograms height:heightInCentimeters age:ageInYears biologicalSex:[biologicalSex biologicalSex]];

    // Figure out how much of today has completed so we know how many kilocalories the user has burned.
    NSDate *startOfToday = [[NSCalendar currentCalendar] startOfDayForDate:now];
    NSDate *endOfToday = [[NSCalendar currentCalendar] dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startOfToday options:0];
    
    NSTimeInterval secondsInDay = [endOfToday timeIntervalSinceDate:startOfToday];
    double percentOfDayComplete = [now timeIntervalSinceDate:startOfToday] / secondsInDay;
    
    double kilocaloriesBurned = BMR * percentOfDayComplete;

    return [HKQuantity quantityWithUnit:[HKUnit kilocalorieUnit] doubleValue:kilocaloriesBurned];
}

#pragma mark - Convenience

- (NSPredicate *)predicateForSamplesToday {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDate *now = [NSDate date];
    
    NSDate *startDate = [calendar startOfDayForDate:now];
    NSDate *endDate = [calendar dateByAddingUnit:NSCalendarUnitDay value:1 toDate:startDate options:0];
    
    return [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];
}

/// Returns BMR value in kilocalories per day. Note that there are different ways of calculating the
/// BMR. In this example we chose an arbitrary function to calculate BMR based on weight, height, age,
/// and biological sex.
- (double)calculateBMRFromWeight:(double)weightInKilograms height:(double)heightInCentimeters age:(NSUInteger)ageInYears biologicalSex:(HKBiologicalSex)biologicalSex {
    double BMR;

    // The BMR equation is different between males and females.
    if (biologicalSex == HKBiologicalSexMale) {
        BMR = 66.0 + (13.8 * weightInKilograms) + (5 * heightInCentimeters) - (6.8 * ageInYears);
    }
    else {
        BMR = 655 + (9.6 * weightInKilograms) + (1.8 * heightInCentimeters) - (4.7 * ageInYears);
    }

    return BMR;
}

#pragma mark - NSEnergyFormatter

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

#pragma mark - Setter Overrides

- (void)setActiveEnergyBurned:(double)activeEnergyBurned {
    _activeEnergyBurned = activeEnergyBurned;
    
    NSEnergyFormatter *energyFormatter = [self energyFormatter];
    self.activeEnergyBurnedValueLabel.text = [energyFormatter stringFromJoules:activeEnergyBurned];
}

- (void)setEnergyConsumed:(double)energyConsumed {
    _energyConsumed = energyConsumed;
    
    NSEnergyFormatter *energyFormatter = [self energyFormatter];
    self.consumedEnergyValueLabel.text = [energyFormatter stringFromJoules:energyConsumed];
}

- (void)setRestingEnergyBurned:(double)restingEnergyBurned {
    _restingEnergyBurned = restingEnergyBurned;
    
    NSEnergyFormatter *energyFormatter = [self energyFormatter];
    self.restingEnergyBurnedValueLabel.text = [energyFormatter stringFromJoules:restingEnergyBurned];
}

- (void)setNetEnergy:(double)netEnergy {
    _netEnergy = netEnergy;
    
    NSEnergyFormatter *energyFormatter = [self energyFormatter];
    self.netEnergyValueLabel.text = [energyFormatter stringFromJoules:netEnergy];
}

@end