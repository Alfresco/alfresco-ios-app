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

#import "SiteMembersViewController.h"
#import "PersonCell.h"
#import "AvatarManager.h"
#import "AccountManager.h"
#import "LoginManager.h"
#import "PersonProfileViewController.h"
#import "UniversalDevice.h"

static CGFloat const kEstimatedCellHeight = 60.0f;

@interface SiteMembersViewController ()

@property (nonatomic, strong) NSString *siteShortName;
@property (nonatomic, strong) AlfrescoSiteService *siteService;
@property (nonatomic, strong) AlfrescoPersonService *personService;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) AlfrescoSite *site;
@property (nonatomic, strong) NSString *username;

@end

@implementation SiteMembersViewController

- (instancetype)initWithSiteShortName:(NSString *)siteShortName listingContext:(AlfrescoListingContext *)listingContext session:(id<AlfrescoSession>)session displayName:(NSString *)displayName
{
    self = [super initWithNibName:NSStringFromClass([self class]) andSession:session];
    
    if (self)
    {
        self.siteShortName = siteShortName;
        self.siteService = [[AlfrescoSiteService alloc] initWithSession:session];
        self.displayName = displayName;
        self.site = nil;
        
        if (listingContext)
        {
            self.defaultListingContext = listingContext;
        }
    }
    
    return self;
}

- (instancetype)initWithSite:(AlfrescoSite *)site session:(id<AlfrescoSession>)session
{
    self = [super initWithNibName:NSStringFromClass([self class]) andSession:session];
    
    if (self)
    {
        self.siteShortName = site.shortName;
        self.siteService = [[AlfrescoSiteService alloc] initWithSession:session];
        self.displayName = site.title;
        self.site = site;
    }
    
    return self;
}

- (instancetype)initWithUsername:(NSString *)username session:(id<AlfrescoSession>)session
{
    self = [super initWithNibName:NSStringFromClass([self class]) andSession:session];
    
    if(self)
    {
        self.username = username;
        self.displayName = username;
        self.personService = [[AlfrescoPersonService alloc] initWithSession:session];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.emptyMessage = NSLocalizedString(@"No Users", @"No Users");
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = kEstimatedCellHeight;

    self.title = self.displayName;
    UINib *nib = [UINib nibWithNibName:NSStringFromClass([PersonCell class]) bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:NSStringFromClass([PersonCell class])];
    
    [self loadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[AnalyticsManager sharedManager] trackScreenWithName:kAnalyticsViewSiteMembers];
}

#pragma mark - UITableViewDataSource and UITableViewDelegate methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoPerson *person = [self.tableViewData objectAtIndex:indexPath.row];
    PersonCell *cell = (PersonCell *)[tableView dequeueReusableCellWithIdentifier:NSStringFromClass([PersonCell class]) forIndexPath:indexPath];
    
    AvatarConfiguration *configuration = [AvatarConfiguration defaultConfigurationWithIdentifier:person.identifier session:self.session];
    [[AvatarManager sharedManager] retrieveAvatarWithConfiguration:configuration completionBlock:^(UIImage *avatarImage, NSError *avatarError) {
        [cell.avatarImageView setImage:avatarImage withFade:YES];
    }];
    
    cell.nameLabel.text = person.fullName;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableViewData.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoPerson *currentPerson = [self.tableViewData objectAtIndex:indexPath.row];
    PersonProfileViewController *personProfileViewController = [[PersonProfileViewController alloc] initWithPerson:currentPerson session:self.session];
    [UniversalDevice pushToDisplayViewController:personProfileViewController usingNavigationController:self.navigationController animated:YES];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // the last row index of the table data
    NSUInteger lastSiteRowIndex = self.tableViewData.count - 1;
    
    // if the last cell is about to be drawn, check if there are more sites
    if (indexPath.row == lastSiteRowIndex)
    {
        int maxItems = self.defaultListingContext.maxItems;
        int skipCount = self.defaultListingContext.skipCount + (int)self.tableViewData.count;
        AlfrescoListingContext *moreListingContext = [[AlfrescoListingContext alloc] initWithMaxItems:maxItems skipCount:skipCount];
   
        if (self.moreItemsAvailable)
        {
            // show more items are loading ...
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            [spinner startAnimating];
            self.tableView.tableFooterView = spinner;
            
            [self.siteService retrieveAllMembersOfSite:self.site listingContext:moreListingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error){
                [self addMoreToTableViewWithPagingResult:pagingResult error:error];
                self.tableView.tableFooterView = nil;

            }];
        }
    }
}

