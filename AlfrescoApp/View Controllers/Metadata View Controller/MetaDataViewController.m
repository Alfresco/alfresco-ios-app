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
 
#import "MetaDataViewController.h"
#import "MetadataCell.h"
#import "ConnectivityManager.h"
#import "TableviewUnderlinedHeaderView.h"


static NSString * kMetadataToDisplayPlistName = @"MetadataDisplayList";
static NSString * kDateFormat = @"d MMM yyyy HH:mm";
static NSString * kNodeTagsKey = @"nodeTags";
static NSString * kCMISVersionLabel = @"cmis:versionLabel";

@interface MetaDataViewController ()
@property (nonatomic, strong) NSMutableDictionary *propertiesToDisplayWithValues;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) AlfrescoTaggingService *tagService;
@property (nonatomic, strong) NSMutableArray *sectionHeaderKeys;
@end

@implementation MetaDataViewController

- (id)initWithAlfrescoNode:(AlfrescoNode *)node session:(id<AlfrescoSession>)session
{
    self = [super initWithSession:session];
    if (self)
    {
        // setup tag service first as it's used in setNode
        self.tagService = [[AlfrescoTaggingService alloc] initWithSession:session];
        self.node = node;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setAccessibilityIdentifiers];
    self.allowsPullToRefresh = NO;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.title = self.node.name;
}

#pragma mark - Custom Setters

- (void)setNode:(AlfrescoNode *)node
{
    _node = node;
    [self setupMetadataToDisplayWithNode:node];
}

#pragma mark - Private Functions

- (void)setupMetadataToDisplayWithNode:(AlfrescoNode *)node
{
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:kMetadataToDisplayPlistName ofType:@"plist"];
    NSDictionary *allPossibleDisplayMetadata = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    NSMutableArray *tableDataArray = [NSMutableArray array];
    NSMutableDictionary *metadataToDisplayWithValues = [NSMutableDictionary dictionary];
    
    self.sectionHeaderKeys = [NSMutableArray array];
    
    [allPossibleDisplayMetadata enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSArray *propertySectionArray, BOOL *stop) {
        NSMutableArray *sectionArray = [NSMutableArray array];
        
        [propertySectionArray enumerateObjectsUsingBlock:^(NSString *propertyName, NSUInteger idx, BOOL *stop) {
            AlfrescoProperty *propertyObject = (AlfrescoProperty *)[node.properties objectForKey:propertyName];
            if ([propertyObject value] != nil)
            {
                [sectionArray addObject:propertyName];
                metadataToDisplayWithValues[propertyName] = propertyObject;
            }
        }];
        
        if (sectionArray.count > 0)
        {
            [self.sectionHeaderKeys addObject:key];
            [tableDataArray addObject:sectionArray];
        }
    }];
    
    self.tableViewData = tableDataArray;
    self.propertiesToDisplayWithValues = metadataToDisplayWithValues;
    
    // fetch any tags the node may have in the background
    __weak typeof(self) weakSelf = self;
    [self.tagService retrieveTagsForNode:node completionBlock:^(NSArray *array, NSError *error) {
        if (array.count > 0 && self.tableViewData.count > 0)
        {
            NSString *tags = [[array valueForKeyPath:@"value"] componentsJoinedByString:@", "];
            weakSelf.propertiesToDisplayWithValues[kNodeTagsKey] = tags;
            [weakSelf.tableViewData[0] addObject:kNodeTagsKey];
            [weakSelf.tableView reloadData];
        }
    }];
}

