/*
 Copyright (C) 2015 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A HomeListViewController subclass which allows the user to add and remove homes and set the primary home.
 */

#import "HomeListConfigurationViewController.h"
#import "UIAlertController+Convenience.h"
#import "UIViewController+Convenience.h"
#import "UITableView+Updating.h"

typedef NS_ENUM(NSUInteger, HomeListSection) {
    HomeListSectionHomes = 0,
    HomeListSectionPrimaryHome
};

@implementation HomeListConfigurationViewController

#pragma mark - Table View

- (BOOL)indexPathIsAdd:(NSIndexPath *)indexPath {
    return indexPath.section == HomeListSectionHomes &&
           indexPath.row == self.homeManager.homes.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSUInteger homes = self.homeManager.homes.count;
    switch (section) {
        case HomeListSectionHomes:
            return homes + 1;
        case HomeListSectionPrimaryHome:
            return MAX(homes, 1);
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self indexPathIsAdd:indexPath]) {
        return [tableView dequeueReusableCellWithIdentifier:@"AddHomeCell" forIndexPath:indexPath];
    } else if (self.homeManager.homes.count == 0) {
        return [tableView dequeueReusableCellWithIdentifier:@"NoHomesCell" forIndexPath:indexPath];
    }

    NSString *reuseIdentifier;
    switch (indexPath.section) {
        case HomeListSectionHomes:
            reuseIdentifier = @"HomeCell";
            break;
        case HomeListSectionPrimaryHome:
            reuseIdentifier = @"PrimaryHomeCell";
            break;
    }

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];

    HMHome *home = self.homeManager.homes[indexPath.row];
    cell.textLabel.text = home.name;

    if (indexPath.section == HomeListSectionPrimaryHome) {
        // Show a label for the primary home.
        if (home == self.homeManager.primaryHome) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == HomeListSectionHomes;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self indexPathIsAdd:indexPath]) {
        return UITableViewCellEditingStyleInsert;
    }
    return UITableViewCellEditingStyleDelete;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    switch (section) {
        case HomeListSectionPrimaryHome:
            return NSLocalizedString(@"The primary home is used by Siri to route commands if the home is not specified.", nil);
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == HomeListSectionPrimaryHome) {
        return NSLocalizedString(@"Primary Home", @"Primary Home");
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self removeHomeAtIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([self indexPathIsAdd:indexPath]) {
        [self addNewHome];
    } else if (indexPath.section == HomeListSectionPrimaryHome) {
        HMHome *newPrimaryHome = self.homeManager.homes[indexPath.row];
        [self updatePrimaryHome:newPrimaryHome];
    }
}

- (void)updatePrimaryHome:(HMHome *)newPrimaryHome {
    if (newPrimaryHome == self.homeManager.primaryHome) {
        return;
    }
    [self.homeManager updatePrimaryHome:newPrimaryHome completionHandler:^(NSError *error) {
        if (error) {
            [self hmc_displayError:error];
            return;
        }
        [self didUpdatePrimaryHome];
    }];
}

/**
 *  Reloads the primary home section to check the new primary home.
 */
- (void)didUpdatePrimaryHome {
    NSIndexSet *primaryIndexSet = [NSIndexSet indexSetWithIndex:HomeListSectionPrimaryHome];
    [self.tableView hmc_update:^(UITableView *tableView) {
        [self.tableView reloadSections:primaryIndexSet withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

#pragma mark - HomeKit-related functions

/**
 *  Removes the home associated with a given indexPath on the table.
 *
 *  @param home      The home to remove.
 *  @param indexPath The index path where that home exists on the table.
 */
- (void)removeHomeAtIndexPath:(NSIndexPath *)indexPath {
    HMHome *home = self.homeManager.homes[indexPath.row];

    [self.homeManager removeHome:home completionHandler:^(NSError *error) {
        if (error) {
            [self hmc_displayError:error];
            return;
        }
        [self didRemoveHomeAtIndexPath:indexPath];
    }];
}

/**
 *  Called whenever the home removal process has finished and the
 *  supplied indexPath needs to be removed from the table.
 *
 *  <b>Note:</b> The indexPath is passed here because we can no longer look up
 *               where that home was in the table -- it has been removed.
 *
 *  @param indexPath The indexPath of the removed home's old spot on the table.
 */
- (void)didRemoveHomeAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *primaryIndexPath = [NSIndexPath indexPathForRow:indexPath.row inSection:HomeListSectionPrimaryHome];
    [self.tableView hmc_update:^(UITableView *tableView) {
        // If there aren't any homes, we still want one cell to display 'No Homes'.
        // So just reload it.
        if (self.homeManager.homes.count == 0) {
            [tableView reloadRowsAtIndexPaths:@[primaryIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        } else {
            [tableView deleteRowsAtIndexPaths:@[primaryIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

/**
 *  Caled whenever the home addition process has finished, and a new index needs to open up in the table.
 *
 *  @param home The home that was added.
 */
- (void)didAddHome:(HMHome *)home {
    NSUInteger newHomeIndex = [self.homeManager.homes indexOfObject:home];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:newHomeIndex inSection:HomeListSectionHomes];
    NSIndexPath *primaryIndexPath = [NSIndexPath indexPathForRow:newHomeIndex inSection:HomeListSectionPrimaryHome];

    [self.tableView hmc_update:^(UITableView *tableView) {
        // If we only have 1 home, we want to replace the 'No Homes' cell with the
        // new home. So reload that cell.
        if (self.homeManager.homes.count == 1) {
            [tableView reloadRowsAtIndexPaths:@[primaryIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        } else {
            [tableView insertRowsAtIndexPaths:@[primaryIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        [tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];
}

/**
 *  Prompts the user to input a name for a new Home.
 */
- (void)addNewHome {
    [self hmc_presentAddAlertWithAttributeType:NSLocalizedString(@"Home", @"Home")
                                   placeholder:NSLocalizedString(@"Apartment", @"Apartment")
                                    completion:^(NSString *name) {
                                        [self addHomeWithName:name];
                                    }];
}

/**
 *  Adds a home with a given name to the users HomeKit database.
 *
 *  @param name the new name for the home.
 */
- (void)addHomeWithName:(NSString *)name {
    [self.homeManager addHomeWithName:name completionHandler:^(HMHome *newHome, NSError *error) {
        if (error) {
            [self hmc_displayError:error];
            return;
        }

        [self didAddHome:newHome];
    }];
}

#pragma mark - HMHomeManagerDelegate

- (void)homeManagerDidUpdatePrimaryHome:(HMHomeManager *)manager {
    if (self.tableView.numberOfSections > 1) {
        [self didUpdatePrimaryHome];
    }
}

- (void)homeManager:(HMHomeManager *)manager didAddHome:(HMHome *)home {
    [self didAddHome:home];
}

@end
