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

#import "SearchViewController.h"
#import "SearchTableViewCell.h"
#import "UniversalDevice.h"
#import "RootRevealViewController.h"

static NSString * const kCellTextKey = @"CellText";
static NSString * const kCellImageKey = @"CellImage";

@interface SearchViewController ()

@property (nonatomic, strong) NSMutableArray *dataSourceInfo;

@end

@implementation SearchViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    self.dataSourceInfo = [[NSMutableArray alloc] initWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"search.files", @"Files"), kCellTextKey, @"small_document", kCellImageKey, nil], [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"search.folders", @"Folders"), kCellTextKey, @"small_folder", kCellImageKey, nil], [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"search.sites", @"Sites"), kCellTextKey, @"mainmenu-sites", kCellImageKey, nil], [NSDictionary dictionaryWithObjectsAndKeys:NSLocalizedString(@"search.people", @"People"), kCellTextKey, @"mainmenu-user", kCellImageKey, nil], nil];
    self.title = NSLocalizedString(@"view-search-default", @"Search");
    
    if (!IS_IPAD && !self.presentingViewController)
    {
        UIBarButtonItem *hamburgerButtom = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"hamburger.png"] style:UIBarButtonItemStylePlain target:self action:@selector(expandRootRevealController)];
        if (self.navigationController.viewControllers.firstObject == self)
        {
            self.navigationItem.leftBarButtonItem = hamburgerButtom;
        }
    }
    
    UINib *cellNib = [UINib nibWithNibName:NSStringFromClass([SearchTableViewCell class]) bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:NSStringFromClass([SearchTableViewCell class])];
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataSourceInfo.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SearchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SearchTableViewCell class]) forIndexPath:indexPath];
    
    NSDictionary *cellDataSource = self.dataSourceInfo[indexPath.row];
    cell.searchItemText.text = [cellDataSource objectForKey:kCellTextKey];
    [cell.searchItemImage setImage:[UIImage imageNamed:[cellDataSource objectForKey:kCellImageKey]]];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return NSLocalizedString(@"search.searchfor", @"Search for");
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 50;
}

/*
#pragma mark - Table view delegate

// In a xib-based application, navigation from a table can be handled in -tableView:didSelectRowAtIndexPath:
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here, for example:
    // Create the next view controller.
    <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:<#@"Nib name"#> bundle:nil];
    
    // Pass the selected object to the new view controller.
    
    // Push the view controller.
    [self.navigationController pushViewController:detailViewController animated:YES];
}
*/

- (void)expandRootRevealController
{
    [(RootRevealViewController *)[UniversalDevice revealViewController] expandViewController];
}

@end
