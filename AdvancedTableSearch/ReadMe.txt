AdvancedTableSearch
===================

This sample demonstrates how to use the UISearchDisplayController object in conjunction with a UISearchBar, effectively filtering in and out the contents of that table. If an iOS application has large amounts of table data, this sample shows how to filter it down to a manageable amount so that users to scroll through less content in a table.

It shows how you can:
- Create a UISearchDisplayController.
- Use scopes on UISearchBar with a search display controller.
- Manage the interaction between the search display controller and a containing UINavigationController
	(there is no code for this -- the navigation bar is moved around as necessary).
- Return different results for the main table view and the search display controller's table view.
- Handle the destruction and re-creation of a search display controller when receiving a memory warning.

"AdvancedTableSearch" is a continuation of the "TableSearch" sample, yet provides a more advanced search algorithm on a more complex data source.

So if a table view row contains multiple fields of information, the user may want to search on some or all those fields.

Instead of simple string comparisons to filter out search results, the advanced version uses "filteredArrayUsingPredicate" on the NSArray of objects.  This approach uses NSPredicate, an advanced way of predicating a search.  To perform a search across multiple fields of an NSObject subclass, this sample makes use of compound predicates (NSCompoundPredicate) and NSExpressions to create a more advanced search algorithm.

The product object has: 1) title, 2) year introduced, 3) price

The user can type in the search field any number of search terms to filter out the the desired product.  The user can type "2007", and all products introduced in 2007 will appear in the table.  If the user types "2007 i", the search will return all objects introduced in 2007, starting with the letter "i".

Using the Sample
----------------
Tap the search field and as you enter case insensitive text the list shinks/expands based on the filter text. An empty string will show the entire contents.  To get back the entire contents once you have filtered the content, touch the search bar again, tap the clear ('x') button and then tap cancel.


=======================================================
Copyright (C) 2013 Apple Inc. All rights reserved.