- (void)setAccessibilityIdentifiers
{
    self.view.accessibilityIdentifier = kMetadataVCViewIdentifier;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.tableViewData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == self.tableViewData.count)
    {
        return 1;
    }
    return [[self.tableViewData objectAtIndex:section] count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [TableviewUnderlinedHeaderView headerViewHeight];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    TableviewUnderlinedHeaderView *headerView = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TableviewUnderlinedHeaderView class]) owner:self options:nil] lastObject];
    headerView.headerTitleTextLabel.textColor = [UIColor appTintColor];
    
    NSString *headerTitleText = nil;
    if (section < self.sectionHeaderKeys.count)
    {
        NSString *stringKey = [NSString stringWithFormat:@"metadata.section.header.%@", self.sectionHeaderKeys[section]];
        headerTitleText = NSLocalizedString(stringKey, @"Section Header");
    }
    
    headerView.headerTitleTextLabel.text = [headerTitleText uppercaseString];
    
    return headerView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *MetadataCellIdentifier = @"MetadataCell";
    MetadataCell *metadataCell = [tableView dequeueReusableCellWithIdentifier:MetadataCellIdentifier];
    
    if (!metadataCell)
    {
        metadataCell = (MetadataCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([MetadataCell class]) owner:self options:nil] lastObject];
        metadataCell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    // config the cell here...
    NSArray *dataSourceArray = nil;
    if (indexPath.section < self.tableViewData.count)
    {
        dataSourceArray = [self.tableViewData objectAtIndex:indexPath.section];
    }
    
    if (dataSourceArray)
    {
        NSString *currentPropertyKey = [dataSourceArray objectAtIndex:indexPath.row];
        id currentProperty = [self.propertiesToDisplayWithValues objectForKey:currentPropertyKey];
        id currentPropertyValue = nil;
        
        if ([currentProperty isKindOfClass:[NSString class]])
        {
            currentPropertyValue = currentProperty;
        }
        else if ([currentProperty isKindOfClass:[AlfrescoProperty class]])
        {
            currentPropertyValue = ((AlfrescoProperty *)currentProperty).value;
        }
        
        if ([currentPropertyKey isEqualToString:kCMISVersionLabel])
        {
            currentPropertyValue = [currentPropertyValue isEqualToString:@"0.0"] ? @"1.0" : currentPropertyValue;
        }
        
        NSString *localisedKey = [NSString stringWithFormat:@"metadata.%@", currentPropertyKey];
        metadataCell.propertyNameLabel.text = NSLocalizedString(localisedKey, @"Metadata current Property");
        
        if ([currentPropertyValue isKindOfClass:[NSString class]])
        {
            metadataCell.propertyValueLabel.text = currentPropertyValue;
        }
        else if ([currentPropertyValue isKindOfClass:[NSDate class]])
        {
            if (!self.dateFormatter)
            {
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                [dateFormatter setDateFormat:kDateFormat];
                self.dateFormatter = dateFormatter;
            }
            
            metadataCell.propertyValueLabel.text = [self.dateFormatter stringFromDate:currentPropertyValue];
        }
        else if ([currentPropertyValue isKindOfClass:[NSNumber class]])
        {
            NSNumber *currentPropertyNumber = (NSNumber *)currentPropertyValue;
            if (strcmp([currentPropertyNumber objCType], @encode(BOOL)) == 0)
            {
                metadataCell.propertyValueLabel.text = ([currentPropertyNumber boolValue]) ? NSLocalizedString(@"Yes", @"Yes") : NSLocalizedString(@"No", @"No");
            }
            else if (strcmp([currentPropertyNumber objCType], @encode(int)) == 0)
            {
                NSString *labelText = nil;
                if ([currentPropertyKey isEqualToString:@"exif:orientation"])
                {
                    switch ([currentPropertyValue intValue])
                    {
                        case 1:
                            labelText = NSLocalizedString(@"metadata.exif.orientation.landscape.left", @"Landscape left");
                            break;
                        case 3:
                            labelText = NSLocalizedString(@"metadata.exif.orientation.landscape.right", @"Landscape right");
                            break;
                        case 6:
                            labelText = NSLocalizedString(@"metadata.exif.orientation.portrait", @"Portrait");
                            break;
                        case 8:
                            labelText = NSLocalizedString(@"metadata.exif.orientation.portrait.upsidedown", @"Portrait Up-side Down");
                            break;
                        default:
                            labelText = NSLocalizedString(@"metadata.exif.orientation.undefined", @"undefined");
                            break;
                    }
                }
                else
                {
                    labelText = [NSString stringWithFormat:@"%i", [currentPropertyValue intValue]];
                }
                
                metadataCell.propertyValueLabel.text = labelText;
            }
            else if (strcmp([currentPropertyNumber objCType], @encode(double)) == 0)
            {
                NSString *labelText = nil;
                if ([currentPropertyKey isEqualToString:@"exif:exposureTime"])
                {
                    float floatValue = [currentPropertyNumber floatValue];
                    if (1.0 < floatValue)
                    {
                        labelText = [NSString stringWithFormat:@"%d", (int)((1./floatValue) + 0.5)];
                    }
                    else if (1.0 > floatValue && 0.0 < floatValue)
                    {
                        labelText = [NSString stringWithFormat:@"1/%d", (int)((1./floatValue) + 0.5)];
                    }
                    else
                    {
                        labelText = [NSString stringWithFormat:@"%.0f", floatValue];
                    }
                }
                else if ([currentPropertyKey isEqualToString:@"cm:longitude"] || [currentPropertyKey isEqualToString:@"cm:latitude"])
                {
                    labelText = [NSString stringWithFormat:@"%.5f", [currentPropertyValue doubleValue]];
                }
                else
                {
                    labelText = [NSString stringWithFormat:@"%.0f", [currentPropertyValue doubleValue]];
                }
                
                metadataCell.propertyValueLabel.text = labelText;
            }
            else
            {
                metadataCell.propertyValueLabel.text = [currentPropertyValue stringValue];
            }
        }
    }
    
    return metadataCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MetadataCell *cell = (MetadataCell *)[self tableView:tableView cellForRowAtIndexPath:indexPath];
    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingExpandedSize].height;
    
    return height;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - DocumentInDetailView Protocol functions

- (NSString *)detailViewItemIdentifier
{
    return (self.node) ? self.node.identifier : nil;
}

#pragma mark - NodeUpdatableProtocal Functions

- (void)updateToAlfrescoNode:(AlfrescoNode *)node permissions:(AlfrescoPermissions *)permissions session:(id<AlfrescoSession>)session;
{
    self.tagService = [[AlfrescoTaggingService alloc] initWithSession:session];
    self.node = node;
    [self.tableView reloadData];
}

@end
