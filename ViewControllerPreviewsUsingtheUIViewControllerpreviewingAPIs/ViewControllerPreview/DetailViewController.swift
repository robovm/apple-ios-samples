/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The detail view controller.
*/

import UIKit

class DetailViewController: UIViewController {
    // MARK: Properties

    @IBOutlet weak var detailDescriptionLabel: UILabel!
    
    // Property to hold the detail item's title.
    var detailItemTitle: String?
    
    // Preview action items.
    lazy var previewActions: [UIPreviewActionItem] = {
        func previewActionForTitle(title: String, style: UIPreviewActionStyle = .Default) -> UIPreviewAction {
            return UIPreviewAction(title: title, style: style) { previewAction, viewController in
                guard let detailViewController = viewController as? DetailViewController,
                          item = detailViewController.detailItemTitle else { return }
                
                print("\(previewAction.title) triggered from `DetailViewController` for item: \(item)")
            }
        }
        
        let action1 = previewActionForTitle("Default Action")
        let action2 = previewActionForTitle("Destructive Action", style: .Destructive)
        
        let subAction1 = previewActionForTitle("Sub Action 1")
        let subAction2 = previewActionForTitle("Sub Action 2")
        let groupedActions = UIPreviewActionGroup(title: "Sub Actions…", style: .Default, actions: [subAction1, subAction2] )
        
        return [action1, action2, groupedActions]
    }()

    // MARK: Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Update the user interface for the detail item.
        if let detail = detailItemTitle {
            detailDescriptionLabel.text = detail
        }
        
        // Set up the detail view's `navigationItem`.
        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem()
        navigationItem.leftItemsSupplementBackButton = true
    }
    
    // MARK: Preview actions

    override func previewActionItems() -> [UIPreviewActionItem] {
        return previewActions
    }
}