
TableViewSuite
==============

This sample shows how to use UITableView and UITableViewController through a progression of increasingly advanced applications that display information about time zones.

* The first example shows a simple list of the time zone names. It shows how to display a simple data set in a table view.

* The second example shows the time zones split into sections by region, with the region name as the section heading. It shows how to create an indexed table view.

* The third example shows how to set up a table view to display an index. The time zones are separated into sections using UILocalizedIndexedCollation.

* The fourth and fifth samples show two approaches to implementing a custom cell.

When implementing a table view cell, there's a tension between optimal scrolling performance and optimal edit/reordering performance. You should typically use subviews in the cell's content view.

When you have an edit or reordering control, using subviews makes the implementation easier, and the animations perform better because UIKit doesn't have to redraw during animations.

Subviews have two costs:
1) Initialization. This can be largely mitigated by reusing table cells.
2) Compositing. This can be largely mitigated by making the views opaque. Often, one translucent subview is fine, but more than one frequently causes frame drops while scrolling.

If the content is complex, however (more than about three subviews), scrolling performance may suffer. If this becomes a problem, you can instead draw directly in a subview of the table view cell's content view.

* The fourth example displays more information about each time zone, such as the time and relative day in that time zone. Its main aim is to show how you can customize a table view cell using subviews. The views are laid out using auto layout. Notice that the content compression resistance priority of the time field is increased slightly so that the region name field is narrowed if the name is too long (as might be the case with, for example, “Buenos Aires (Argentina)”).
(The fourth example also introduces custom classes to represent regions and time zones to help reduce the overhead of calculating the required information -- these are also used in the fifth example.)

* The fifth example is an extension of the fourth. It displays even more information about each time zone, such as the time and relative day in that time zone. Its shows how you can create a custom table view cell that contains a custom view that draws its content in -drawRect:.


================================================================================
Copyright (C) 2008-2013 Apple Inc. All rights reserved.
