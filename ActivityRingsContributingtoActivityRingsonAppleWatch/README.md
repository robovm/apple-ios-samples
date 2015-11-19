# Activity Rings

---
## About Activity Rings

This sample demonstrates the proper way to work with HealthKit on Apple Watch to contribute to the Activity Rings and have your app associated with workouts and calories in the Activity app on iPhone.

There are a few specific pieces to pay attention to for a great user experience:

1. The HKWorkoutSession is started and stopped on Apple Watch. This ensures the app is frontmost during the workout session.
2. The HKWorkout is saved on Apple Watch. This ensures the activity contributes to the user's Activity Rings on Apple Watch.
3. The samples from the timespan of the workout session are associated to the HKWorkout. This ensures that your app is displayed in the Workouts section of the Activity app on iPhone, for the given day.
4. You must instantiate your own HKQuantitySample objects and associate those to the HKWorkout in order for your app name to be displayed in the user's Move graph in the Activity app on iPhone.

Note: For important guidelines that govern how you can use HealthKit and user health information in your app, see https://developer.apple.com/app-store/review/guidelines/#healthkit

---
## Build/Runtime Requirements

Building this sample requires Xcode 7.1, iOS 9.1 SDK, and watchOS 2.0.1 SDK.
Running the sample requires iOS 9.1 and watchOS 2.0 or later.

Note: Before being able to run the sample you will need to update the bundle identifiers for each of the targets and associate the WatchKit extension to the WatchKit app and the WatchKit app to the iOS app.

---
Copyright (C) 2008-2015 Apple Inc. All rights reserved.