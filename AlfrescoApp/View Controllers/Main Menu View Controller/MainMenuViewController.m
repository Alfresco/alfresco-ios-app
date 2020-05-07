/*******************************************************************************
 * Copyright (C) 2005-2020 Alfresco Software Limited.
 *
 * This file is part of the Alfresco Mobile iOS App.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 ******************************************************************************/

#import "MainMenuViewController.h"
#import "MainMenuTableViewCell.h"
#import "MainMenuHeaderView.h"
#import "LoginManager.h"
#import "DownloadsViewController.h"
#import "MainMenuConfigurationBuilder.h"
#import "AFPDataManager.h"
#import "AccountManager.h"
#import "AccountsViewController.h"

static NSString * const kMainMenuCellIdentifier = @"MainMenuCellIdentifier";
static NSString * const kMainMenuHeaderViewIdentifier = @"MainMenuHeaderViewIdentifier";
static NSTimeInterval const kHeaderFadeSpeed = 0.3f;

@interface MainMenuViewController () <UITableViewDataSource, UITableViewDelegate, MainMenuGroupDelegate, AccountPickerPresentationDelegate>
@property (nonatomic, strong, readwrite) MainMenuBuilder *builder;
@property (nonatomic, strong, readwrite) NSArray *tableViewData;
@property (nonatomic, strong, readwrite) MainMenuGroup *headerGroup;
@property (nonatomic, strong, readwrite) MainMenuGroup *contentGroup;
@property (nonatomic, strong, readwrite) MainMenuGroup *footerGroup;
@property (nonatomic, weak, readwrite) id<MainMenuViewControllerDelegate> delegate;
@property (nonatomic, strong, readwrite) NSString *previouslySelectedIdentifier;
@property (nonatomic, assign, readwrite) BOOL headersVisible;
// Views
@property (nonatomic, weak) UITableView *tableView;
@end

@implementation MainMenuViewController

@dynamic title;

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.headerGroup = [[MainMenuGroup alloc] initWithDelegate:self];
        self.contentGroup = [[MainMenuGroup alloc] initWithDelegate:self];
        self.footerGroup = [[MainMenuGroup alloc] initWithDelegate:self];
    }
    return self;
}

- (instancetype)initWithTitle:(NSString *)title menuBuilder:(MainMenuBuilder *)builder delegate:(id<MainMenuViewControllerDelegate>)delegate
{
    self = [self init];
    if (self)
    {
        self.title = title;
        self.delegate = delegate;
        self.builder = builder;
    }
    return self;
}

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:view.frame style:UITableViewStyleGrouped];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.alwaysBounceVertical = NO;
    tableView.showsVerticalScrollIndicator = NO;
    tableView.showsHorizontalScrollIndicator = NO;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tableView.rowHeight = UITableViewAutomaticDimension;
    [view addSubview:tableView];
    self.tableView = tableView;
    
    view.backgroundColor = [UIColor whiteColor];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Register table view
    UINib *cellNib = [UINib nibWithNibName:NSStringFromClass([MainMenuTableViewCell class]) bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:kMainMenuCellIdentifier];
    
    // Register header view
    UINib *headerNib = [UINib nibWithNibName:NSStringFromClass([MainMenuHeaderView class]) bundle:nil];
    [self.tableView registerNib:headerNib forHeaderFooterViewReuseIdentifier:kMainMenuHeaderViewIdentifier];
    
    // If there is a background colour set
    if (self.backgroundColour)
    {
        self.tableView.backgroundColor = self.backgroundColour;
    }
    [self setAccessibilityIdentifiers];
}

#pragma mark - Custom Getters and Setters

- (void)setBackgroundColour:(UIColor *)colour
{
    _backgroundColour = colour;
    _tableView.backgroundColor = colour;
}

#pragma mark - Private Methods

- (void)setAccessibilityIdentifiers
{
    self.view.accessibilityIdentifier = kMainMenuVCViewIdentifier;
    self.tableView.accessibilityIdentifier = kMainMenuVCTableViewIdentifier;
}

