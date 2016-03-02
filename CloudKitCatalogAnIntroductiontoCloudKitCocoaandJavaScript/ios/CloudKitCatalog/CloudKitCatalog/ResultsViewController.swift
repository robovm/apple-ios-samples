/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A ResultsViewController displays a Results object in a table.
*/

import UIKit

class ResultsViewController: ResultOrErrorViewController, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate {

    // MARK: - Properties
    
    @IBOutlet weak var tableView: TableView!
    @IBOutlet weak var toolbarHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var toolbar: UIToolbar!
    
    var results: Results = Results()
    var codeSample: CodeSample?
    
    var selectedAttributeValue: String?
    
    var activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if results.items.count == 1 {
            let result = results.items[0]
            navigationItem.title = result.summaryField ?? "Result"
        } else {
            navigationItem.title = "Result"
        }
        
        activityIndicator.hidesWhenStopped = true
        
        toggleToolbar()
    }
    
    override func viewDidAppear(animated: Bool) {
        if let codeSample = codeSample as? MarkNotificationsReadSample {
            codeSample.cache.markAsRead()
        }
    }
    
    func toggleToolbar() {
        if toolbarHeightConstraint != nil {
            if results.moreComing {
                toolbar.hidden = false
                toolbarHeightConstraint.constant = 44
            } else {
                toolbarHeightConstraint.constant = 0
                toolbar.hidden = true
            }
        }
    }


    // MARK: - Table view data source

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if results.items.count > 0 && !results.showAsList {
            return results.items[0].attributeList.count
        }
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if results.items.count > 0 && !results.showAsList {
            return results.items[0].attributeList[section].attributes.count
        } else {
            return results.items.count
        }
    }


    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        if results.showAsList {
            let cell = tableView.dequeueReusableCellWithIdentifier("ResultCell", forIndexPath: indexPath) as! ResultTableViewCell
            let result = results.items[indexPath.row]
            cell.resultLabel.text = result.summaryField ?? ""
            cell.changeLabelWidthConstraint.constant = 15
            if results.added.contains(indexPath.row) {
                cell.changeLabel.text = "A"
            } else if results.deleted.contains(indexPath.row) {
                cell.changeLabel.text = "D"
            } else if results.modified.contains(indexPath.row) {
                cell.changeLabel.text = "M"
            } else {
                cell.changeLabelWidthConstraint.constant = 0
            }
            return cell
        }
        
        let attribute = results.items[0].attributeList[indexPath.section].attributes[indexPath.row]
        
        guard let value = attribute.value else {
            let cell = tableView.dequeueReusableCellWithIdentifier("AttributeKeyCell", forIndexPath: indexPath) as! AttributeKeyTableViewCell
            cell.attributeKey.text = attribute.key
            return cell
        }
        
        
        if attribute.image != nil {
            let cell = tableView.dequeueReusableCellWithIdentifier("ImageCell", forIndexPath: indexPath) as! ImageTableViewCell
            cell.attributeKey.text = attribute.key
            cell.attributeValue.text = value.isEmpty ? "-" : value
            cell.assetImage.image = attribute.image
            return cell
        }
        
        let cellIdentifier = attribute.isNested ? "NestedAttributeCell" : "AttributeCell"

        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! AttributeTableViewCell

        cell.attributeKey.text = attribute.key
        cell.attributeValue.text = value.isEmpty ? "-" : value
    
        return cell
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let codeSample = codeSample else { return "" }
        if results.showAsList {
            return codeSample.listHeading
        } else {
            let result = results.items[0]
            return result.attributeList[section].title
        }
        
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if results.items.count > 0 && !results.showAsList {
            let attribute = results.items[0].attributeList[indexPath.section].attributes[indexPath.row]
            if attribute.image != nil {
                return 200.0
            }
        }
        return tableView.rowHeight
    }
    
    
    // Mark: - Responder
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func canPerformAction(action: Selector, withSender sender: AnyObject?) -> Bool {
        return action == "copyAttributeToClipboard"
    }
    
    // MARK: - Actions

    
    @IBAction func handleLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .Ended {
            let point = sender.locationInView(tableView)
            let indexPath = tableView.indexPathForRowAtPoint(point)!
            if let attributeCell = tableView.cellForRowAtIndexPath(indexPath) as? AttributeTableViewCell, let attributeValue = attributeCell.attributeValue {
                self.becomeFirstResponder()
                self.selectedAttributeValue = attributeValue.text ?? ""
                let menuController = UIMenuController.sharedMenuController()
                menuController.setTargetRect(attributeValue.frame, inView: attributeCell)
                menuController.menuItems = [UIMenuItem(title: "Copy attribute value", action: "copyAttributeToClipboard")]
                menuController.setMenuVisible(true, animated: true)
            }
        }
    }
    
    func copyAttributeToClipboard() {
        if let selectedAttributeValue = selectedAttributeValue {
            let pasteBoard = UIPasteboard.generalPasteboard()
            pasteBoard.string = selectedAttributeValue
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "DrillDown", let resultsViewController = segue.destinationViewController as? ResultsViewController, let indexPath = tableView.indexPathForSelectedRow {
            let result = results.items[indexPath.row]
            resultsViewController.results = Results(items: [result])
            resultsViewController.codeSample = codeSample
            resultsViewController.isDrilldown = true
            tableView.deselectRowAtIndexPath(indexPath, animated: false)
        }
    }
    
    
    @IBAction func loadMoreResults(sender: UIBarButtonItem) {
        sender.enabled = false
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        activityIndicator.startAnimating()
        
        if let codeSample = codeSample {
            codeSample.run {
                (results, nsError) in
                
                self.results = results
                
                dispatch_async(dispatch_get_main_queue()) {
                    
                    var indexPaths = [NSIndexPath]()
                    for index in results.added.sort() {
                        indexPaths.append(NSIndexPath(forRow: index, inSection: 0))
                    }
                    if indexPaths.count > 0 {
                        self.tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
                    }
                    indexPaths = []
                    for index in results.deleted.union(results.modified).sort() {
                        indexPaths.append(NSIndexPath(forRow: index, inSection: 0))
                    }
                    if indexPaths.count > 0 {
                        self.tableView.reloadRowsAtIndexPaths(indexPaths, withRowAnimation: .Automatic)
                    }
                    self.navigationItem.rightBarButtonItem = self.doneButton
                    self.activityIndicator.stopAnimating()
                    if results.moreComing {
                        sender.enabled = true
                    } else {
                    
                        UIView.animateWithDuration(0.4, animations: {
                            self.toggleToolbar()
                            self.view.layoutIfNeeded()
                        })
                        
                    }
                    
                }
            }
        }
    }
    

}
