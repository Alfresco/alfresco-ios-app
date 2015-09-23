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

#import "SiteMembersViewController.h"
#import "PersonCell.h"
#import "AvatarManager.h"
#import "AccountManager.h"
#import "LoginManager.h"
#import "PersonProfileViewController.h"
#import "UniversalDevice.h"

static CGFloat const kCellHeight = 73.0f;

@interface SiteMembersViewController ()

@property (nonatomic, strong) NSString *siteShortName;
@property (nonatomic, strong) AlfrescoSiteService *siteService;
@property (nonatomic, strong) NSString *displayName;

@end

@implementation SiteMembersViewController

- (instancetype)initWithSiteShortName:(NSString *)siteShortName session:(id<AlfrescoSession>)session displayName:(NSString *)displayName
{
    self = [super initWithNibName:NSStringFromClass([self class]) andSession:session];
    
    if(self)
    {
        self.siteShortName = siteShortName;
        self.siteService = [[AlfrescoSiteService alloc] initWithSession:session];
        self.displayName = displayName;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = self.displayName;
    UINib *nib = [UINib nibWithNibName:NSStringFromClass([PersonCell class]) bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:NSStringFromClass([PersonCell class])];
    
    [self loadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource and UITableViewDelegate methods
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoPerson *person = [self.tableViewData objectAtIndex:indexPath.row];
    PersonCell *cell = (PersonCell *)[tableView dequeueReusableCellWithIdentifier:NSStringFromClass([PersonCell class]) forIndexPath:indexPath];
    
    AvatarManager *avatarManager = [AvatarManager sharedManager];
    
    [avatarManager retrieveAvatarForPersonIdentifier:person.identifier session:self.session completionBlock:^(UIImage *image, NSError *error) {
        if(image)
        {
            cell.avatarImageView.image = image;
        }
        else
        {
            UIImage *placeholderImage = [UIImage imageNamed:@"avatar.png"];
            cell.avatarImageView.image = placeholderImage;
        }
    }];
    cell.nameLabel.text = person.fullName;
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableViewData.count;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kCellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoPerson *currentPerson = [self.tableViewData objectAtIndex:indexPath.row];
    PersonProfileViewController *personProfileViewController = [[PersonProfileViewController alloc] initWithUsername:currentPerson.identifier session:self.session];
    [UniversalDevice pushToDisplayViewController:personProfileViewController usingNavigationController:self.navigationController animated:YES];
}

#pragma mark - Private methods
- (void)loadData
{
    [self showHUD];
    [self.siteService retrieveSiteWithShortName:self.siteShortName completionBlock:^(AlfrescoSite *site, NSError *error) {
        if(error)
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
            [self.siteService retrieveAllMembersOfSite:site listingContext:self.defaultListingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
                if(error)
                {
                    [Notifier notifyWithAlfrescoError:error];
                }
                else
                {
                    [self hideHUD];
                    [self reloadTableViewWithPagingResult:pagingResult error:error];
                }
            }];
        }
    }];
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
