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

NSString *kHelpGuide = @"UserGuide.pdf";
CGFloat const kMoreTableCellHeight = 60.0f;

@interface MoreViewController ()

@property (nonatomic, strong) NSMutableArray *tableViewData;

@end

@implementation MoreViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navigationItem setTitle:NSLocalizedString(@"more.view.title", @"More")];
    
    [self constructMoreTabs];
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
    
    cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    
    return cell;
}

- (void)constructMoreTabs
{
    self.tableViewData = [@[NSLocalizedString(@"help.view.title", @"Help tab bar button label"), NSLocalizedString(@"About", @"About tab bar button label")] mutableCopy];
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
    
    [UniversalDevice pushToDisplayViewController:viewController usingNavigationController:self.navigationController animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kMoreTableCellHeight;
}

@end
