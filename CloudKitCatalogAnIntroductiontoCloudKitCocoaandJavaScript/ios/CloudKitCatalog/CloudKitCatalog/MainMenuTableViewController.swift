/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A MainMenuTableViewController displays the main menu of code sample groups.
*/

import UIKit

class MainMenuTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    var codeSampleGroups = [CodeSampleGroup]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadMenu()
    }
    
    override func viewDidAppear(animated: Bool) {
        if codeSampleGroups.count > 0 {
            if let _ = codeSampleGroups.last?.codeSamples.first as? MarkNotificationsReadSample {
                tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: codeSampleGroups.count - 1, inSection: 0)], withRowAnimation: .None)
            }
        }
    }

    
    func loadMenu() {
        let discoverability = CodeSampleGroup(
            title: "Discoverability",
            icon: UIImage(named: "Discoverability")!,
            codeSamples: [
                RequestApplicationPermissionSample(),
                FetchUserRecordIDSample(),
                DiscoverUserInfoWithUserRecordIDSample(),
                DiscoverUserInfoWithEmailAddressSample(),
                DiscoverAllContactUserInfosSample()
            ]
        )
        
        let zones = CodeSampleGroup(
            title: "Zones",
            icon: UIImage(named: "Zones")!,
            codeSamples: [
                SaveRecordZoneSample(),
                DeleteRecordZoneSample(),
                FetchRecordZoneSample(),
                FetchAllRecordZonesSample()
            ]
        )
        
        let query = CodeSampleGroup(
            title: "Query",
            icon: UIImage(named: "Query")!,
            codeSamples: [
                PerformQuerySample()
            ]
        )
        
        let records = CodeSampleGroup(
            title: "Records",
            icon: UIImage(named: "Records")!,
            codeSamples: [
                SaveRecordSample(),
                DeleteRecordSample(),
                FetchRecordSample()
            ]
        )
        
        let sync = CodeSampleGroup(
            title: "Sync",
            icon: UIImage(named: "Sync")!,
            codeSamples: [
                FetchRecordChangesSample()
            ]
        )
        
        let subscriptions = CodeSampleGroup(
            title: "Subscriptions",
            icon: UIImage(named: "Subscriptions")!,
            codeSamples: [
                SaveSubscriptionSample(),
                DeleteSubscriptionSample(),
                FetchSubscriptionSample(),
                FetchAllSubscriptionsSample()
            ]
        )
        
        let notifications = CodeSampleGroup(
            title: "Notifications",
            icon: UIImage(named: "Notifications")!,
            codeSamples: [
                MarkNotificationsReadSample()
            ]
        )

        codeSampleGroups = [discoverability, query, zones, records, sync, subscriptions, notifications]
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return codeSampleGroups.count
    }


    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let codeSampleGroup = codeSampleGroups[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier("MainMenuItem", forIndexPath: indexPath) as! MainMenuTableViewCell
        cell.menuLabel.text = codeSampleGroup.title
        cell.menuIcon.image = codeSampleGroup.icon
        if codeSampleGroup.codeSamples.count > 1 {
            cell.accessoryType = .DisclosureIndicator
        } else if codeSampleGroup.codeSamples.count == 1 {
            let codeSample = codeSampleGroup.codeSamples.first
            if let notificationSample = codeSample as? MarkNotificationsReadSample where UIApplication.sharedApplication().isRegisteredForRemoteNotifications() {
                if notificationSample.cache.addedIndices.count > 0 {
                    cell.badgeLabel.superview!.layer.cornerRadius = cell.badgeLabel.font.pointSize * 1.2/2
                    cell.badgeLabel.text = String(notificationSample.cache.addedIndices.count)
                    cell.badgeLabel.superview!.hidden = false
                    cell.badgeLabel.hidden = false
                } else {
                    cell.badgeLabel.hidden = true
                    cell.badgeLabel.superview!.hidden = true
                }
            }
        }
        return cell
    }


    // MARK: - Navigation
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let codeSampleGroup = codeSampleGroups[indexPath.row]
        let segueIdentifier: String
        if codeSampleGroup.codeSamples.count > 1 {
            segueIdentifier = "ShowSubmenu"
        } else {
            segueIdentifier = "ShowCodeSampleFromMenu"
        }
        self.performSegueWithIdentifier(segueIdentifier, sender: self)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let indexPath = tableView.indexPathForSelectedRow {
            let selectedCodeSampleGroup = codeSampleGroups[indexPath.row]
            if segue.identifier == "ShowSubmenu" {
                let submenuViewController = segue.destinationViewController as! SubmenuTableViewController
                submenuViewController.codeSamples = selectedCodeSampleGroup.codeSamples
                submenuViewController.groupTitle = selectedCodeSampleGroup.title
            } else if segue.identifier == "ShowCodeSampleFromMenu" && selectedCodeSampleGroup.codeSamples.count > 0 {
                let codeSampleViewController = segue.destinationViewController as! CodeSampleViewController
                codeSampleViewController.selectedCodeSample = selectedCodeSampleGroup.codeSamples[0]
                codeSampleViewController.groupTitle = selectedCodeSampleGroup.title
            }
        }
    }


}
