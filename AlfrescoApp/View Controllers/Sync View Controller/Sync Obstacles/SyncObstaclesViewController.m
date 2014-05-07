//
//  SyncObstaclesViewController.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 04/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "SyncObstaclesViewController.h"
#import "SyncManager.h"
#import "Utility.h"

@interface SyncObstaclesViewController ()
@property (nonatomic, retain) NSMutableDictionary *errorDictionary;
@property (nonatomic, retain) NSMutableDictionary *sectionHeaders;

- (NSString *)keyForSection:(NSInteger)section;
- (NSInteger)calculateHeaderHeightForSection:(NSInteger)section;
- (void)handleSyncObstacles;
- (void)reloadTableView;
- (NSInteger)numberOfPopulatedErrorArrays;
@end

@implementation SyncObstaclesViewController

- (id)initWithErrors:(NSMutableDictionary *)errors
{
    self = [super init];
    if (self)
    {
        self.errorDictionary = errors;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    UIBarButtonItem *dismissButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                   target:self
                                                                                   action:@selector(dismissModalView)];
    [self.navigationItem setRightBarButtonItem:dismissButton];
    
    [self.navigationItem setTitle:NSLocalizedString(@"sync-errors.title", @"Sync Error Navigation Bar Title")];
    
    self.sectionHeaders = [NSMutableDictionary dictionaryWithObjects:[NSArray arrayWithObjects:@"sync-errors.unfavorited-on-server-with-local-changes.header", @"sync-errors.deleted-on-server-with-local-changes.header", nil]
                                                             forKeys:[NSArray arrayWithObjects:kDocumentsRemovedFromSyncOnServerWithLocalChanges, kDocumentsDeletedOnServerWithLocalChanges, nil]];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self handleSyncObstacles];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Private Class functions

- (void)dismissModalView
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSString *)keyForSection:(NSInteger)sectionNumber
{
    return [[self.sectionHeaders allKeys] objectAtIndex:sectionNumber];
}

- (NSInteger)calculateHeaderHeightForSection:(NSInteger)section
{
    NSString *key = [self keyForSection:section];
    
    NSUInteger returnHeight = 0;
    
    if ([[self.errorDictionary objectForKey:key] count] != 0)
    {
        NSString *headerText = NSLocalizedString([self.sectionHeaders objectForKey:key], @"TableView Header Section Descriptions");
        CGRect rect = [headerText boundingRectWithSize:CGSizeMake(300, 2000)
                                               options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                            attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:14.0f]}
                                               context:nil];
        returnHeight = rect.size.height;
    }
    
    return returnHeight;
}

- (void)handleSyncObstacles
{
    NSArray *syncObstacles = [[self.errorDictionary objectForKey:kDocumentsDeletedOnServerWithLocalChanges] mutableCopy];
    for (AlfrescoDocument *document in syncObstacles)
    {
        [[SyncManager sharedManager] saveDeletedFileBeforeRemovingFromSync:document];
    }
}

- (void)reloadTableView
{
    NSInteger numberOfPopulatedErrorArrays = [self numberOfPopulatedErrorArrays];
    
    if (numberOfPopulatedErrorArrays == 0)
    {
        [self dismissModalView];
    }
    
    [self.tableView reloadData];
}

- (NSInteger)numberOfPopulatedErrorArrays
{
    int numberOfPopulatedErrorArrays = 0;
    for (NSString *key in [self.sectionHeaders allKeys])
    {
        if ([[self.errorDictionary objectForKey:key] count] > 0)
        {
            numberOfPopulatedErrorArrays++;
        }
    }
    return numberOfPopulatedErrorArrays;
}

