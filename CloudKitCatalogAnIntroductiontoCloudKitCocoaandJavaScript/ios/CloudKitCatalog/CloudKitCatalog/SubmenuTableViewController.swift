/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A SubmenuTableViewController displays a second-level menu for those code sample groups that have 
                more than one code sample.
*/

import UIKit

class SubmenuTableViewController: UITableViewController {
    
    // MARK: - Properties
    
    var codeSamples = [CodeSample]()
    var groupTitle: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        if let groupTitle = groupTitle {
            navigationItem.title = groupTitle
        }
        navigationItem.hidesBackButton = (navigationController!.viewControllers.first?.navigationItem.hidesBackButton)!
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return codeSamples.count
    }


    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let codeSample = codeSamples[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier("SubmenuItem", forIndexPath: indexPath) as! SubmenuTableViewCell
        cell.submenuLabel.text = codeSample.title
        return cell
    }


    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowCodeSampleFromSubmenu" {
            let codeSampleViewController = segue.destinationViewController as! CodeSampleViewController
            if let selectedCell = sender as? SubmenuTableViewCell {
                let indexPath = tableView.indexPathForCell(selectedCell)!
                codeSampleViewController.selectedCodeSample = codeSamples[indexPath.row]

            }
        }
    }


}
