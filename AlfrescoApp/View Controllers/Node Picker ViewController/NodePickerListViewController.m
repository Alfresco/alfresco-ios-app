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
#import "NodePickerScopeViewController.h"

@interface NodePickerListViewController ()

@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic, weak) NodePicker *picker;

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
        AlfrescoNode *node = self.items[indexPath.row];
        
        cell.textLabel.text = node.name;
        cell.imageView.image = smallImageForType([node.name pathExtension]);
        
        if (node.isDocument)
        {
            UIImage *thumbnail = [[ThumbnailDownloader sharedManager] thumbnailForDocument:(AlfrescoDocument *)node renditionType:kRenditionImageDocLib];
            if (thumbnail)
            {
                cell.imageView.image = thumbnail;
            }
            else
            {
                UIImage *placeholderImage = smallImageForType([node.name pathExtension]);
                cell.imageView.image = placeholderImage;
                [[ThumbnailDownloader sharedManager] retrieveImageForDocument:(AlfrescoDocument *)node renditionType:kRenditionImageDocLib session:self.session completionBlock:^(UIImage *image, NSError *error) {
                    if (image)
                    {
                        cell.imageView.image = image;
                    }
                }];
            }
        }
        else
        {
            cell.imageView.image = smallImageForType(@"folder");
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
        NodePickerScopeViewController *scopeController = [[NodePickerScopeViewController alloc] initWithSession:self.session nodePickerController:self.picker];
        [self.navigationController pushViewController:scopeController animated:YES];
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
