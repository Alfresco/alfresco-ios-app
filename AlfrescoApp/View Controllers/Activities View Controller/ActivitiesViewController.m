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
 
#import "ActivitiesViewController.h"
#import "ActivityWrapper.h"
#import "ActivityTableViewCell.h"
#import "AttributedLabelCell.h"
#import "DocumentPreviewViewController.h"
#import "MetaDataViewController.h"
#import "UniversalDevice.h"
#import "LoginManager.h"
#import "AccountManager.h"
#import "AvatarManager.h"
#import "ThumbnailManager.h"
#import "ConnectivityManager.h"
#import "TableviewUnderlinedHeaderView.h"
#import "RealmSyncCore.h"

static NSString * const kActivityTableSectionToday = @"activities.section.today";
static NSString * const kActivityTableSectionYesterday = @"activities.section.yesterday";
static NSString * const kActivityTableSectionOlder = @"activities.section.older";

static NSString * const kActivityCellIdentifier = @"ActivityCell";

typedef NS_ENUM(NSUInteger, ActivitiesViewControllerType)
{
    ActivitiesViewControllerTypeRepository,
    ActivitiesViewControllerTypeSite
};

@interface ActivitiesViewController ()
@property (nonatomic, strong) AlfrescoActivityStreamService *activityService;
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentFolderService;
@property (nonatomic, strong) AlfrescoPersonService *personService;
@property (nonatomic, strong) AlfrescoSiteService *siteService;
@property (nonatomic, strong) ActivityTableViewCell *prototypeCell;
@property (nonatomic, strong) NSMutableArray *tableSectionHeaders;
@property (nonatomic, assign) ActivitiesViewControllerType controllerType;
@property (nonatomic, strong) NSString *siteShortName;
@property (nonatomic, strong) AlfrescoSite *site;
@end

@implementation ActivitiesViewController

- (id)initWithSession:(id<AlfrescoSession>)session
{
    self = [super initWithSession:session];
    if (self)
    {
        [self createAlfrescoServicesWithSession:session];
    }
    return self;
}

