//
//  NodePickerListViewController.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 27/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

static NSString * const kCellReuseIdentifier = @"PickerListCell";

static NSInteger const kNumberOfTableViewSections = 2;
static NSInteger const kListSectionNumber = 1;
static NSInteger const kDefaultNumberOfRows = 1;

#import "NodePickerListViewController.h"
#import "ThumbnailDownloader.h"
#import "Utility.h"
#import "NodePickerSitesViewController.h"
#import "PeoplePickerViewController.h"

@interface NodePickerListViewController ()

@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic, strong) id picker;

@end

@implementation NodePickerListViewController

- (instancetype)initWithSession:(id<AlfrescoSession>)session items:(NSMutableArray *)items nodePickerController:(id)picker
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self)
    {
        _session = session;
        _items = items;
        _picker = picker;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"nodes.picker.list.title", @"Attachements");
    
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kCellReuseIdentifier];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deselectAllSelectedNodes:)
                                                 name:kAlfrescoPickerDeselectAllNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.picker updateMultiSelectToolBarActionsForListView];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.picker hideMultiSelectToolBar];
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

- (void)deselectAllSelectedNodes:(id)sender
{
    [self.items removeAllObjects];
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
        id item = self.items[indexPath.row];
        
        if ([item isKindOfClass:[AlfrescoNode class]])
        {
            AlfrescoNode *node = (AlfrescoNode *)item;
            cell.textLabel.text = node.name;
            cell.imageView.image = smallImageForType([node.name pathExtension]);
        }
        else if ([item isKindOfClass:[AlfrescoPerson class]])
        {
            AlfrescoPerson *person = (AlfrescoPerson *)item;
            cell.textLabel.text = person.fullName;
        }
    }
    else
    {
        cell.textLabel.text = NSLocalizedString(@"nodes.picker.attachments.select", @"");
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section != kListSectionNumber)
    {
        [self.picker replaceSelectedNodesWithNodes:self.items];
        NodePickerSitesViewController *sitesPickerController = [[NodePickerSitesViewController alloc] initWithSession:self.session nodePickerController:self.picker];
        [self.navigationController pushViewController:sitesPickerController animated:YES];
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
        [self.picker deselectNode:node];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

@end
