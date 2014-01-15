//
//  MetaDataViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "MetaDataViewController.h"
#import "MetadataCell.h"
#import "ConnectivityManager.h"
#import "MetadataHeaderView.h"

static NSString * kMetadataToDisplayPlistName = @"MetadataDisplayList";
static NSString * kDateFormat = @"d MMM yyyy HH:mm";
static NSString * kNodeTagsKey = @"nodeTags";
static NSString * kCMISVersionLabel = @"cmis:versionLabel";

@interface MetaDataViewController ()

@property (nonatomic, strong) NSDictionary *propertiesToDisplayWithValues;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong, readwrite) AlfrescoNode *node;
@property (nonatomic, strong) AlfrescoTaggingService *tagService;

@end

@implementation MetaDataViewController

- (id)initWithAlfrescoNode:(AlfrescoNode *)node session:(id<AlfrescoSession>)session
{
    self = [super initWithSession:session];
    if (self)
    {
        self.node = node;
        self.tagService = [[AlfrescoTaggingService alloc] initWithSession:session];
        [self setupMetadataToDisplayWithNode:node];
    }
    return self;
}

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // create and configure the table view
    self.tableView = [[UITableView alloc] initWithFrame:view.frame style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [view addSubview:self.tableView];
    
    view.autoresizesSubviews = YES;
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self disablePullToRefresh];
    
    self.title = self.node.name;
    [self retrieveTagsForNode:self.node];
}

#pragma mark - Private Functions

- (void)retrieveTagsForNode:(AlfrescoNode *)node
{
    [self.tagService retrieveTagsForNode:node completionBlock:^(NSArray *array, NSError *error) {
        if (array.count > 0 && self.tableViewData.count > 0)
        {
            NSString *tags = [[array valueForKeyPath:@"value"] componentsJoinedByString:@", "];
            [self.propertiesToDisplayWithValues setValue:tags forKey:kNodeTagsKey];
            [self.tableViewData[0] addObject:kNodeTagsKey];
            [self.tableView reloadData];
        }
    }];
}

- (void)setupMetadataToDisplayWithNode:(AlfrescoNode *)node
{
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:kMetadataToDisplayPlistName ofType:@"plist"];
    NSArray *allPossibleDisplayMetadata = [NSArray arrayWithContentsOfFile:plistPath];
    
    NSMutableArray *metadataToDisplayKeys = [NSMutableArray array];
    NSMutableDictionary *metadataToDisplayWithValues = [NSMutableDictionary dictionary];
    
    [allPossibleDisplayMetadata enumerateObjectsUsingBlock:^(NSArray *propertySectionArray, NSUInteger idx, BOOL *stop) {
        NSMutableArray *sectionArray = [NSMutableArray array];
        
        [propertySectionArray enumerateObjectsUsingBlock:^(NSString *propertyName, NSUInteger idx, BOOL *stop) {
            AlfrescoProperty *propertyObject = (AlfrescoProperty *)[node.properties objectForKey:propertyName];
            if ([propertyObject value] != nil)
            {
                [sectionArray addObject:propertyName];
                [metadataToDisplayWithValues setObject:propertyObject forKey:propertyName];
            }
        }];
        
        if (sectionArray.count > 0)
        {
            [metadataToDisplayKeys addObject:sectionArray];
        }
    }];
    
    self.tableViewData = metadataToDisplayKeys;
    self.propertiesToDisplayWithValues = metadataToDisplayWithValues;
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
    return kMetadataHeaderViewHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    MetadataHeaderView *headerView = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([MetadataHeaderView class]) owner:self options:nil] lastObject];
    
    NSString *headerTitleText = nil;
    if (section < self.tableViewData.count)
    {
        switch (section)
        {
            case 0:
                headerTitleText = NSLocalizedString(@"metadata.general.section.header.title", @"General Section Header");
                break;

            case 1:
                headerTitleText = NSLocalizedString(@"metadata.image.information.section.header.title", @"Image Section Header");
                break;
        }
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
        }
    }
    
    return metadataCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MetadataCell *cell = (MetadataCell *)[self tableView:tableView cellForRowAtIndexPath:indexPath];
    
    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    
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

@end
