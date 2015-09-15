# TheElements


## DESCRIPTION
+ TheElements is a sample application that provides access to the data contained in the
Periodic Table of the Elements. The Periodic Table of the Elements catalogs all the known
atomic elements in the universe.

+ TheElements provides this data in multiple formats, allowing you to sort the data by name,
atomic number, symbol name, and an elements physical state at room temperature.

+ TheElements is structured as a Model-View-Controller application. There is distinct
separation of the model data, the views used to present that data, and the controllers which
act as a liaison between the model and controller.

+ The application illustrates the following techniques:

 Configuring and responding to selections in a tab bar
 Displaying information in a tableview using both plain and grouped style table views
 Using navigation controllers to navigate deeper into a data structure
 Subclassing UIView
 Providing a custom UITableViewCell consisting of multiple subviews
 Implementing the UITableViewDelegate protocol
 Implementing the UITableViewDataSource protocol
 Reacting to taps in views
 Open a URL to an external web site using Safari
 Flipping view content from front to back
 Creating a reflection of a view in the interface

+ TheElements is a fairly large application with many classes. This document attempts to explain
those classes and their roles in the application.

+ To understand the flow of screens from one to the next when using the application see the
ApplicationFlow.pdf included with the project.


## BUILD REQUIREMENTS
+ iOS 8.0 SDK or later


## RUNTIME REQUIREMENTS
+ iOS 8.0 or later


## PACKAGING LIST

+ AtomicElement.h
AtomicElement.m

The AtomicElement class encapsulates the data for a single atomic element. It contains the
name, atomic number, symbol, and state information, along with layout information
(horizontal and vertical positions). It returns the image that represents the state of the
object, which displayed in each visual representation of an element.


+ PeriodicTable.h
PeriodicTable.m

The PeriodicTable class encapsulates the collection of AtomicElement instances. It provides
access to elements in a variety of formats: sorted numerically, sorted by name, sorted by
symbol, elements for an atomic state, and elements that begin with a specific character.
This data is pre-sorted and indexed when the raw element information is read from the
Elements.plist. The PeriodicTable class is a singleton, there is one instance that is shared
by the entire application.


+ ElementsTableViewController.h
ElementsTableViewController.m

ElementsTableViewController is the controller class that is used for each of the four
representations of the elements data that is displayed in UITableView objects. It is
responsible for creating and configuring instances of UITableView when requested.
The ElementsTableViewController class adopts the UITableViewDelegate protocol, agreeing
to provide the cells for the tableview.

It provides instances of the custom table cell class ElementTableViewCell pre-populated
with the appropriate AtomicElement object when asked by the UITableViewDelegate for the
cell to be displayed for a row and section.

As the UITableView delegate an instance of the ElementsTableViewController class will also
receive messages when a user taps on a row in the table view. Upon receiving this event it
asks its data source object for the AtomicElement object that it represents and then instructs
the navigation controller for the view controller to push an instance of the
AtomicElementViewController class onto the navigation stack.


+ AtomicElementTableViewCell.h
AtomicElementTableViewCell.m

Each row in a UITableView displays a custom table cell of the class AtomicElementTableViewCell.
This custom class displays a graphic indicating the symbol, atomic number, and state of the
element, as well as a text label with the generally accepted name of the element.

+ ElementsDataSourceProtocol.h
ElementsSortedByNameDataSource.h
ElementsSortedByNameDataSource.m
ElementsSortedByNumberDataSource.h
ElementsSortedByNumberDataSource.m
ElementsSortedBySymbolDataSource.h
ElementsSortedBySymbolDataSource.m
ElementsSortedByStateDataSource.h
ElementsSortedByStateDataSource.m

The data source classes provide the data for the ElementsTableViewController, the UITabBarItem,
the UINavigationController and the UITableView that is displayed within those views. There
are four classes: ElementsSortedByNameDataSource, ElementsSortedByAtomicNumberDataSource,
ElementsSortedBySymbolDataSource, and ElementsSortedByStateDataSource.

These classes all adopt and implement the UITableViewDataSource protocol and are set as the
dataSource for the UITableView displayed for the data sorted in each manner. As the table
view requires data it sends messages to its dataSource (one of these class instances) and
that data is displayed.

These classes also adopt the ElementsDataSource protocol. This protocol is defined by the
application and provides a uniform means for the ElementsTableViewController to determine
the title displayed in the tab bar and navigation controller, the images displayed in the
UITabBarItem for this data representation, and the style the UITableView uses to display
the data (indexed or grouped depending on the sorted representation of the Periodic
Table data.


+ AtomicElementViewController.h
AtomicElementViewController.m

When a user taps on a row in a UITableView listing a collection of elements the table's
delegate (ElementsTableViewController) receives a message. Upon receiving this event the
ElementsTableViewController asks its data source object for the AtomicElement object that
it represents and then instructs the navigation controller for the view controller to push
an instance of the AtomicElementViewController class onto the navigation stack.

The AtomicElementViewController is responsible for displaying the single element view as a
large tile. The initial view displayed is the AtomicElementView. It is also responsible for
ensuring that the flipper button in the navigation bar shows that there is another view
available for the content by tapping on the tile.


+ AtomicElementView.h
AtomicElementView.m

The AtomicElementView is displayed in the content of the AtomicElementViewController.
It displays the atomic name, number, symbol, and state of the element. By tapping on the
element the display will 'flip' to show the AtomicElementFlippedView.


+ AtomicElementFlippedView.h
AtomicElementFlippedView.m

This view displays the Atomic name, number, and state of the current element, as well as a
link to the appropriate page on Wikipedia.



Copyright (C) 2008-2015 Apple Inc. All rights reserved.