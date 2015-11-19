/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
This class manages the presentation of the Historical view of the users activity.
*/

import UIKit

class HistoryViewController: UIViewController, UITableViewDataSource {
    // MARK: Properties

    static let textCellIdentifier = "HistoryCell"

    let motionManager = MotionManager()

    @IBOutlet weak var historyTableView: UITableView!

    /**
        An array of title / detail text label creation handlers. The left hand
        side string is the title of the label, while the right hand side is a closure
        that maps an `Activity` to some derived property of the activity to use
        in a text label.
    */
    let recentActivityItems: [(text: String, detailTextCreationHandler: Activity -> String)] = [
        ("Start Date",          { $0.startDateDescription }),
        ("End Date",            { $0.endDateDescription }),
        ("Duration",            { $0.activityDuration }),
        ("Pace Per Mile",       { $0.calculatedPace }),
        ("Distance (Miles)",    { $0.distanceInMiles }),
        ("Distance (Meters)",   { String($0.distance ?? 0) }),
        ("Number of Steps",     { String($0.numberOfSteps ?? 0) }),
        ("Floors Ascended",     { String($0.floorsAscended ?? 0) }),
        ("Floors Descended",    { String($0.floorsDescended ?? 0) })
    ]

    // MARK: View Controller

    override func viewDidLoad() {
        super.viewDidLoad()

        setNeedsStatusBarAppearanceUpdate()
    }

    override func viewWillAppear(animated: Bool) {
        // The `completionHandler` is executed on the main thread.
        motionManager.queryForRecentActivityData(historyTableView.reloadData)
    }

    // MARK: UITableViewDataSource

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.motionManager.recentActivities.count
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // This is the number of properties defined in `recentActivityItems(_:)`.
        let activity = motionManager.recentActivities[section].activity

        if activity.running || activity.walking {
            // Display all of the fields for running and walking.
            return recentActivityItems.count
        }
        else {
            // For all other activities only present Start Date, End Date, and Duration.
            return 3
        }
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(HistoryViewController.textCellIdentifier, forIndexPath: indexPath)

        let activity = motionManager.recentActivities[indexPath.section]

        let item = recentActivityItems[indexPath.row]

        cell.textLabel!.text = item.text
        cell.detailTextLabel!.text = item.detailTextCreationHandler(activity)
        cell.userInteractionEnabled = false

        return cell
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return motionManager.recentActivities[section].activityType
    }
}
