//
//  MoreViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "MoreViewController.h"
#import "AboutViewController.h"
#import "PreviewViewController.h"
#import "UniversalDevice.h"
#import "DownloadsViewController.h"
#import "SettingsViewController.h"
#import "SyncViewController.h"

NSString *kHelpGuide = @"UserGuide.pdf";
CGFloat const kMoreTableCellHeight = 60.0f;

@interface MoreViewController ()

@property (nonatomic, strong) NSMutableArray *tableViewData;
@property (nonatomic, strong) id<AlfrescoSession> session;
@end

@implementation MoreViewController

- (id)initWithSession:(id<AlfrescoSession>)session
{
    self = [super init];
    if (self)
    {
        self.session = session;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(sessionReceived:)
                                                     name:kAlfrescoSessionReceivedNotification
                                                   object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navigationItem setTitle:NSLocalizedString(@"more.view.title", @"More")];
    
    [self constructMoreTabs];
}

- (void)sessionReceived:(NSNotification *)notification
{
    id <AlfrescoSession> session = notification.object;
    self.session = session;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableViewData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"MoreCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = self.tableViewData[indexPath.row];
    
    if ([self.tableViewData[indexPath.row] isEqualToString:NSLocalizedString(@"help.view.title", @"Help tab bar button label")])
    {
        cell.imageView.image = [UIImage imageNamed:@"help-more"];
    }
    else if ([self.tableViewData[indexPath.row] isEqualToString:NSLocalizedString(@"About", @"About tab bar button label")])
    {
        cell.imageView.image = [UIImage imageNamed:@"about-more"];
    }
    else if ([self.tableViewData[indexPath.row] isEqualToString:NSLocalizedString(@"Downloads", @"Downloads tab bar button label")])
    {
        cell.imageView.image = [UIImage imageNamed:@"downloads-tabbar.png"];
    }
    else if ([self.tableViewData[indexPath.row] isEqualToString:NSLocalizedString(@"Favorites", @"Favorites tab bar button label")])
    {
        cell.imageView.image = [UIImage imageNamed:@"help-more"];
    }
    else if ([self.tableViewData[indexPath.row] isEqualToString:NSLocalizedString(@"settings.title", @"Settings tab bar button label")])
    {
        cell.imageView.image = [UIImage imageNamed:@"help-more"];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    
    return cell;
}

- (void)constructMoreTabs
{
    self.tableViewData = [@[NSLocalizedString(@"Downloads", @"Downloads tab bar button label"),
                            NSLocalizedString(@"Favorites", @"Favorites tab bar button label"),
                            NSLocalizedString(@"settings.title", @"Settings tab bar button label"),
                            NSLocalizedString(@"help.view.title", @"Help tab bar button label"),
                            NSLocalizedString(@"About", @"About tab bar button label")] mutableCopy];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id viewController = nil;
    
    if ([self.tableViewData[indexPath.row] isEqualToString:NSLocalizedString(@"help.view.title", @"Help tab bar button label")])
    {
        viewController = [[PreviewViewController alloc] initWithBundleDocument:kHelpGuide];
    }
    else if ([self.tableViewData[indexPath.row] isEqualToString:NSLocalizedString(@"About", @"About tab bar button label")])
    {
        viewController = [[AboutViewController alloc] init];
    }
    else if ([self.tableViewData[indexPath.row] isEqualToString:NSLocalizedString(@"Downloads", @"Downloads tab bar button label")])
    {
        viewController = [[DownloadsViewController alloc] initWithSession:nil];
    }
    else if ([self.tableViewData[indexPath.row] isEqualToString:NSLocalizedString(@"Favorites", @"Favorites tab bar button label")])
    {
        viewController = [[SyncViewController alloc] initWithParentNode:nil andSession:self.session];
    }
    else if ([self.tableViewData[indexPath.row] isEqualToString:NSLocalizedString(@"settings.title", @"Settings tab bar button label")])
    {
        viewController = [[SettingsViewController alloc] initWithSession:nil];
    }
    
    if ([viewController isKindOfClass:[DownloadsViewController class]] || [viewController isKindOfClass:[SyncViewController class]])
    {
        [self.navigationController pushViewController:viewController animated:YES];
    }
    else
    {
        [UniversalDevice pushToDisplayViewController:viewController usingNavigationController:self.navigationController animated:YES];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kMoreTableCellHeight;
}

@end