- (instancetype)initWithSiteShortName:(NSString *)siteShortName listingContext:(AlfrescoListingContext *)listingContext session:(id<AlfrescoSession>)session
{
    self = [self initWithSession:session];
    if (self)
    {
        if (siteShortName)
        {
            self.controllerType = ActivitiesViewControllerTypeSite;
            self.siteShortName = siteShortName;
        }
        
        if (listingContext)
        {
            self.defaultListingContext = listingContext;
        }
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

    [self loadActivities];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // Reselect the node in the detail view
    [self selectIndexPathForAlfrescoNodeInDetailView];
    
    [[AnalyticsManager sharedManager] trackScreenWithName:kAnalyticsViewMenuActivities];
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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [TableviewUnderlinedHeaderView headerViewHeight];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    TableviewUnderlinedHeaderView *headerView = [[[NSBundle mainBundle] loadNibNamed:@"TableviewUnderlinedHeaderView" owner:self options:nil] lastObject];
    headerView.headerTitleTextLabel.textColor = [UIColor appTintColor];
    headerView.headerTitleTextLabel.text = NSLocalizedString(self.tableSectionHeaders[section], @"Section header");
    return headerView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.tableViewData[section] count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self configureCell:self.prototypeCell forIndexPath:indexPath forOffscreenUse:YES];
    [self.prototypeCell layoutIfNeeded];
    CGSize size = [self.prototypeCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return size.height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ActivityTableViewCell *activityCell = [self.tableView dequeueReusableCellWithIdentifier:kActivityCellIdentifier];
    [self configureCell:activityCell forIndexPath:indexPath forOffscreenUse:NO];
    return activityCell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // The last row index of the table data
    NSUInteger lastRowIndex = [[self.tableViewData lastObject] count] - 1;
    
    // The last section index of the table data
    NSInteger lastSectionIndex = tableView.numberOfSections - 1;
    
    // If the last cell is about to be drawn, check if there are more activities
    if (indexPath.row == lastRowIndex && indexPath.section == lastSectionIndex)
    {
        int totalTableViewItemsCount = 0;
        for (id section in self.tableViewData)
        {
            totalTableViewItemsCount += [section count];
        }
        
        int maxItems = self.defaultListingContext.maxItems;
        int skipCount = self.defaultListingContext.skipCount + totalTableViewItemsCount;
        AlfrescoListingContext *moreListingContext = [[AlfrescoListingContext alloc] initWithMaxItems:maxItems skipCount:skipCount];
        
        if (self.moreItemsAvailable)
        {
            // Show more items are loading ...
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            [spinner startAnimating];
            self.tableView.tableFooterView = spinner;
            
            void (^handleMoreActivities)(AlfrescoPagingResult *, NSError *) = ^(AlfrescoPagingResult *pagingResult, NSError *pagingError) {
                NSMutableArray *activityData = [self constructTableGroups:pagingResult];
                // This method needs pagingResult for the hasMoreItems flag, but will use activityData in preference to pagingResult.objects
                [self addMoreToTableViewWithPagingResult:pagingResult data:activityData error:pagingError];
                self.tableView.tableFooterView = nil;
                
                [self selectIndexPathForAlfrescoNodeInDetailView];
            };
            
            switch (self.controllerType)
            {
                case ActivitiesViewControllerTypeRepository:
                {
                    [self.activityService retrieveActivityStreamWithListingContext:moreListingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
                        handleMoreActivities(pagingResult, error);
                    }];
                }
                break;
                    
                case ActivitiesViewControllerTypeSite:
                {
                    [self.activityService retrieveActivityStreamForSite:self.site listingContext:moreListingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
                        handleMoreActivities(pagingResult, error);
                    }];
                }
                break;
            }
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
    self.siteService = [[AlfrescoSiteService alloc] initWithSession:session];
}

- (void)loadActivities
{
    self.tableViewData = nil;
    self.tableSectionHeaders = nil;

    if ([ConnectivityManager sharedManager].hasInternetConnection && self.session)
    {
        // Define an activites handling block
        void (^handleActivitesBlock)(AlfrescoPagingResult *pagingResult, NSError *pagingError) = ^(AlfrescoPagingResult *pagingResult, NSError *pagingError) {
            if (pagingError || [pagingResult.objects count] == 0)
            {
                [self.tableView reloadData];
                
                if (pagingError)
                {
                    [Notifier notifyWithAlfrescoError:pagingError];
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
        };
        
        // Load activities depending on the controller type
        switch (self.controllerType)
        {
            case ActivitiesViewControllerTypeRepository:
            {
                [self showHUD];
                [self.activityService retrieveActivityStreamWithListingContext:self.defaultListingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
                    handleActivitesBlock(pagingResult, error);
                }];
            }
            break;
                
            case ActivitiesViewControllerTypeSite:
            {
                [self showHUD];
                [self.siteService retrieveSiteWithShortName:self.siteShortName completionBlock:^(AlfrescoSite *site, NSError *siteError) {
                    if (siteError)
                    {
                        [Notifier notifyWithAlfrescoError:siteError];
                        [self hideHUD];
                    }
                    else
                    {
                        self.site = site;
                        [self.activityService retrieveActivityStreamForSite:site listingContext:self.defaultListingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *activitiesError) {
                            handleActivitesBlock(pagingResult, activitiesError);
                        }];
                    }
                }];
            }
            break;
        }
    }
}

/**
 * Note: This method currently assumes activities arrive in reverse date order only.
 */
- (NSMutableArray *)constructTableGroups:(AlfrescoPagingResult *)pagingResult
{
    NSMutableArray *tableSections = self.tableViewData ?: [NSMutableArray new];
    self.tableSectionHeaders = self.tableSectionHeaders ?: [NSMutableArray new];

    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *todayComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:[NSDate date]];
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
    NSDateComponents *activityComponents = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay) fromDate:activityEntry.createdAt];
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

