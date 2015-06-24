/*******************************************************************************
 * Copyright (C) 2005-2015 Alfresco Software Limited.
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

static NSString * const kMainMenuCellIdentifier = @"MainMenuCellIdentifier";

@interface MainMenuViewController () <UITableViewDataSource, UITableViewDelegate, MainMenuGroupDelegate>
@property (nonatomic, strong, readwrite) MainMenuBuilder *builder;
@property (nonatomic, strong, readwrite) NSArray *tableViewData;
@property (nonatomic, strong, readwrite) MainMenuGroup *headerGroup;
@property (nonatomic, strong, readwrite) MainMenuGroup *contentGroup;
@property (nonatomic, strong, readwrite) MainMenuGroup *footerGroup;
@property (nonatomic, weak, readwrite) id<MainMenuViewControllerDelegate> delegate;
@property (nonatomic, strong, readwrite) NSIndexPath *previouslySelectedIndexPath;
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
    tableView.bounces = NO;
    tableView.showsVerticalScrollIndicator = NO;
    tableView.showsHorizontalScrollIndicator = NO;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
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
    
    // If there is a background colour set
    if (self.backgroundColour)
    {
        self.tableView.backgroundColor = self.backgroundColour;
    }
}

#pragma mark - Custom Getters and Setters

- (void)setBackgroundColour:(UIColor *)colour
{
    _backgroundColour = colour;
    _tableView.backgroundColor = colour;
}

#pragma mark - Private Methods

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

#pragma mark - Public Methods

- (void)selectMenuItemWithIdentifier:(NSString *)identifier
{
    for (NSInteger sectionIndex = 0; sectionIndex < self.tableViewData.count; sectionIndex++)
    {
        MainMenuSection *currentSection = self.tableViewData[sectionIndex];
        NSArray *menuItemIdentifiersForCurrentSection = [currentSection.visibleSectionItems valueForKey:@"itemIdentifier"];
        
        if ([menuItemIdentifiersForCurrentSection containsObject:identifier])
        {
            // Get the row index
            NSInteger rowIndex = [menuItemIdentifiersForCurrentSection indexOfObject:identifier];
            // Index Path
            NSIndexPath *foundIndexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
            // Select the row
            [self.tableView.delegate tableView:self.tableView didSelectRowAtIndexPath:foundIndexPath];
            [self.tableView selectRowAtIndexPath:foundIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            break;
        }
    }
}

- (void)loadGroupType:(MainMenuGroupType)groupType completionBlock:(void (^)(void))completionBlock
{
    [self sectionsForGroupType:groupType completionBlock:^(NSArray *sections) {
        if (sections)
        {
            [self addSectionsFromArray:sections toGroupType:groupType];
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
        }
        
        if (completionBlock != NULL)
        {
            completionBlock();
        }
    }];
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
    MainMenuItem *foundItem = [self itemForIdentifier:identifier];
    foundItem.itemDescription = updateDescription;
    NSIndexPath *itemIndexPath = [self indexPathForItemWithIdentifier:identifier];
    if (itemIndexPath)
    {
        [self.tableView reloadRowsAtIndexPaths:@[itemIndexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)clearGroupType:(MainMenuGroupType)groupType
{
    MainMenuGroup *currentGroup = [self groupForGroupType:groupType];
    [currentGroup clearGroup];
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
    if (self.selectionColour)
    {
        cell.selectedBackgroundView.backgroundColor = self.selectionColour;
    }
    
    // Configure the cell
    cell.itemImageView.image = item.itemImage;
    cell.itemTextLabel.text = item.itemTitle.uppercaseString;
    cell.itemTextLabel.textColor = [UIColor whiteColor];
    cell.itemDescriptionLabel.text = item.itemDescription.uppercaseString;
    cell.itemDescriptionLabel.textColor = [UIColor whiteColor];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    MainMenuSection *sectionItem = self.tableViewData[section];
    return sectionItem.sectionTitle;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MainMenuTableViewCell *cell = (MainMenuTableViewCell *)[self tableView:tableView cellForRowAtIndexPath:indexPath];
    
    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    
    return height;
}

#pragma mark - UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(mainMenuViewController:didDeselectItem:inSectionItem:)])
    {
        // Only call this when a current selection is being deselected
        NSIndexPath *currentlySelectedIndexPath = [self.tableView indexPathForSelectedRow];
        if (currentlySelectedIndexPath)
        {
            MainMenuSection *deselectedSection = self.tableViewData[indexPath.section];
            MainMenuItem *deselectedItem = deselectedSection.visibleSectionItems[indexPath.row];
            
            [self.delegate mainMenuViewController:self didDeselectItem:deselectedItem inSectionItem:deselectedSection];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MainMenuSection *selectedSection = self.tableViewData[indexPath.section];
    MainMenuItem *selectedItem = selectedSection.visibleSectionItems[indexPath.row];
    
    [self.delegate mainMenuViewController:self didSelectItem:selectedItem inSectionItem:selectedSection];
}

#pragma mark - MainMenuGroupDelegate Methods

- (void)mainMenuGroupDidChange:(MainMenuGroup *)group
{
    // Get the currently selected index path
    NSIndexPath *currentlySelected = self.tableView.indexPathForSelectedRow;
    // recalculate the table view data
    self.tableViewData = [self allTableViewSectionsItems];
    // reload the table view
    [self.tableView reloadData];
    // select the previous index path
    [self.tableView selectRowAtIndexPath:currentlySelected animated:NO scrollPosition:UITableViewScrollPositionNone];
}

@end
