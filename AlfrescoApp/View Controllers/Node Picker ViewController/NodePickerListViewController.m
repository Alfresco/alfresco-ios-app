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
 
#import "NodePickerListViewController.h"
#import "ThumbnailManager.h"
#import "NodePickerScopeViewController.h"
#import "NodePickerListCell.h"

static NSString * const kDefaultCellReuseIdentifier = @"PickerListDefaultCell";
static NSString * const kCustomCellReuseIdentifier = @"PickerListCustomCell";

static CGFloat const kCellHeight = 54.0f;

static NSInteger const kNumberOfTableViewSections = 2;
static NSInteger const kListSectionNumber = 1;
static NSInteger const kDefaultNumberOfRows = 1;

@interface NodePickerListViewController ()
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic, weak) NodePicker *picker;
@end

@implementation NodePickerListViewController

- (instancetype)initWithSession:(id<AlfrescoSession>)session items:(NSMutableArray *)items nodePickerController:(NodePicker *)picker
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
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kDefaultCellReuseIdentifier];
    
    UINib *cellNib = [UINib nibWithNibName:@"NodePickerListCell" bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:kCustomCellReuseIdentifier];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deselectAllSelectedNodes:)
                                                 name:kAlfrescoPickerDeselectAllNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRefreshed:) name:kAlfrescoSessionRefreshedNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.picker updateMultiSelectToolBarActionsForListView];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.picker hideMultiSelectToolBar];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (void)sessionRefreshed:(NSNotification *)notification
{
    self.session = notification.object;
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kCellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    if (indexPath.section == kListSectionNumber)
    {
        NodePickerListCell *customCell = [tableView dequeueReusableCellWithIdentifier:kCustomCellReuseIdentifier forIndexPath:indexPath];
        AlfrescoNode *node = self.items[indexPath.row];
        
        customCell.label.text = node.name;
        if (node.isDocument)
        {
            UIImage *thumbnail = [[ThumbnailManager sharedManager] thumbnailForDocument:(AlfrescoDocument *)node renditionType:kRenditionImageDocLib];
            if (thumbnail)
            {
                [customCell.thumbnail setImage:thumbnail withFade:NO];
            }
            else
            {
                [customCell.thumbnail setImage:smallImageForType([node.name pathExtension]) withFade:NO];
                [[ThumbnailManager sharedManager] retrieveImageForDocument:(AlfrescoDocument *)node renditionType:kRenditionImageDocLib session:self.session completionBlock:^(UIImage *image, NSError *error) {
                    if (image)
                    {
                        NodePickerListCell *updateCell = (NodePickerListCell *)[tableView cellForRowAtIndexPath:indexPath];
                        if (updateCell)
                        {
                            [updateCell.thumbnail setImage:image withFade:YES];
                        }
                    }
                }];
            }
        }
        else
        {
            [customCell.thumbnail setImage:smallImageForType(@"folder") withFade:NO];
        }
        customCell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell = customCell;
    }
    else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:kDefaultCellReuseIdentifier forIndexPath:indexPath];
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *headerTitle = @"";
    
    if (section == kListSectionNumber)
    {
        headerTitle = NSLocalizedString(@"nodes.picker.list.attachments.section.title", @"Selected Attachments");
    }
    return headerTitle;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectZero];
    [footerView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth];
    
    if (section == kListSectionNumber)
    {
        UILabel *footerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        footerLabel.numberOfLines = 0;
        footerLabel.backgroundColor = self.tableView.backgroundColor;
        footerLabel.textAlignment = NSTextAlignmentCenter;
        footerLabel.textColor = [UIColor textDimmedColor];
        footerLabel.font = [UIFont systemFontOfSize:15];
        [footerLabel setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
        
        if (section == kListSectionNumber)
        {
            footerLabel.text = NSLocalizedString(@"nodes.picker.list.attachments.section.footer", @"Swipe to delete");
        }
        
        [footerLabel sizeToFit];
        [footerView addSubview:footerLabel];
    }
    return footerView;
}

@end