#pragma mark - Private methods

- (void)sessionReceived:(NSNotification *)notification
{
    id<AlfrescoSession> session = notification.object;
    self.session = session;
    self.siteService = [[AlfrescoSiteService alloc] initWithSession:session];
    if ([self shouldRefresh])
    {
        [self loadData];
    }
}

- (void)loadData
{
    void (^retrieveSiteMembers)(AlfrescoSite *site, AlfrescoListingContext *listingContext) = ^(AlfrescoSite *site, AlfrescoListingContext *listingContext)
    {
        [self.siteService retrieveAllMembersOfSite:site listingContext:listingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
            if (error)
            {
                [Notifier notifyWithAlfrescoError:error];
            }
            else
            {
                [self hideHUD];
                [self reloadTableViewWithPagingResult:pagingResult error:error];
            }
        }];
    };
    
    if(self.username)
    {
        // if there is a username present we will present the view controller with only one person
        [self.personService retrievePersonWithIdentifier:self.username completionBlock:^(AlfrescoPerson *person, NSError *error) {
            if(error)
            {
                NSString *errorTitle = NSLocalizedString(@"error.person.profile.no.profile.title", @"Profile Error Title");
                NSString *errorMessage = [NSString stringWithFormat:NSLocalizedString(@"error.person.profile.no.profile.message", @"Profile Error Message"), self.username];
                displayErrorMessageWithTitle(errorMessage, errorTitle);
            }
            else
            {
                self.tableViewData = [NSMutableArray arrayWithObject:person];
                [self.tableView reloadData];
                [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            }
        }];
    }
    else
    {
        if (self.site)
        {
            if (!self.displayName)
            {
                self.displayName = self.site.title;
                self.title = self.displayName;
            }
            retrieveSiteMembers(self.site, self.defaultListingContext);
        }
        else
        {
            [self showHUD];
            [self.siteService retrieveSiteWithShortName:self.siteShortName completionBlock:^(AlfrescoSite *site, NSError *error) {
                if (error)
                {
                    if(error.code == kAlfrescoErrorCodeRequestedNodeNotFound)
                    {
                        // display error
                        displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.sites.site.notfound", @"Site Not Found"), [ErrorDescriptions descriptionForError:error]]);
                    }
                    else
                    {
                        [Notifier notifyWithAlfrescoError:error];
                    }
                    [self hideHUD];
                }
                else
                {
                    self.site = site;
                    if (!self.displayName)
                    {
                        self.displayName = self.site.title;
                        self.title = self.displayName;
                    }
                    retrieveSiteMembers(site, self.defaultListingContext);
                }
            }];
        }
    }
}

#pragma mark - UIRefreshControl Functions

- (void)refreshTableView:(UIRefreshControl *)refreshControl
{
    [self showLoadingTextInRefreshControl:refreshControl];
    if (self.session)
    {
        [self hidePullToRefreshView];
        [self loadData];
    }
    else
    {
        [self hidePullToRefreshView];
        UserAccount *selectedAccount = [AccountManager sharedManager].selectedAccount;
        [[LoginManager sharedManager] attemptLoginToAccount:selectedAccount networkId:selectedAccount.selectedNetworkId completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error) {
            if (successful)
            {
                [self loadData];
            }
        }];
    }
}

@end
