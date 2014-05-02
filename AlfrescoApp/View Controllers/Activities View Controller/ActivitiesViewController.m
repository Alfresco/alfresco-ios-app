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
#import "AvatarManager.h"
#import "ThumbnailDownloader.h"


static NSString * const kActivityTableSectionToday = @"activities.section.today";
static NSString * const kActivityTableSectionYesterday = @"activities.section.yesterday";
static NSString * const kActivityTableSectionOlder = @"activities.section.older";

static NSString * const kActivityCellIdentifier = @"ActivityCell";

@interface ActivitiesViewController ()

@property (nonatomic, strong) AlfrescoActivityStreamService *activityService;
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentFolderService;
@property (nonatomic, strong) AlfrescoPersonService *personService;
@property (nonatomic, strong) ActivityTableViewCell *prototypeCell;
@property (nonatomic, strong) NSMutableArray *tableSectionHeaders;

@end

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
    self.tableView.emptyMessage = NSLocalizedString(@"activities.empty", @"No Activities");
    
    UINib *cellNib = [UINib nibWithNibName:@"ActivityTableViewCell" bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:kActivityCellIdentifier];

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
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.accessoryType == UITableViewCellAccessoryDisclosureIndicator)
    {
        ActivityWrapper *activityWrapper = self.tableViewData[indexPath.section][indexPath.row];
        if (activityWrapper.nodeIdentifier)
        {
            if (activityWrapper.node)
            {
                [self displayNodeForActivity:activityWrapper];
            }
            else
            {
                // Need to retrieve the node first
                [self retrieveNodeForActivity:activityWrapper completionBlock:^(BOOL success, NSError *error) {
                    if (!success)
                    {
                        // Display an error
                        displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.content.failedtodownload", @"Failed to download the file"), [ErrorDescriptions descriptionForError:error]]);
                        [Notifier notifyWithAlfrescoError:error];
                    }
                    else
                    {
                        [self displayNodeForActivity:activityWrapper];
                    }
                }];
            }
        }
    }
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
    self.tableViewData = nil;
    self.tableSectionHeaders = nil;

    [self showHUD];
    [self.activityService retrieveActivityStreamWithListingContext:self.defaultListingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
        if (error || [pagingResult.objects count] == 0)
        {
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

/**
 * Note: This method currently assumes activities arrive in reverse date order only.
 */
- (NSMutableArray *)constructTableGroups:(AlfrescoPagingResult *)pagingResult
{
    NSMutableArray *tableSections = self.tableViewData ?: [NSMutableArray new];
    self.tableSectionHeaders = self.tableSectionHeaders ?: [NSMutableArray new];

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
    ActivityWrapper *activityWrapper = self.tableViewData[indexPath.section][indexPath.row];
    cell.detailsLabel.attributedText = activityWrapper.attributedDetailString;
    cell.dateLabel.text = activityWrapper.dateString;
    
    /**
     * Offscreen use flag indicates this configuration is for a prototype cell,
     * so there's no need to perform any processing that doesn't affect cell height.
     */
    if (!offscreenUse)
    {
        if (activityWrapper.nodeIdentifier && !activityWrapper.isDeleteActivity)
        {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        }
        else
        {
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }

        BOOL isActivityDocumentOrFolder = activityWrapper.isDocument || activityWrapper.isFolder;
        cell.activityImageIsAvatar = !isActivityDocumentOrFolder;
        
        if (activityWrapper.activityImage)
        {
            // We already have an image for this activity
            cell.activityImage.image = activityWrapper.activityImage;
        }
        else
        {
            if (isActivityDocumentOrFolder)
            {
                if (activityWrapper.isDocument)
                {
                    // TODO - MOBILE-2526: It should be possible to request the latest cached thumbnail given an objectId
                    activityWrapper.activityImage = smallImageForType([activityWrapper.nodeName pathExtension]);
                    
//                    AlfrescoDocument *documentNode = (AlfrescoDocument *)currentNode;
//                    
//                    UIImage *cachedThumbnail = [[ThumbnailDownloader sharedManager] thumbnailForDocument:documentNode renditionType:kRenditionImageDocLib];
//                    if (cachedThumbnail)
//                    {
//                        activityWrapper.activityImage = cachedThumbnail;
//                        cell.activityImage.image = activityWrapper.activityImage;
//                    }
//                    else
//                    {
//                        activityWrapper.activityImage = smallImageForType([documentNode.name pathExtension]);
//                        cell.activityImage.image = activityWrapper.activityImage;
//                        
//                        [[ThumbnailDownloader sharedManager] retrieveImageForDocument:documentNode renditionType:kRenditionImageDocLib session:self.session completionBlock:^(UIImage *image, NSError *error) {
//                            if (image)
//                            {
//                                ActivityTableViewCell *thumbnailCell = (ActivityTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
//                                if (thumbnailCell)
//                                {
//                                    activityWrapper.activityImage = image;
//                                    thumbnailCell.activityImage.image = image;
//                                }
//                            }
//                        }];
//                    }
                }
                else
                {
                    activityWrapper.activityImage = [UIImage imageNamed:@"folder.png"];
                }
            }
            else if (activityWrapper.avatarUserName)
            {
                UIImage *cachedImage = [[AvatarManager sharedManager] avatarForIdentifier:activityWrapper.avatarUserName];
                if (cachedImage)
                {
                    activityWrapper.activityImage = cachedImage;
                }
                else
                {
                    activityWrapper.activityImage = [UIImage imageNamed:@"avatar.png"];

                    [[AvatarManager sharedManager] retrieveAvatarForPersonIdentifier:activityWrapper.avatarUserName session:self.session completionBlock:^(UIImage *avatarImage, NSError *avatarError) {
                        if (avatarImage)
                        {
                            ActivityTableViewCell *avatarCell = (ActivityTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                            if (avatarCell)
                            {
                                activityWrapper.activityImage = avatarImage;
                                avatarCell.activityImage.image = activityWrapper.activityImage;
                            }
                        }
                    }];
                }
            }

            // We'll always have *something* by the time the code gets here
            cell.activityImage.image = activityWrapper.activityImage;
        }
    }
}

- (void)displayNodeForActivity:(ActivityWrapper *)activityWrapper
{
    AlfrescoNode *node = activityWrapper.node;
    AlfrescoPermissions *nodePermissions = activityWrapper.nodePermissions;

    if (node.isDocument)
    {
        DocumentPreviewViewController *previewController = [[DocumentPreviewViewController alloc] initWithAlfrescoDocument:(AlfrescoDocument *)node
                                                                                                               permissions:nodePermissions
                                                                                                           contentFilePath:nil
                                                                                                          documentLocation:InAppDocumentLocationFilesAndFolders
                                                                                                                   session:self.session];
        [UniversalDevice pushToDisplayViewController:previewController usingNavigationController:self.navigationController animated:YES];
    }
    else if (node.isFolder)
    {
        FolderPreviewViewController *folderPreviewController = [[FolderPreviewViewController alloc] initWithAlfrescoFolder:(AlfrescoFolder *)node
                                                                                                               permissions:nodePermissions
                                                                                                                   session:self.session];
        [UniversalDevice pushToDisplayViewController:folderPreviewController usingNavigationController:self.navigationController animated:YES];
    }
}

- (void)retrieveNodeForActivity:(ActivityWrapper *)activityWrapper completionBlock:(void(^)(BOOL success, NSError *error))completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];

    if (!activityWrapper.nodeIdentifier)
    {
        return completionBlock(NO, nil);
    }
    
    [self.documentFolderService retrieveNodeWithIdentifier:activityWrapper.nodeIdentifier completionBlock:^(AlfrescoNode *node, NSError *nodeError) {
        if (nodeError)
        {
            return completionBlock(NO, nodeError);
        }
        
        [self.documentFolderService retrievePermissionsOfNode:node completionBlock:^(AlfrescoPermissions *permissions, NSError *permissionsError) {
            if (permissionsError)
            {
                return completionBlock(NO, permissionsError);
            }
            
            activityWrapper.node = node;
            activityWrapper.nodePermissions = permissions;
            
            completionBlock(YES, nil);
        }];
    }];
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