#pragma mark - UITableViewDataSourceDelegate functions

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.sectionHeaders allKeys] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *key = [self keyForSection:section];
    return [[self.errorDictionary objectForKey:key] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *standardCellIdentifier = @"StandardCellIdentifier";
    static NSString *syncErrorCellIdentifier = @"SyncObstacleCellIdentifier";
    
    NSString *key = [self keyForSection:indexPath.section];
    NSArray *currentErrorArray = [self.errorDictionary objectForKey:key];
    AlfrescoDocument *document = currentErrorArray[indexPath.row];
    UITableViewCell *cell = nil;
    
    if ([key isEqualToString:kDocumentsDeletedOnServerWithLocalChanges])
    {
        UITableViewCell *standardCell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:standardCellIdentifier];
        if (!standardCell)
        {
            standardCell = (UITableViewCell *)[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:standardCellIdentifier];
            standardCell.imageView.contentMode = UIViewContentModeCenter;
        }
        standardCell.selectionStyle = UITableViewCellSelectionStyleNone;
        standardCell.textLabel.font = [UIFont systemFontOfSize:17.0f];
        standardCell.textLabel.text = document.name;
        standardCell.imageView.image = smallImageForType([document.name pathExtension]);
        
        cell = standardCell;
    }
    else
    {
        SyncObstacleTableViewCell *syncErrorCell = (SyncObstacleTableViewCell *)[tableView dequeueReusableCellWithIdentifier:syncErrorCellIdentifier];
        if (!syncErrorCell)
        {
            NSArray *nibItems = [[NSBundle mainBundle] loadNibNamed:@"SyncObstacleTableViewCell" owner:self options:nil];
            syncErrorCell = (SyncObstacleTableViewCell *)[nibItems objectAtIndex:0];
            syncErrorCell.delegate = self;
            [syncErrorCell.syncButton setTitle:NSLocalizedString(@"sync-errors.button.sync", @"Sync Button") forState:UIControlStateNormal];
            [syncErrorCell.syncButton setBackgroundImage:[[UIImage imageNamed:@"blue-button-30.png"] stretchableImageWithLeftCapWidth:5 topCapHeight:5] forState:UIControlStateNormal];
            [syncErrorCell.saveButton setTitle:NSLocalizedString(@"sync-errors.button.save", @"Save Button") forState:UIControlStateNormal];
            [syncErrorCell.saveButton setBackgroundImage:[[UIImage imageNamed:@"blue-button-30.png"] stretchableImageWithLeftCapWidth:5 topCapHeight:5] forState:UIControlStateNormal];
            NSAssert(nibItems, @"Failed to load object from NIB");
        }
        
        syncErrorCell.selectionStyle = UITableViewCellSelectionStyleNone;
        syncErrorCell.fileNameTextLabel.text = document.name;
        syncErrorCell.imageView.image = smallImageForType([document.name pathExtension]);
        
        cell = syncErrorCell;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate Functions

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *key = [self keyForSection:section];
    NSArray *syncErrors = [self.errorDictionary objectForKey:key];
    if (syncErrors.count > 0)
    {
        int horizontalMargin = 10;
        int verticalMargin = 10;
        CGFloat heightRequired = [self calculateHeaderHeightForSection:section];
        
        UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, heightRequired + (verticalMargin * 2))];
        headerView.backgroundColor = [UIColor clearColor];
        headerView.contentMode = UIViewContentModeScaleAspectFit;
        headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(horizontalMargin, -verticalMargin, tableView.frame.size.width - (horizontalMargin * 2), heightRequired)];
        label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.numberOfLines = 0;
        label.font = [UIFont systemFontOfSize:14.0f];
        label.text = NSLocalizedString([self.sectionHeaders objectForKey:key], @"TableView Header Section Descriptions");
        
        [headerView addSubview:label];
        return headerView;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [self calculateHeaderHeightForSection:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.section == 0 && !IS_IPAD) ? 100.0f : 60.0f;
}

#pragma mark - SyncErrorTableViewDelegate Functions

- (NSIndexPath *)indexPathForButtonPressed:(UIButton *)button
{
    UIView *cell = button.superview;
    
    BOOL foundTableView = NO;
    while (!foundTableView)
    {
        if (![cell isKindOfClass:[UITableViewCell class]])
        {
            cell = (UITableViewCell *)cell.superview;
        }
        else
        {
            foundTableView = YES;
        }
    }
    
    NSIndexPath *cellIndexPath = [self.tableView indexPathForCell:(SyncObstacleTableViewCell *)cell];
    return cellIndexPath;
}
- (void)didPressSyncButton:(UIButton *)syncButton
{
    NSIndexPath *cellIndexPath = [self indexPathForButtonPressed:syncButton];
    // key for section
    NSString *key = [self keyForSection:cellIndexPath.section];
    NSArray *currentErrorArray = [self.errorDictionary objectForKey:key];
    AlfrescoDocument *document = currentErrorArray[cellIndexPath.row];
    [[SyncManager sharedManager] syncFileBeforeRemovingFromSync:document syncToServer:YES];
    [self reloadTableView];
}

- (void)didPressSaveToDownloadsButton:(UIButton *)saveButton
{
    NSIndexPath *cellIndexPath = [self indexPathForButtonPressed:saveButton];
    // key for section
    NSString *key = [self keyForSection:cellIndexPath.section];
    NSArray *currentErrorArray = [self.errorDictionary objectForKey:key];
    AlfrescoDocument *document = currentErrorArray[cellIndexPath.row];
    [[SyncManager sharedManager] syncFileBeforeRemovingFromSync:document syncToServer:NO];
    [self reloadTableView];
}

@end
