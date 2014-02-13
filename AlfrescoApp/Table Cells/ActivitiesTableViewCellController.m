//
//  ActivitiesTableViewCellController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "ActivitiesTableViewCellController.h"
#import "ActivityTableViewCell.h"
#import "Utility.h"

NSString * const kActivityCellIdentifier = @"ActivityCell";

NSString * const kActivityTitle = @"title";
NSString * const kActivityNodeRef = @"nodeRef";
NSString * const kActivityObjectId = @"objectId";
NSString * const kActivityFirstName = @"firstName";
NSString * const kActivityLastName = @"lastName";
NSString * const kActivityUserFirstName = @"userFirstName";
NSString * const kActivityUserLastName = @"userLastName";
NSString * const kActivityMemberUserName = @"memberUserName";
NSString * const kActivityRole = @"role";
NSString * const kActivityStatus = @"status";
NSString * const kActivityPage = @"page";

static CGFloat const kDefaultCellHeight = 44.0f;
static CGFloat const kFontSize = 17.0f;

@interface ActivitiesTableViewCellController ()

@property (nonatomic, strong) AlfrescoPersonService *personService;
@property (nonatomic, strong) ActivityTableViewCell *activityCell;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *cellTitle;
@property (nonatomic, strong) NSAttributedString *attributedCellTitle;
@property (nonatomic, strong) NSString *cellSubTitle;
@property (nonatomic, strong) NSString *replacedActivityText;
@property (nonatomic, assign) UITableViewCellAccessoryType accesoryType;
@property (nonatomic, strong) NSMutableAttributedString *mutableString;
@property (nonatomic, strong) UIImage *activityIcon;

@end

@implementation ActivitiesTableViewCellController

- (id)initWithSession:(id<AlfrescoSession>)session
{
    self = [super init];
    
    if (self)
    {
        self.personService = [[AlfrescoPersonService alloc] initWithSession:session];
    }
    return self;
}

- (void)setActivity:(AlfrescoActivityEntry *)activity
{
    _activity = activity;
    self.title = activity.data[kActivityTitle];
    self.cellTitle = [self activityText];
    self.cellSubTitle = [NSString stringWithFormat:@"%@", self.activity.createdAt];
}

- (void)populateActivityCell:(ActivityTableViewCell *)cell
{
    if (!self.attributedCellTitle)
    {
        self.attributedCellTitle = [self applyBoldAttributesToStrings:[self textReplacements] inText:self.cellTitle];
    }
    cell.summaryLabel.attributedText = self.attributedCellTitle;
    cell.detailsLabel.text = relativeDateFromDate(self.activity.createdAt);
    
    self.isActivityTypeDocument = [[self activityDocumentType] containsObject:self.activity.type];
    self.isActivityTypeFolder = [self.activity.type hasPrefix:@"org.alfresco.documentlibrary.folder"];
    
    [self replaceActivityCellImageViewIconWithIcon:self.activityIcon];
    
    BOOL isFileOrFolder = (self.isActivityTypeDocument || self.isActivityTypeFolder);
    BOOL nodeRefExists = (self.activity.data[kActivityNodeRef] != nil) || (self.activity.data[kActivityObjectId] != nil);
    BOOL isDeleted = [self.activity.type hasSuffix:@"-deleted"];
    
    if (isFileOrFolder && nodeRefExists && !isDeleted)
    {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.accessoryView = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
}

- (ActivityTableViewCell *)createActivityTableViewCellInTableView:(UITableView *)tableView
{
    ActivityTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kActivityCellIdentifier];
    
    self.activityCell = cell;
    [self populateActivityCell:cell];
    
    return cell;
}

- (NSAttributedString *)applyBoldAttributesToStrings:(NSArray *)strings inText:(NSString *)text
{
    UIFont *normalFont = [UIFont systemFontOfSize:kFontSize];
    UIFont *boldFont = [UIFont boldSystemFontOfSize:kFontSize];
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:text attributes:@{NSFontAttributeName:normalFont}];
    
    for (NSString *string in strings)
    {
        NSRange rangeOfString = [text rangeOfString:string];
        [attributedText setAttributes:@{NSFontAttributeName:boldFont} range:rangeOfString];
    }
    return attributedText;
}

- (UITableViewCell *)createActivityErrorTableViewCellInTableView:(UITableView *)tableView
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ErrorCell"];
    
    cell.textLabel.text = NSLocalizedString(@"activities.empty", @"No activities Available");
    cell.imageView.image = nil;
    
    return cell;
}

