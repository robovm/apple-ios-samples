# Fit: HealthKit in Action

===========================================================================

Fit is a sample intended as a quick introduction to HealthKit. It teaches you everything from writing data into HealthKit to reading data from HealthKit. This information may have been entered into the store by some other app; e.g. a user's birthday may have been entered into Health, and a user's weight by some popular weight tracker app. However, some of this information may not yet be populated (or you may not have access to it) and you should consider how to present this scenario to your users.

Fit shows examples of using queries to retrieve information from HealthKit using sample queries and statistics queries. Fit gives you a quick introduction into using the new Foundation classes NSLengthFormatter, NSMassFormatter, and NSEnergyFormatter.

Note: For important guidelines that govern how you can use HealthKit and user health information in your app, see https://developer.apple.com/app-store/review/guidelines/#healthkit.

===========================================================================
Using the Sample

Fit tries to emulate a fitness tracker app. The goal of this fitness app is to track the net energy burn for a given day. Net energy is defined in this app as:

    Total Energy Consumed - Total Active Energy Burned - Total Resting Energy Burned.
    
    This resting or basal energy burn is calculated as a function of your height, weight, age, sex and the time of the day.

AAPLProfileViewController shows how to retrieve a user's age, height, and weight information from HealthKit. This is an example of retrieving a characteristic data type. Height and weight are quantity types, and you will learn how to retrieve these quantities from an HKHealthStore object using a sample query. You’ll also notice code to save valid user entered height and weight information into a HKHealthStore object. Note that in order to see a valid height or weight calculation in the profile view controller, you'll want to make sure you have height or weight data saved. You can either do this from within the Fit app or you can store this data in another app (such as Health in the "Health Data" tab).

AAPLJournalViewController tracks the user’s food consumption details for the day. You will find code that lets a user save into and retrieve food items from HealthKit, where each item is stored as an HKCorrelation instance. Saving each food item as an HKCorrelation lets us correlate the various pieces of information associated with that entry. For instance, in our sample code, we save the food item's name, calories, fat and carb information, all correlated to each other. You will also see how the journal is updated using a sample query to retrieve all the HKCorrelation instances from HealthKit.

AAPLEnergyViewController shows an example of using the statistics query. This sample uses a statistics query to retrieve the cumulative sum of calories of all the food samples entered using the AAPLJournalViewController.

===========================================================================
Build/Runtime Requirements

This sample requires capabilities that are only available when run on an iOS device. Note that in order to run this sample on a device, you will need to change the bundle identifier of the application.

Building this sample requires Xcode 6.0 and iOS 8.0 SDK
Running the sample requires iOS 8.0 or later.

===========================================================================
Copyright (C) 2008-2014 Apple Inc. All rights reserved.