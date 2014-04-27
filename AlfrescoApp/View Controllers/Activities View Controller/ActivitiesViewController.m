//
//  ActivitiesViewController.m
//  AlfrescoApp
//
//  Created by Mike Hatfield on 24/04/2014
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "ActivitiesViewController.h"
#import "ActivityWrapper.h"
#import "ActivityTableViewCell.h"
#import "AttributedLabelCell.h"
#import "DocumentPreviewViewController.h"
#import "FolderPreviewViewController.h"
#import "MetaDataViewController.h"
#import "UniversalDevice.h"
#import "Utility.h"
#import "LoginManager.h"
#import "AccountManager.h"

static NSString * const kActivityTableSectionToday = @"activities.section.today";
static NSString * const kActivityTableSectionYesterday = @"activities.section.yesterday";
static NSString * const kActivityTableSectionOlder = @"activities.section.older";

static NSString * const kActivityCellIdentifier = @"ActivityCell";

@interface ActivitiesViewController ()

@property (nonatomic, strong) AlfrescoActivityStreamService *activityService;
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentFolderService;
@property (nonatomic, strong) AlfrescoPersonService *personService;
@property (nonatomic, strong) ActivitiesEmptyTableViewDelegate *emptyTableViewDelegate;
@property (nonatomic, strong) ActivityTableViewCell *prototypeCell;
@property (nonatomic, strong) NSMutableArray *tableSectionHeaders;

@end

/**
 * ActivitiesEmptyTableViewDelegate
 */
@implementation ActivitiesEmptyTableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[AttributedLabelCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ActivitiesEmptyCell"];
    cell.textLabel.font = [UIFont systemFontOfSize:24.0];
    cell.textLabel.insetTop = -(tableView.frame.size.height / 3.0);
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.text = NSLocalizedStringFromTable(@"activity.no-activities", @"Activities", @"No Activities");
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    cell.textLabel.textColor = [UIColor grayColor];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return tableView.frame.size.height;
}

@end

/**
 * ActivitiesViewController
 */
@implementation ActivitiesViewController

- (id)initWithSession:(id<AlfrescoSession>)session
{
    self = [super initWithNibName:NSStringFromClass(self.class) andSession:session];
    
    if (self)
    {
        [self createAlfrescoServicesWithSession:session];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"activities.title", @"Title");
    self.emptyTableViewDelegate = [ActivitiesEmptyTableViewDelegate new];
    
    UINib *cellNib = [UINib nibWithNibName:@"ActivityTableViewCell" bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:kActivityCellIdentifier];

    self.tableView.dataSource = self.emptyTableViewDelegate;
    self.tableView.delegate = self.emptyTableViewDelegate;
    self.tableView.allowsSelection = NO;

    if (self.session)
    {
        [self loadActivities];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Reselect the node in the detail view
    [self selectIndexPathForAlfrescoNodeInDetailView];
}

#pragma mark - Property getters & setters

- (ActivityTableViewCell *)prototypeCell
{
    if (!_prototypeCell)
    {
        _prototypeCell = [self.tableView dequeueReusableCellWithIdentifier:kActivityCellIdentifier];
    }
    
    return _prototypeCell;
}


#pragma mark - UITableView Data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.tableViewData count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return NSLocalizedString(self.tableSectionHeaders[section], @"Section header");
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.tableViewData[section] count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self configureCell:self.prototypeCell forIndexPath:indexPath isForOffscreenUse:YES];
    [self.prototypeCell layoutIfNeeded];
    CGSize size = [self.prototypeCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return size.height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ActivityTableViewCell *activityCell = [self.tableView dequeueReusableCellWithIdentifier:kActivityCellIdentifier];
    [self configureCell:activityCell forIndexPath:indexPath isForOffscreenUse:NO];
    return activityCell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // The last row index of the table data
    NSUInteger lastRowIndex = [[self.tableViewData lastObject] count] - 1;
    
    // If the last cell is about to be drawn, check if there are more activities
    if (indexPath.row == lastRowIndex)
    {
        int totalTableViewItemsCount = 0;
        for (id section in self.tableViewData)
        {
            totalTableViewItemsCount += [section count];
        }
        
        AlfrescoListingContext *moreListingContext = [[AlfrescoListingContext alloc] initWithMaxItems:kMaxItemsPerListingRetrieve skipCount:totalTableViewItemsCount];
        if (self.moreItemsAvailable)
        {
            // Show more items are loading ...
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            [spinner startAnimating];
            self.tableView.tableFooterView = spinner;
            
            [self.activityService retrieveActivityStreamWithListingContext:moreListingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
                NSMutableArray *activityData = [self constructTableGroups:pagingResult];
                // This method needs pagingResult for the hasMoreItems flag, but will use activityData in preference to pagingResult.objects
                [self addMoreToTableViewWithPagingResult:pagingResult data:activityData error:error];
                self.tableView.tableFooterView = nil;
                
                [self selectIndexPathForAlfrescoNodeInDetailView];
            }];
        }
    }
}