- (CGFloat)heightForCellAtIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *)tableView withSections:(NSArray *)sections
{
    CGFloat height = kDefaultCellHeight;
    if (sections)
    {
        ActivityTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kActivityCellIdentifier];
        [self populateActivityCell:cell];
        
        [cell.summaryLabel sizeThatFits:self.attributedCellTitle.size];
        
        [cell setNeedsLayout];
        [cell layoutIfNeeded];
        
        CGSize size = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingExpandedSize];
        height = size.height;
    }
    return height;
}

- (NSString *)activityText
{
    if (self.replacedActivityText == nil)
    {
        NSString *text = NSLocalizedStringFromTable(self.activity.type, @"Activities", @"Activity type text");
        
        self.replacedActivityText = [self replaceIndexPointsIn:text withValues:[self textReplacements]];
    }
    
    return self.replacedActivityText;
}

- (NSString *)replaceIndexPointsIn:(NSString *)string withValues:(NSArray *)replacements
{
    for (NSInteger index = 0; index < replacements.count; index++)
    {
        NSString *indexPoint = [NSString stringWithFormat:@"{%d}", index];
        string = [string stringByReplacingOccurrencesOfString:indexPoint withString:replacements[index]];
    }
    
    return string;
}

- (NSArray *)textReplacements
{
    NSString *role = self.activity.data[kActivityRole] ? self.activity.data[kActivityRole] : @"";
    NSString *siteName = self.activity.siteShortName ? self.activity.siteShortName : @"";
    NSString *status = self.activity.data[kActivityStatus] ? self.activity.data[kActivityStatus] : @"";
    
    NSString *user = [NSString stringWithFormat:@"%@ %@", self.activity.data[kActivityFirstName], self.activity.data[kActivityLastName]];
    NSString *following = [NSString stringWithFormat:@"%@ %@", self.activity.data[kActivityUserFirstName], self.activity.data[kActivityUserLastName]];
    
    user = user ? user : @"";
    following = following ? following : @"";
    
    if ([self.activity.data[kActivityTitle] isKindOfClass:[NSString class]])
    {
        self.title = self.activity.data[kActivityTitle] ? self.activity.data[kActivityTitle] : @"";
    }
    else
    {
        self.title = self.activity.data[kActivityTitle] ? [self.activity.data[kActivityTitle] stringValue] : @"";
    }
    
    return @[self.title, user, role, @"", siteName, following, status];
}

#pragma mark - private methods

- (NSArray *)activityDocumentType
{
    return @[
             @"org.alfresco.documentlibrary.file-added",
             @"org.alfresco.documentlibrary.file-created",
             @"org.alfresco.documentlibrary.file-deleted",
             @"org.alfresco.documentlibrary.file-updated",
             @"org.alfresco.documentlibrary.file-liked",
             @"org.alfresco.comments.comment-created",
             @"org.alfresco.comments.comment-updated"
             ];
}

/*
 * Retrieve and Set Avatar For Person
 */
- (void)retrieveAvatar
{
    [self.personService retrievePersonWithIdentifier:self.activity.createdBy completionBlock:^(AlfrescoPerson *person, NSError *error) {
        
        [self.personService retrieveAvatarForPerson:person completionBlock:^(AlfrescoContentFile *contentFile, NSError *error) {
            
            if (!error)
            {
                AlfrescoFileManager *shareManager = [AlfrescoFileManager sharedManager];
                
                self.activityIcon = [UIImage imageWithData:[shareManager dataWithContentsOfURL:contentFile.fileUrl]];
                [self replaceActivityCellImageViewIconWithIcon:self.activityIcon];
            }
        }];
    }];
}

- (void)replaceActivityCellImageViewIconWithIcon:(UIImage *)icon
{
    if (icon)
    {
        self.activityCell.avatar.image = icon;
    }
    else
    {
        self.activityCell.avatar.image = [UIImage imageNamed:@"avatar.png"];
        
        if (self.isActivityTypeDocument)
        {
            self.activityIcon = smallImageForType([self.activity.data[kActivityTitle] pathExtension]);
            self.activityCell.avatar.image = self.activityIcon;
        }
        else if (self.isActivityTypeFolder)
        {
            self.activityIcon = [UIImage imageNamed:@"folder"];
        }
        else
        {
            NSString *username = self.activity.createdBy;
            
            if (username && ![username isEqualToString:@""])
            {
                [self retrieveAvatar];
            }
        }
    }
}

@end
