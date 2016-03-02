/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This customizes UITableView by removing the empty cells of a plain table and adjusting the background color
                of a grouped table.
*/

import UIKit

class TableView: UITableView {

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        if style == .Grouped {
            backgroundView = nil
            backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
        } else if style == .Plain {
            tableFooterView = UIView()
        }
    }

}
