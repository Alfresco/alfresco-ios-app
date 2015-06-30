//
//  ProfileSelectionViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 24/06/2015.
//  Copyright (c) 2015 Alfresco. All rights reserved.
//

#import "ProfileSelectionViewController.h"
#import "AlfrescoConfigService.h"
#import "AppConfigurationManager.h"
#import "UserAccount.h"

static NSString * const kProfileCellIdentifier = @"ProfileCellIdentifier";

@interface ProfileSelectionViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *tableViewData;
@property (nonatomic, strong) NSString *originallySelectedProfileIdentifier;
@property (nonatomic, strong) AlfrescoProfileConfig *currentlySelectedProfile;
@property (nonatomic, strong) AlfrescoConfigService *configService;
@property (nonatomic, strong) UserAccount *account;
@end

@implementation ProfileSelectionViewController

- (instancetype)initWithAccount:(UserAccount *)account
{
    self = [super init];
    if (self)
    {
        self.account = account;
        self.configService = [[AppConfigurationManager sharedManager] configurationServiceForAccount:account];
        self.originallySelectedProfileIdentifier = account.selectedProfileIdentifier;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"main.menu.profile.selection.title", @"Profile Title");
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kProfileCellIdentifier];
    
    [self loadData];
}

- (void)dealloc
{
    if (![self.originallySelectedProfileIdentifier isEqualToString:self.currentlySelectedProfile.identifier])
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoConfigurationProfileDidChangeNotification
                                                            object:self.currentlySelectedProfile
                                                          userInfo:@{kAlfrescoConfigurationProfileDidChangeForAccountKey : self.account}];
    }
}

#pragma mark - Private Methods

- (void)loadData
{
    [self.configService retrieveProfilesWithCompletionBlock:^(NSArray *profilesArray, NSError *profilesError) {
        if (profilesError)
        {
            // TODO
        }
        else
        {
            self.tableViewData = profilesArray;
            [self.tableView reloadData];
        }
    }];
}

#pragma mark - UITableViewDataSource Delegate Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableViewData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kProfileCellIdentifier];
    
    AlfrescoProfileConfig *currentProfile = self.tableViewData[indexPath.row];
    cell.textLabel.text = NSLocalizedString(currentProfile.label, @"Localised Label");
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if ([currentProfile.identifier isEqualToString:self.originallySelectedProfileIdentifier])
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        self.currentlySelectedProfile = currentProfile;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

#pragma mark - UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *deselectedCell = [tableView cellForRowAtIndexPath:indexPath];
    deselectedCell.accessoryType = UITableViewCellAccessoryNone;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    selectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    AlfrescoProfileConfig *selectedProfile = self.tableViewData[indexPath.row];
    self.currentlySelectedProfile = selectedProfile;
}

@end