- (void)configureCell:(ActivityTableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath forOffscreenUse:(BOOL)offscreenUse
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
            [cell.activityImage setImage:activityWrapper.activityImage withFade:NO];
        }
        else
        {
            if (isActivityDocumentOrFolder)
            {
                if (activityWrapper.isDocument)
                {
                    UIImage *cachedThumbnail = [[ThumbnailManager sharedManager] thumbnailForDocumentIdentifier:activityWrapper.nodeIdentifier renditionType:kRenditionImageDocLib];
                    if (cachedThumbnail)
                    {
                        activityWrapper.activityImage = cachedThumbnail;
                        [cell.activityImage setImage:activityWrapper.activityImage withFade:NO];
                    }
                    else
                    {
                        activityWrapper.activityImage = smallImageForType([activityWrapper.nodeName pathExtension]);
                        [cell.activityImage setImage:activityWrapper.activityImage withFade:NO];
                        
                        [self retrieveNodeForActivity:activityWrapper completionBlock:^(BOOL success, NSError *error) {
                            if (success)
                            {
                                [[ThumbnailManager sharedManager] retrieveImageForDocument:(AlfrescoDocument *)activityWrapper.node renditionType:kRenditionImageDocLib session:self.session completionBlock:^(UIImage *image, NSError *error) {
                                    if (image)
                                    {
                                        ActivityTableViewCell *thumbnailCell = (ActivityTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                                        if (thumbnailCell)
                                        {
                                            activityWrapper.activityImage = image;
                                            [thumbnailCell.activityImage setImage:image withFade:YES];
                                        }
                                    }
                                }];
                            }
                        }];
                    }
                }
                else
                {
                    activityWrapper.activityImage = smallImageForType(@"folder");
                }
            }
            else if (activityWrapper.avatarUserName)
            {
                AvatarConfiguration *configuration = [AvatarConfiguration defaultConfigurationWithIdentifier:activityWrapper.avatarUserName session:self.session];
                [[AvatarManager sharedManager] retrieveAvatarWithConfiguration:configuration completionBlock:^(UIImage *avatarImage, NSError *avatarError) {
                        ActivityTableViewCell *avatarCell = (ActivityTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                        if (avatarCell)
                        {
                            activityWrapper.activityImage = avatarImage;
                            avatarCell.activityImage.image = activityWrapper.activityImage;
                        }
                }];
            }

            // We'll always have *something* by the time the code gets here
            [cell.activityImage setImage:activityWrapper.activityImage withFade:NO];
        }
    }
}

- (void)displayNodeForActivity:(ActivityWrapper *)activityWrapper
{
    AlfrescoNode *node = activityWrapper.node;
    AlfrescoPermissions *nodePermissions = activityWrapper.nodePermissions;

    if (node.isDocument)
    {
        [UniversalDevice pushToDisplayDocumentPreviewControllerForAlfrescoDocument:(AlfrescoDocument *)node
                                                                       permissions:nodePermissions
                                                                       contentFile:[[RealmSyncCore sharedSyncCore] contentPathForNode:node forAccountIdentifier:[AccountManager sharedManager].selectedAccount.accountIdentifier]
                                                                  documentLocation:InAppDocumentLocationFilesAndFolders
                                                                           session:self.session
                                                              navigationController:self.navigationController
                                                                          animated:YES];
    }
    else if (node.isFolder)
    {
        [UniversalDevice pushToDisplayFolderPreviewControllerForAlfrescoDocument:(AlfrescoFolder *)node
                                                                     permissions:nodePermissions
                                                                         session:self.session
                                                            navigationController:self.navigationController
                                                                        animated:YES];
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
    if ([self shouldRefresh] && [notification.name isEqualToString:kAlfrescoSessionReceivedNotification])
    {
        [self loadActivities];
    }
    else if (self == [self.navigationController.viewControllers lastObject])
    {
        if (UserAccountTypeAIMS != [AccountManager sharedManager].selectedAccount.accountType)
        {
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
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
        [[LoginManager sharedManager] attemptLoginToAccount:selectedAccount networkId:selectedAccount.selectedNetworkId completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error) {
            if (successful)
            {
                [self loadActivities];
            }
        }];
    }
}

@end
