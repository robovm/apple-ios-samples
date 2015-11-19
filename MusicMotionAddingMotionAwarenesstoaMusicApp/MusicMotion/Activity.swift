/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This class represents a significant activity the user performed.
*/

import Foundation
import CoreMotion

/**
    This struct is responsible for storing the activity data and providing relevant
    pedometer properties such as pace and distance.
*/
struct Activity: CustomDebugStringConvertible {
    // MARK: Properties

    static let milesPerMeter = 0.000621371192

    var activity: CMMotionActivity
    var startDate: NSDate
    var endDate: NSDate

    var timeInterval = 0.0

    var numberOfSteps: Int?
    var distance: Int?
    var floorsAscended: Int?
    var floorsDescended: Int?

    // MARK: Initializers

    init(activity: CMMotionActivity, startDate: NSDate, endDate: NSDate, pedometerData: CMPedometerData? = nil) {
        self.activity = activity

        self.startDate = startDate

        self.endDate = endDate

        self.timeInterval = endDate.timeIntervalSinceDate(startDate)

        guard let pedometerData = pedometerData where activity.walking || activity.running else {
            return
        }

        numberOfSteps = pedometerData.numberOfSteps.integerValue

        if let distance = pedometerData.distance?.integerValue where distance > 0 {
            self.distance = distance
        }

        if let floorsAscended = pedometerData.floorsAscended?.integerValue {
            self.floorsAscended = floorsAscended
        }

        if let floorsDescended = pedometerData.floorsDescended?.integerValue {
            self.floorsDescended = floorsDescended
        }
    }

    // MARK: Computed Properties

    var activityType: String {
        if activity.walking {
            return "Walking"
        }
        else if activity.running {
            return "Running"
        }
        else if activity.automotive {
            return "Automotive"
        }
        else if activity.cycling {
            return "Cycling"
        }
        else if activity.stationary {
            return "Stationary"
        }
        else {
            return "Unknown"
        }
    }

    var startDateDescription: String {
        return createLocalTimeDateStringFromDate(startDate)
    }

    var endDateDescription: String {
        return createLocalTimeDateStringFromDate(endDate)
    }

    var activityDuration: String {
        return createTimeStringFromSeconds(timeInterval)
    }

    var distanceInMiles: String {
        guard let distance = distance else { return "N/A" }

        return String(format: "%.7f", Double(distance) * Activity.milesPerMeter)
    }

    var calculatedPace: String {
        guard let distance = distance else { return "N/A" }

        let miles = Double(distance) * Activity.milesPerMeter
        let paceInSecondsPerMile = timeInterval / miles

        return createTimeStringFromSeconds(paceInSecondsPerMile)
    }

    // MARK: Helper Functions

    private func createTimeStringFromSeconds(seconds: NSTimeInterval) -> String {
        let calendar = NSCalendar.currentCalendar()

        let startDate = NSDate()
        let endDate = NSDate(timeInterval: seconds, sinceDate: startDate)

        let unitFlags: NSCalendarUnit = [.Hour, .Minute, .Second]

        let conversionInfo = calendar.components(unitFlags, fromDate: startDate, toDate: endDate, options: [])

        return String(format: "%dh %dm %ds", conversionInfo.hour, conversionInfo.minute, conversionInfo.second)
    }

    private func createLocalTimeDateStringFromDate(date: NSDate) -> String {
        return NSDateFormatter.localizedStringFromDate(date, dateStyle: .MediumStyle, timeStyle: .MediumStyle)
    }

    // MARK: CustomDebugStringConvertible

    var debugDescription: String {
        return "ActivityType: \(activityType), StartDate: \(startDate), EndDate: \(endDate), TimeInterval: \(timeInterval), Steps: \(numberOfSteps), Distance: \(distance), FloorsAscended: \(floorsAscended), FloorsDescended: \(floorsDescended) "
    }
}