- (MainMenuGroup *)groupForGroupType:(MainMenuGroupType)groupType
{
    MainMenuGroup *returnGroup = nil;
    
    switch (groupType)
    {
        case MainMenuGroupTypeHeader:
        {
            returnGroup = self.headerGroup;
        }
        break;
            
        case MainMenuGroupTypeContent:
        {
            
            returnGroup = self.contentGroup;
        }
        break;
            
        case MainMenuGroupTypeFooter:
        {
            returnGroup = self.footerGroup;
        }
        break;
    }
    
    return returnGroup;
}

- (NSArray *)allTableViewSectionsItems
{
    NSMutableArray *allSections = [[NSMutableArray alloc] init];
    [allSections addObjectsFromArray:self.headerGroup.sections];
    [allSections addObjectsFromArray:self.contentGroup.sections];
    [allSections addObjectsFromArray:self.footerGroup.sections];
    
    return allSections;
}

- (void)addSection:(MainMenuSection *)section toGroupType:(MainMenuGroupType)groupType
{
    MainMenuGroup *currentGroup = [self groupForGroupType:groupType];
    [currentGroup addSection:section];
}

- (void)addSectionsFromArray:(NSArray *)sections toGroupType:(MainMenuGroupType)groupType
{
    MainMenuGroup *currentGroup = [self groupForGroupType:groupType];
    [currentGroup addSectionsFromArray:sections];
}

- (void)removeSectionAtIndex:(NSUInteger)index fromGroupType:(MainMenuGroupType)groupType
{
    [self savePreviouslySelectedIdentifier];
    
    MainMenuGroup *currentGroup = [self groupForGroupType:groupType];
    [currentGroup removeSectionAtIndex:index];
}

- (MainMenuItem *)itemForIdentifier:(NSString *)identifier
{
    MainMenuItem *foundItem = nil;
    
    for (NSInteger sectionIndex = 0; sectionIndex < self.tableViewData.count; sectionIndex++)
    {
        MainMenuSection *currentSection = self.tableViewData[sectionIndex];
        NSArray *menuItemIdentifiersForCurrentSection = [currentSection.visibleSectionItems valueForKey:@"itemIdentifier"];
        
        if ([menuItemIdentifiersForCurrentSection containsObject:identifier])
        {
            // Get the row index
            NSInteger rowIndex = [menuItemIdentifiersForCurrentSection indexOfObject:identifier];
            // Get the item
            foundItem = currentSection.visibleSectionItems[rowIndex];
            break;
        }
    }
    
    return foundItem;
}

- (NSIndexPath *)indexPathForItemWithIdentifier:(NSString *)identifier
{
    NSIndexPath *foundIndexPath = nil;
    
    for (NSInteger sectionIndex = 0; sectionIndex < self.tableViewData.count; sectionIndex++)
    {
        MainMenuSection *currentSection = self.tableViewData[sectionIndex];
        NSArray *menuItemIdentifiersForCurrentSection = [currentSection.visibleSectionItems valueForKey:@"itemIdentifier"];
        
        if ([menuItemIdentifiersForCurrentSection containsObject:identifier])
        {
            // Get the row index
            NSInteger rowIndex = [menuItemIdentifiersForCurrentSection indexOfObject:identifier];
            // Index Path
            foundIndexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
        }
    }
    
    return foundIndexPath;
}

- (void)visibilityForSectionHeadersHidden:(BOOL)hidden animated:(BOOL)animated
{
    NSUInteger numberOfSections = [self.tableView numberOfSections];
    for (NSUInteger index = 0; index < numberOfSections; index++)
    {
        UITableViewHeaderFooterView *header = [self.tableView headerViewForSection:index];
        CGFloat alphaValue = (hidden) ? 0.0f : 1.0f;
        
        if (animated)
        {
            [UIView animateWithDuration:kHeaderFadeSpeed animations:^{
                header.alpha = alphaValue;
            }];
        }
        else
        {
            header.alpha = alphaValue;
        }
    }
    self.headersVisible = !hidden;
}

