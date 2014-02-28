//
//  AlfrescoAppPickerItemsListViewController.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 27/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

static NSString * const kCellReuseIdentifier = @"PickerListCell";

static NSInteger const kNumberOfTableViewSections = 2;
static NSInteger const kListSectionNumber = 1;
static NSInteger const kDefaultNumberOfRows = 1;

#import "AlfrescoAppPickerItemsListViewController.h"
#import "ThumbnailDownloader.h"
#import "Utility.h"
#import "NodePickerSitesViewController.h"

@interface AlfrescoAppPickerItemsListViewController ()

@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic, assign) AlfrescoAppPickerItemsListType listType;
@property (nonatomic, strong) AlfrescoAppPicker *nodePicker;

@end

@implementation AlfrescoAppPickerItemsListViewController

- (instancetype)initWithSession:(id<AlfrescoSession>)session pickerListType:(AlfrescoAppPickerItemsListType)listType items:(NSMutableArray *)items nodePickerController:(AlfrescoAppPicker *)nodePicker
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self)
    {
        _session = session;
        _items = items;
        _listType = listType;
        _nodePicker = nodePicker;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.listType == PickerItemsListTypeNodesMultiSelection)
    {
        self.title = NSLocalizedString(@"picker.multiSelect.list.title", @"Multi Select List title");
    }
    else
    {
        
    }
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellReuseIdentifier];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.nodePicker hideMultiSelectToolBar];
}

- (void)editButtonPressed:(id)sender
{
    self.tableView.editing = !self.tableView.isEditing;
}

- (void)refreshListWithItems:(NSArray *)items
{
    self.items = [items mutableCopy];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kNumberOfTableViewSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;
    
    if (section == kListSectionNumber)
    {
        numberOfRows = self.items.count;
    }
    else
    {
        numberOfRows = kDefaultNumberOfRows;
    }
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellReuseIdentifier forIndexPath:indexPath];
    
    if (indexPath.section == kListSectionNumber)
    {
        AlfrescoNode *node = self.items[indexPath.row];
        cell.textLabel.text = node.name;
        cell.imageView.image = smallImageForType([node.name pathExtension]);
    }
    else
    {
        if (self.listType == PickerItemsListTypeNodesMultiSelection)
        {
            cell.textLabel.text = NSLocalizedString(@"picker.multiSelect.attachments.select", @"");
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section != kListSectionNumber)
    {
        [self.nodePicker replaceSelectedItemsWithItems:self.items];
        NodePickerSitesViewController *sitescontroller = [[NodePickerSitesViewController alloc] initWithSession:self.session nodePickerController:self.nodePicker];
        [self.navigationController pushViewController:sitescontroller animated:YES];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.section == kListSectionNumber;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        AlfrescoNode *node = self.items[indexPath.row];
        
        [self.items removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self.nodePicker deselectItem:node];
    }
}

@end
