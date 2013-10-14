//
//  MainMenuViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 10/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "MainMenuViewController.h"

@interface MainMenuViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong, readwrite) NSMutableArray *tableData;
@property (nonatomic, weak, readwrite) UITableView *tableView;

@end

@implementation MainMenuViewController

- (instancetype)initWithSectionArrays:(NSArray *)sections, ...
{
    self = [super init];
    if (self)
    {
        self.tableData = [NSMutableArray array];
        va_list args;
        va_start(args, sections);
        for (id arg = sections; arg != nil; arg = va_arg(args, id))
        {
            [self.tableData addObject:arg];
        }
        va_end(args);
    }
    return self;
}

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:view.frame style:UITableViewStyleGrouped];
    tableView.bounces = NO;
    tableView.backgroundView = nil;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.separatorColor = [UIColor clearColor];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView = tableView;
    [view addSubview:self.tableView];
    
    view.autoresizesSubviews = YES;
    self.view = view;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.tableData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sectionArray = [self.tableData objectAtIndex:section];
    return sectionArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    NSArray *sectionArray = [self.tableData objectAtIndex:indexPath.section];
    MainMenuItem *currentItem = [sectionArray objectAtIndex:indexPath.row];
    cell.textLabel.text = NSLocalizedString(currentItem.localizedTitleKey, @"Localised Cell Title") ;
    cell.imageView.image = [UIImage imageNamed:currentItem.imageName];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor clearColor];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSArray *sectionArray = [self.tableData objectAtIndex:indexPath.section];
    MainMenuItem *selectedMenuItem = [sectionArray objectAtIndex:indexPath.row];
    
    [self informDelegateMenuItemSelected:selectedMenuItem];
}

#pragma mark - Private Functions

- (void)informDelegateMenuItemSelected:(MainMenuItem *)menuItem
{
    [self.delegate didSelectMenuItem:menuItem];
}

@end