- (void)savePreviouslySelectedIdentifier
{
    NSIndexPath *indexPath = self.tableView.indexPathForSelectedRow;
    MainMenuSection *section = self.tableViewData[indexPath.section];
    MainMenuItem *item = section.visibleSectionItems[indexPath.row];
    
    self.previouslySelectedIdentifier = item.itemIdentifier;
}

#pragma mark - Public Methods

- (void)selectMenuItemWithIdentifier:(NSString *)identifier fallbackIdentifier:(NSString *)fallbackIdentifier
{
    // define a search block
    BOOL (^searchTableViewDataForIdentifierAndSelect)(NSString *searchIdentifier) = ^(NSString *searchIdentifier) {
        BOOL foundIdentifier = NO;
        for (NSInteger sectionIndex = 0; sectionIndex < self.tableViewData.count; sectionIndex++)
        {
            MainMenuSection *currentSection = self.tableViewData[sectionIndex];
            NSArray *menuItemIdentifiersForCurrentSection = [currentSection.visibleSectionItems valueForKey:@"itemIdentifier"];
            
            if ([menuItemIdentifiersForCurrentSection containsObject:searchIdentifier])
            {
                // Get the row index
                NSInteger rowIndex = [menuItemIdentifiersForCurrentSection indexOfObject:searchIdentifier];
                // Index Path
                NSIndexPath *foundIndexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
                // Select the row
                [self.tableView.delegate tableView:self.tableView didSelectRowAtIndexPath:foundIndexPath];
                [self.tableView selectRowAtIndexPath:foundIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
                foundIdentifier = YES;
                break;
            }
        }
        return foundIdentifier;
    };
    
    // run the method
    BOOL foundAndSelected = searchTableViewDataForIdentifierAndSelect(identifier);
    
    if (fallbackIdentifier && !foundAndSelected)
    {
        searchTableViewDataForIdentifierAndSelect(fallbackIdentifier);
    }
}

- (void)loadGroupType:(MainMenuGroupType)groupType completionBlock:(void (^)(void))completionBlock
{
    [self sectionsForGroupType:groupType completionBlock:^(NSArray *sections) {
        if (sections)
        {
            [self addSectionsFromArray:sections toGroupType:groupType];
            if (groupType == MainMenuGroupTypeHeader)
            {
                [self setPresentationDeleateOnAccountsViewControllerFromArray:sections];
            }
        }
        
        if (completionBlock != NULL)
        {
            completionBlock();
        }
    }];
}

- (void)reloadGroupType:(MainMenuGroupType)groupType completionBlock:(void (^)(void))completionBlock
{
    [self sectionsForGroupType:groupType completionBlock:^(NSArray *sections) {
        if (sections)
        {
            [self clearGroupType:groupType];
            [self addSectionsFromArray:sections toGroupType:groupType];
            if (groupType == MainMenuGroupTypeHeader)
            {
                [self setPresentationDeleateOnAccountsViewControllerFromArray:sections];
            }
        }
        
        if (completionBlock != NULL)
        {
            completionBlock();
        }
    }];
}


- (void)setPresentationDeleateOnAccountsViewControllerFromArray:(NSArray *)array
{
    for (MainMenuSection *section in array)
    {
        for (MainMenuItem *item in section.allSectionItems)
        {
            id object = item.associatedObject;
            if ([object isKindOfClass:[AccountsViewController class]])
            {
                ((AccountsViewController*)object).presentationPickerDelegate = self;
            }
            if ([object isKindOfClass:[UINavigationController class]])
            {
                for (UIViewController* viewController in ((UINavigationController*)object).viewControllers) {
                    if ([viewController isKindOfClass:[AccountsViewController class]])
                    {
                        ((AccountsViewController*)viewController).presentationPickerDelegate = self;
                    }
                }
            }
        }
    }
}

- (void)sectionsForGroupType:(MainMenuGroupType)groupType completionBlock:(void (^)(NSArray *sections))completionBlock
{
    switch (groupType)
    {
        case MainMenuGroupTypeHeader:
        {
            [self.builder sectionsForHeaderGroupWithCompletionBlock:completionBlock];
        }
        break;
            
        case MainMenuGroupTypeContent:
        {
            [self.builder sectionsForContentGroupWithCompletionBlock:completionBlock];
        }
        break;
            
        case MainMenuGroupTypeFooter:
        {
            [self.builder sectionsForFooterGroupWithCompletionBlock:completionBlock];
        }
        break;
    }
}

- (void)updateMainMenuItemWithIdentifier:(NSString *)identifier withImage:(UIImage *)updateImage
{
    MainMenuItem *foundItem = [self itemForIdentifier:identifier];
    foundItem.itemImage = updateImage;
    NSIndexPath *itemIndexPath = [self indexPathForItemWithIdentifier:identifier];
    if (itemIndexPath)
    {
        [self.tableView reloadRowsAtIndexPaths:@[itemIndexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)updateMainMenuItemWithIdentifier:(NSString *)identifier withAvatarImage:(UIImage *)avatarImage
{
    MainMenuItem *foundItem = [self itemForIdentifier:identifier];
    foundItem.itemImage = avatarImage;
    foundItem.imageMask = MainMenuImageMaskRounded;
    NSIndexPath *itemIndexPath = [self indexPathForItemWithIdentifier:identifier];
    if (itemIndexPath)
    {
        [self.tableView reloadRowsAtIndexPaths:@[itemIndexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)updateMainMenuItemWithIdentifier:(NSString *)identifier withText:(NSString *)updateText
{
    MainMenuItem *foundItem = [self itemForIdentifier:identifier];
    foundItem.itemTitle = updateText;
    NSIndexPath *itemIndexPath = [self indexPathForItemWithIdentifier:identifier];
    if (itemIndexPath)
    {
        [self.tableView reloadRowsAtIndexPaths:@[itemIndexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)updateMainMenuItemWithIdentifier:(NSString *)identifier withDescription:(NSString *)updateDescription
{
    MainMenuItem *menuItem = [self itemForIdentifier:identifier];
    menuItem.itemDescription = updateDescription;
    NSIndexPath *itemIndexPath = [self indexPathForItemWithIdentifier:identifier];
    if (itemIndexPath)
    {
        [self.tableView reloadRowsAtIndexPaths:@[itemIndexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)clearGroupType:(MainMenuGroupType)groupType
{
    [self savePreviouslySelectedIdentifier];

    MainMenuGroup *currentGroup = [self groupForGroupType:groupType];
    [currentGroup clearGroup];
}

- (void) cleanSelection
{
    NSIndexPath *currentlySelected = self.tableView.indexPathForSelectedRow;
    [self.tableView deselectRowAtIndexPath:currentlySelected animated:NO];
    [self tableView:self.tableView didDeselectRowAtIndexPath:currentlySelected];
}

#pragma mark - UITableViewDataSourceDelegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.tableViewData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    MainMenuSection *currentSection = self.tableViewData[section];
    return currentSection.visibleSectionItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MainMenuTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kMainMenuCellIdentifier];
    MainMenuSection *sectionItem = self.tableViewData[indexPath.section];
    MainMenuItem *item = sectionItem.visibleSectionItems[indexPath.row];
    
    // Setup the cell
    cell.backgroundColor = [UIColor clearColor];
    if (self.selectionColor)
    {
        cell.selectedBackgroundView.backgroundColor = self.selectionColor;
    }
    
    // Configure the cell
    cell.itemImageView.image = item.itemImage;
    cell.itemTextLabel.text = item.itemTitle.uppercaseString;
    cell.itemTextLabel.textColor = [UIColor whiteColor];
    cell.itemDescriptionLabel.text = item.itemDescription.uppercaseString;
    cell.itemDescriptionLabel.textColor = [UIColor whiteColor];
    
    if (item.imageMask == MainMenuImageMaskRounded)
    {
        cell.itemImageView.layer.cornerRadius = cell.itemImageView.frame.size.width / 2;
    }
    else
    {
        cell.itemImageView.layer.cornerRadius = 0;
    }
    
    if(item.accessibilityIdentifier)
    {
        cell.accessibilityIdentifier = item.accessibilityIdentifier;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MainMenuTableViewCell *cell = (MainMenuTableViewCell *)[self tableView:tableView cellForRowAtIndexPath:indexPath];
    return [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
}

#pragma mark - UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(mainMenuViewController:didDeselectItem:inSectionItem:)])
    {
        MainMenuSection *deselectedSection = self.tableViewData[indexPath.section];
        MainMenuItem *deselectedItem = deselectedSection.visibleSectionItems[indexPath.row];
        
        [self.delegate mainMenuViewController:self didDeselectItem:deselectedItem inSectionItem:deselectedSection];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MainMenuSection *selectedSection = self.tableViewData[indexPath.section];
    MainMenuItem *selectedItem = selectedSection.visibleSectionItems[indexPath.row];
    
    if ([LoginManager sharedManager].sessionExpired)
    {
        NSString *itemIdentifier = selectedItem.itemIdentifier;
        
        BOOL shouldBlockAccess = YES;
        
        if ([itemIdentifier isEqualToString:kAlfrescoMainMenuItemAccountsIdentifier] ||
            [itemIdentifier isEqualToString:kAlfrescoMainMenuItemSyncIdentifier] ||
            [itemIdentifier isEqualToString:kAlfrescoMainMenuItemSettingsIdentifier] ||
            [itemIdentifier isEqualToString:kAlfrescoMainMenuItemHelpIdentifier] ||
            [itemIdentifier isEqualToString:kSyncViewIdentifier] ||
            [itemIdentifier isEqualToString:kLocalViewIdentifier])
        {
            shouldBlockAccess = NO;
        }
        
        if (shouldBlockAccess)
        {
            [[LoginManager sharedManager] showSignInAlertWithSignedInBlock:nil];
            return;
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoEnableMainMenuAutoItemSelection object:nil];
    
    [self.delegate mainMenuViewController:self didSelectItem:selectedItem inSectionItem:selectedSection];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    MainMenuHeaderView *header = nil;
    MainMenuSection *sectionItem = self.tableViewData[section];
    
    if (sectionItem.sectionTitle)
    {
        header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:kMainMenuHeaderViewIdentifier];
        header.headerTextLabel.text = sectionItem.sectionTitle.uppercaseString;
        header.headerTextLabel.textColor = [UIColor whiteColor];
    }
    
    if (!self.headersVisible)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            header.alpha = 0.0f;
        });
    }
    
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section
{
    MainMenuHeaderView *header = (MainMenuHeaderView *)[self tableView:tableView viewForHeaderInSection:section];
    return [header.contentView systemLayoutSizeFittingSize:UILayoutFittingExpandedSize].height;
}

#pragma mark - MainMenuGroupDelegate Methods

- (void)mainMenuGroupDidChange:(MainMenuGroup *)group
{
    // recalculate the table view data
    self.tableViewData = [self allTableViewSectionsItems];
    // reload the table view
    [self.tableView reloadData];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self visibilityForSectionHeadersHidden:YES animated:YES];
    });
    
    if([self.builder isKindOfClass:[MainMenuConfigurationBuilder class]])
    {
        NSMutableArray *visibleMenuItems = [NSMutableArray new];
        for (MainMenuSection *section in self.tableViewData)
        {
            [visibleMenuItems addObjectsFromArray:section.visibleSectionItems];
        }
        
        MainMenuConfigurationBuilder *menuConfigBuilder = (MainMenuConfigurationBuilder *)self.builder;
        [menuConfigBuilder viewConfigCollectionForMenuItemCollection:visibleMenuItems completionBlock:^(NSArray *configs, NSError *error) {
            if(configs)
            {
                [[AFPDataManager sharedManager] updateMenuItemsWithVisibleCollectionOfViewConfigs:configs forAccount:[AccountManager sharedManager].selectedAccount];
            }
        }];
    }
    
    // Select the previous selected item identifier. If not found, select the first item.
    NSIndexPath *indexPath = [self indexPathForItemWithIdentifier:self.previouslySelectedIdentifier];
    if (indexPath == nil)
    {
        indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    }
    
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
}

#pragma mark - AccountPickerPresentation Delegate

- (UIViewController *)accountPickerPresentationViewController
{
    return self;
}


@end
