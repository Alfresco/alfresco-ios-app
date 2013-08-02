//
//  TagPickerViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "TagPickerViewController.h"
#import "AlfrescoTaggingService.h"
#import "Utility.h"
#import "UIAlertView+ALF.h"

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
    UITableView *tableView = [[UITableView alloc] initWithFrame:view.frame style:UITableViewStyleGrouped];
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
    
    UIBarButtonItem *addNewTagButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"tagselection.newTag.buttonTitle", @"Add New Tag")
                                                                        style:UIBarButtonItemStyleBordered
                                                                       target:self
                                                                       action:@selector(addNewTagButtonPressed)];
    addNewTagButton.tintColor = [UIColor colorWithRed:0 green:0.5 blue:0 alpha:1.0];
    self.navigationItem.rightBarButtonItem = addNewTagButton;
    
    [self disablePullToRefresh];
    [self showHUD];
    
    __weak TagPickerViewController *weakSelf = self;
    
    [self.tagService retrieveAllTagsWithCompletionBlock:^(NSArray *array, NSError *error) {
        if (array)
        {
            weakSelf.tableViewData = [[array valueForKeyPath:@"value"] mutableCopy];
            for (NSString *selectedTag in weakSelf.selectedTags)
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
        [self.delegate didCompleteSelectingTags:selectedTagsSorted];
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
    UIAlertView *addNewTagAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"tagselection.newTag.alertTitle", @"Add New Tag")
                                                             message:nil
                                                            delegate:self
                                                   cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel")
                                                   otherButtonTitles:NSLocalizedString(@"Add", @"Add"), nil];
    
    addNewTagAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [addNewTagAlert showWithCompletionBlock:^(NSUInteger buttonIndex, BOOL isCancelButton) {
        if (!isCancelButton)
        {
            NSString *newTag = [[addNewTagAlert textFieldAtIndex:0] text];
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
        }
    }];
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

@end