#pragma mark - UITableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ActivityWrapper *activityWrapper = self.tableViewData[indexPath.section][indexPath.row];
    [self displayNode:activityWrapper];
}

#pragma mark - Private Functions

- (void)createAlfrescoServicesWithSession:(id<AlfrescoSession>)session
{
    self.activityService = [[AlfrescoActivityStreamService alloc] initWithSession:session];
    self.documentFolderService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
    self.personService = [[AlfrescoPersonService alloc] initWithSession:session];
}

- (void)loadActivities
{
    [self showHUD];
    [self.activityService retrieveActivityStreamWithListingContext:self.defaultListingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
        if (error || [pagingResult.objects count] == 0)
        {
            self.tableView.dataSource = self.emptyTableViewDelegate;
            self.tableView.delegate = self.emptyTableViewDelegate;
            self.tableView.allowsSelection = NO;
            [self.tableView reloadData];
            
            if (error)
            {
                [Notifier notifyWithAlfrescoError:error];
            }
        }
        else
        {
            self.tableView.dataSource = self;
            self.tableView.delegate = self;
            self.tableView.allowsSelection = YES;
            [self reloadTableViewWithPagingResult:pagingResult data:[self constructTableGroups:pagingResult] error:nil];

            // Introduce delay for tableview to settle before cell is selected
            [self performSelector:@selector(selectIndexPathForAlfrescoNodeInDetailView) withObject:nil afterDelay:0.2];
        }
        [self hidePullToRefreshView];
        [self hideHUD];
        
    }];
}

- (NSMutableArray *)constructTableGroups:(AlfrescoPagingResult *)pagingResult
{
    NSMutableArray *tableSections = self.tableViewData ? self.tableViewData : [NSMutableArray new];
    self.tableSectionHeaders = self.tableSectionHeaders ? self.tableSectionHeaders : [NSMutableArray new];

    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *todayComponents = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:[NSDate date]];
    NSDate *today = [calendar dateFromComponents:todayComponents];

    for (AlfrescoActivityEntry *activity in pagingResult.objects)
    {
        ActivityWrapper *activityWrapper = [[ActivityWrapper alloc] initWithActivityEntry:activity];
        NSString *sectionHeader = [self groupHeaderForActivity:activity relativeToDate:today];
        
        if (![self.tableSectionHeaders containsObject:sectionHeader])
        {
            [self.tableSectionHeaders addObject:sectionHeader];
            [tableSections addObject:[NSMutableArray arrayWithObject:activityWrapper]];
        }
        else
        {
            NSUInteger index = [self.tableSectionHeaders indexOfObject:sectionHeader];
            [tableSections[index] addObject:activityWrapper];
        }
    }
    
    return tableSections;
}

- (NSString *)groupHeaderForActivity:(AlfrescoActivityEntry *)activityEntry relativeToDate:(NSDate *)date
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *activityComponents = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:activityEntry.createdAt];
    NSDate *activityDate = [calendar dateFromComponents:activityComponents];
    NSTimeInterval interval = [date timeIntervalSinceDate:activityDate];
    
    if (interval == 0)
    {
        return kActivityTableSectionToday;
    }
    else if (interval == 60*60*24)
    {
        return kActivityTableSectionYesterday;
    }
    return kActivityTableSectionOlder;
}

