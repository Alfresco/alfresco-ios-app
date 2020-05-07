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
 
#import "TagPickerViewController.h"

@interface TagPickerViewController ()

@property (nonatomic, strong) AlfrescoTaggingService *tagService;
@property (nonatomic, strong) id<TagPickerViewControllerDelegate>delegate;
@property (nonatomic, strong) NSMutableSet *selectedTags;

@end

@implementation TagPickerViewController

- (id)initWithSelectedTags:(NSArray *)selectedTags session:(id<AlfrescoSession>)session delegate:(id<TagPickerViewControllerDelegate>)delegate;
{
    self = [super initWithSession:session];
    if (self)
    {
        self.tagService = [[AlfrescoTaggingService alloc] initWithSession:session];
        self.delegate = delegate;
        self.selectedTags = [[NSMutableSet alloc] initWithArray:selectedTags];
    }
    return self;
}

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // Create and configure the table view
    ALFTableView *tableView = [[ALFTableView alloc] initWithFrame:view.frame style:UITableViewStyleGrouped];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView = tableView;
    [view addSubview:self.tableView];
    
    view.autoresizesSubviews = YES;
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"tagselection.title", @"Tag Title");
    self.tableView.emptyMessage = NSLocalizedString(@"tagselection.empty", @"No Tags");
    
    UIBarButtonItem *addNewTagButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"tagselection.newTag.buttonTitle", @"Add New Tag")
                                                                        style:UIBarButtonItemStylePlain
                                                                       target:self
                                                                       action:@selector(addNewTagButtonPressed)];
    addNewTagButton.tintColor = [UIColor addTagButtonTintColor];
    self.navigationItem.rightBarButtonItem = addNewTagButton;
    
    self.allowsPullToRefresh = NO;
    [self showHUD];
    
    __weak TagPickerViewController *weakSelf = self;
    
    [self.tagService retrieveAllTagsWithCompletionBlock:^(NSArray *array, NSError *error) {
        if (array)
        {
            weakSelf.tableViewData = [[array valueForKeyPath:@"value"] mutableCopy];
            
            NSSet *selectedTags = [NSSet setWithSet:weakSelf.selectedTags];
            for (NSString *selectedTag in selectedTags)
            {
                [weakSelf addNewTag:selectedTag];
            }
            [weakSelf.tableView reloadData];
        }
        else
        {
            displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.tags.retrieve.failed", @"Failed to retrieve tags"), [ErrorDescriptions descriptionForError:error]]);
        }
        
        [weakSelf hideHUD];
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didCompleteSelectingTags:)])
    {
        NSArray *selectedTagsSorted = [[self.selectedTags allObjects] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        [self.delegate didCompleteSelectingTags:(selectedTagsSorted.count > 0) ? selectedTagsSorted : nil];
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableViewData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    NSString *currentTag = [self.tableViewData objectAtIndex:indexPath.row];
    cell.textLabel.text = currentTag;
    
    if ([self.selectedTags containsObject:currentTag])
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

#pragma mark - UITableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    NSString *selectedTag = [self.tableViewData objectAtIndex:indexPath.row];
    
    if ([self.selectedTags containsObject:selectedTag])
    {
        [self.selectedTags removeObject:selectedTag];
        selectedCell.accessoryType = UITableViewCellAccessoryNone;
    }
    else
    {
        [self.selectedTags addObject:selectedTag];
        selectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Add New Tag

- (void)addNewTagButtonPressed
{
    void (^addNewTagBlock)(NSString *) = ^(NSString *newTag){
        newTag = [[newTag lowercaseString] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if ((newTag == nil) || (newTag.length == 0))
        {
            displayErrorMessageWithTitle(NSLocalizedString(@"tagselection.newTag.error.invalidtag.message", @"Tags must contain text"),
                                         NSLocalizedString(@"tagselection.newTag.error.invalidtag.title", @"Invalid Tag"));
        }
        else
        {
            [self addNewTag:newTag];
            [self.selectedTags addObject:newTag];
        }
    };
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"tagselection.newTag.alertTitle", @"Add New Tag")
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel")
                                                           style:UIAlertActionStyleCancel
                                                         handler:nil];
    [alertController addAction:cancelAction];
    UIAlertAction *addNewTagAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Add", @"Add")
                                                              style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                                                  NSString *newTag = alertController.textFields.firstObject.text;
                                                                  addNewTagBlock(newTag);
                                                              }];
    [alertController addAction:addNewTagAction];
    [alertController addTextFieldWithConfigurationHandler:nil];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)addNewTag:(NSString *)newTag
{
    // Check if new tag value already exists in tableViewData
    NSInteger rowIndexForNewTag = [self.tableViewData indexOfObject:newTag];
    
    // If it's not present, the tag doesn't exist in the Repository
    if (rowIndexForNewTag == NSNotFound)
    {
        NSComparator comparator = ^(NSString *tag1, NSString *tag2)
        {
            return (NSComparisonResult)[tag1 caseInsensitiveCompare:tag2];
        };

        rowIndexForNewTag = [self.tableViewData indexOfObject:newTag inSortedRange:NSMakeRange(0, self.tableViewData.count) options:NSBinarySearchingInsertionIndex usingComparator:comparator];
        
        [self.tableViewData insertObject:newTag atIndex:rowIndexForNewTag];
        [self.tableView reloadData];
    }
    else
    {
        newTag = [self.tableViewData objectAtIndex:rowIndexForNewTag];
    }
    
    [self.selectedTags addObject:newTag];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rowIndexForNewTag inSection:0];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    [UIView animateWithDuration:0.0 delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^void() {
        [[self.tableView cellForRowAtIndexPath:indexPath] setHighlighted:YES animated:YES];
    } completion:^(BOOL finished) {
        [[self.tableView cellForRowAtIndexPath:indexPath] setHighlighted:NO animated:YES];
    }];
}

#pragma mark - Session Received

- (void)sessionReceived:(NSNotification *)notification
{
    id<AlfrescoSession> session = notification.object;
    self.session = session;
    self.tagService = [[AlfrescoTaggingService alloc] initWithSession:self.session];
}

@end
