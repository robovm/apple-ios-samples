/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This is the loading view controller for showing an activity indicator and transitioning to a table of results or
                an error view.
*/

import UIKit

class LoadingViewController: UIViewController {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var results = Results()
    var codeSample: CodeSample?
    var error: NSError?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        activityIndicator.startAnimating()
    }
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let spinner = activityIndicator {
            spinner.stopAnimating()
        }
        if segue.identifier == "ShowResult" {
            if let resultsViewController = segue.destinationViewController as? ResultsViewController {
                resultsViewController.codeSample = self.codeSample
                resultsViewController.results = self.results.items.count > 0 ? self.results : Results(items: [NoResults()])
            }
        } else if segue.identifier == "ShowError" {
            if let errorViewController = segue.destinationViewController as? ErrorViewController {
                errorViewController.error = self.error
            }
        }
    }

}
