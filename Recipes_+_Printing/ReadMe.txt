### Recipes_+_Printing ###

===========================================================================
DESCRIPTION:

The Recipes sample app lets you browse recipes. This sample adds the ability to print the recipes.

It demonstrates formatting data presented by the application UI in a completely custom way for the printed page. 

By subclassing UIPrintPageRenderer, this sample illustrates intermixing custom drawn page content with content drawn by architecture-provided UIPrintFormatters. 

In addition to custom page content, it also draws custom page headers, page footers, and page breaks.

===========================================================================
BUILD REQUIREMENTS:

iOS 7 SDK

===========================================================================
RUNTIME REQUIREMENTS:

iOS 7 or later.

===========================================================================
PACKAGING LIST:

- RecipesAppDelegate: the application delegate
- RecipeListTableViewController: a UITableViewController for displaying a list of recipes
- RecipeDetailViewController: a UITableViewController for displaying detailed information about a recipe
- InstructionsViewController: a UIViewController for editing a recipe's preparation instructions
- RecipePhotoViewController: a UIViewController for viewing a recipe's photo
- RecipePrintPageRenderer: a UIPrintPageRenderer for rendering multiple recipes for printing
- RecipeTableViewCell: a UITableViewCell for displaying a recipe entry in the RecipeListTableViewController
- Recipe: a model object to represent a single recipe
- RecipesController: a controller to manage a set of recipes

===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.2
- Fix compile time issue.

Version 1.1
- First version. WWDC sample was scaled down to focus more closely on printing.

===========================================================================
Copyright (C) 2011-2014 Apple Inc. All rights reserved.