- (void)selectIndexPathForAlfrescoNodeInDetailView
{
    NSString *detailViewItemIdentifier = [UniversalDevice detailViewItemIdentifier];
    
    if (detailViewItemIdentifier && self.tableSectionHeaders.count > 0)
    {
        for (NSArray *sections in self.tableViewData)
        {
            for (ActivityWrapper *activityWrapper in sections)
            {
                if ([activityWrapper.nodeIdentifier isEqualToString:detailViewItemIdentifier])
                {
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[sections indexOfObject:activityWrapper] inSection:[self.tableViewData indexOfObject:sections]];
                    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
                    return;
                }
            }
        }
    }
}

- (void)configureCell:(ActivityTableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath isForOffscreenUse:(BOOL)offscreenUse
{
    // Offscreen use flag indicates this configuration is for a prototype cell
    ActivityWrapper *activityWrapper = self.tableViewData[indexPath.section][indexPath.row];
    cell.detailsLabel.attributedText = activityWrapper.attributedDetailString;
    cell.dateLabel.text = activityWrapper.dateString;
    
    if (activityWrapper.activityImage)
    {
        cell.activityImageIsAvatar = NO;
        cell.activityImage.image = activityWrapper.activityImage;
    }
    else
    {
        cell.activityImageIsAvatar = YES;
        cell.activityImage.image = [UIImage imageNamed:@"avatar.png"];

        if (!offscreenUse && activityWrapper.avatarUserName)
        {
            [self.personService retrievePersonWithIdentifier:activityWrapper.avatarUserName completionBlock:^(AlfrescoPerson *person, NSError *error) {
                [self.personService retrieveAvatarForPerson:person completionBlock:^(AlfrescoContentFile *contentFile, NSError *error) {
                    if (!error)
                    {
                        AlfrescoFileManager *fileManager = [AlfrescoFileManager sharedManager];
                        activityWrapper.activityImage = [UIImage imageWithData:[fileManager dataWithContentsOfURL:contentFile.fileUrl]];
                        
                        ActivityTableViewCell *avatarCell = (ActivityTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                        if (avatarCell)
                        {
                            avatarCell.activityImage.image = activityWrapper.activityImage;
                        }
                    }
                }];
            }];
        }
    }
}

- (void)displayNode:(ActivityWrapper *)activityWrapper
{
    AlfrescoNode *node;
    if (node)
    {
        [self.documentFolderService retrievePermissionsOfNode:node completionBlock:^(AlfrescoPermissions *permissions, NSError *error) {
            if (!error)
            {
                if (node.isDocument)
                {
                    DocumentPreviewViewController *previewController = [[DocumentPreviewViewController alloc] initWithAlfrescoDocument:(AlfrescoDocument *)node
                                                                                                                           permissions:permissions
                                                                                                                       contentFilePath:nil
                                                                                                                      documentLocation:InAppDocumentLocationFilesAndFolders
                                                                                                                               session:self.session];
                    [UniversalDevice pushToDisplayViewController:previewController usingNavigationController:self.navigationController animated:YES];
                }
                else
                {
                    FolderPreviewViewController *folderPreviewController = [[FolderPreviewViewController alloc] initWithAlfrescoFolder:(AlfrescoFolder *)node
                                                                                                                           permissions:permissions
                                                                                                                               session:self.session];
                    [UniversalDevice pushToDisplayViewController:folderPreviewController usingNavigationController:self.navigationController animated:YES];
                }
            }
            else
            {
                // display an error
                displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.content.failedtodownload", @"Failed to download the file"), [ErrorDescriptions descriptionForError:error]]);
                [Notifier notifyWithAlfrescoError:error];
            }
        }];
    }
}

#pragma mark - Session received notification handler

- (void)sessionReceived:(NSNotification *)notification
{
    id<AlfrescoSession> session = notification.object;
    self.session = session;
    
    [self createAlfrescoServicesWithSession:session];
    
    if ([self shouldRefresh])
    {
        [self loadActivities];
    }
    else if (self == [self.navigationController.viewControllers lastObject])
    {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

#pragma mark - UIRefreshControl Functions

- (void)refreshTableView:(UIRefreshControl *)refreshControl
{
    [self showLoadingTextInRefreshControl:refreshControl];
    if (self.session)
    {
        [self loadActivities];
    }
    else
    {
        [self hidePullToRefreshView];
        UserAccount *selectedAccount = [AccountManager sharedManager].selectedAccount;
        [[LoginManager sharedManager] attemptLoginToAccount:selectedAccount networkId:selectedAccount.selectedNetworkId completionBlock:nil];
    }
}

@end
