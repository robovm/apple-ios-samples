/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A MainMenuTableViewCell is a UITableViewCell with an icon, label, and an optional badge label (used only
                for the Notifications menu item.
*/

import UIKit

class MainMenuTableViewCell: UITableViewCell {
    
    // MARK: - Properties
    
    @IBOutlet weak var menuIcon: UIImageView!
    @IBOutlet weak var menuLabel: UILabel!
    @IBOutlet weak var badgeLabel: UILabel!
    
}
