//
//  ActivitiesTableViewCellController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "ActivitiesTableViewCellController.h"
#import "AlfrescoDocumentFolderService.h"
#import "AlfrescoPersonService.h"
#import "ActivityTableViewCell.h"
#import "AlfrescoActivityEntry.h"
#import "AlfrescoFileManager.h"
#import "Utility.h"

NSString * const kActivityCellIdentifier = @"ActivityCell";

NSString * const kActivityTitle = @"title";
NSString * const kActivityNodeRef = @"nodeRef";
NSString * const kActivityFirstName = @"firstName";
NSString * const kActivityLastName = @"lastName";
NSString * const kActivityUserFirstName = @"userFirstName";
NSString * const kActivityUserLastName = @"userLastName";
NSString * const kActivityMemberUserName = @"memberUserName";
NSString * const kActivityRole = @"role";
NSString * const kActivityStatus = @"status";
NSString * const kActivityPage = @"page";

static CGFloat const kBoldTextFontSize = 17;

#define CONST_Cell_height 44.0f
#define CONST_textLabelFontSize 17
#define CONST_detailLabelFontSize 14
#define CONST_Cell_imageView_width 32.0f
#define CONST_Cell_imageView_height 32.0f
#define CONST_Cell_titleMaxWidth 320.0f

@interface ActivitiesTableViewCellController ()

@property (nonatomic, strong) AlfrescoPersonService *personService;
@property (nonatomic, strong) ActivityTableViewCell *activityCell;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *cellTitle;
@property (nonatomic, strong) NSString *cellSubTitle;
@property (nonatomic, strong) NSString *replacedActivityText;
@property (nonatomic, assign) UITableViewCellAccessoryType accesoryType;
@property (nonatomic, strong) NSMutableAttributedString *mutableString;
@property (nonatomic, strong) UIImage *activityIcon;
@property (nonatomic, assign) CGFloat cellHeight;

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

- (UIFont *)cellSubTitleFont
{
	return [UIFont italicSystemFontOfSize:CONST_detailLabelFontSize];
}

- (UIFont *)cellTitleFont
{
	return [UIFont boldSystemFontOfSize:CONST_textLabelFontSize];
}

- (void)setActivity:(AlfrescoActivityEntry *)activity
{
    _activity = activity;
    self.title = activity.data[kActivityTitle];
    self.cellTitle = [self activityText];
    self.cellSubTitle = [NSString stringWithFormat:@"%@", self.activity.createdAt];
}

- (ActivityTableViewCell *)createActivityCell
{
    ActivityTableViewCell *cell = [[ActivityTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kActivityCellIdentifier];
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.font = [self cellTitleFont];
    
    cell.detailTextLabel.numberOfLines = 0;
    cell.detailTextLabel.font = [self cellSubTitleFont];
    
    return cell;
}

- (void)populateActivityCell:(ActivityTableViewCell *)cell
{
    cell.textLabel.text = self.cellTitle;
    cell.textLabel.highlightedTextColor = [UIColor whiteColor];
	cell.detailTextLabel.text = relativeDateFromDate(self.activity.createdAt);
    cell.detailTextLabel.highlightedTextColor = [UIColor whiteColor];
    
    [self replaceActivityCellImageViewIconWithIcon:self.activityIcon];
    
    cell.summaryLabel.highlightedTextColor = [UIColor whiteColor];
    
    if (self.isActivityTypeDocument && self.activity.data[kActivityNodeRef] != nil && ![self.activity.type hasSuffix:@"-deleted"])
    {
        UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
        [infoButton addTarget:self action:@selector(accessoryButtonTapped:withEvent:) forControlEvents:UIControlEventTouchUpInside];
        
        cell.accessoryView = infoButton;
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.accessoryView = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
}

- (UITableViewCell *)createActivityTableViewCellInTableView:(UITableView *)tableView
{
    ActivityTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kActivityCellIdentifier];
	if (cell == nil)
	{
		cell = [self createActivityCell];
	}
    
    self.activityCell = cell;
    
    [cell.summaryLabel setText:self.cellTitle afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString)
    {
        mutableAttributedString = [self boldReplacements:[self textReplacements] inString:mutableAttributedString];
        return mutableAttributedString;
    }];
    
    self.isActivityTypeDocument = [[self activityDocumentType] containsObject:self.activity.type] && [self.activity.data[kActivityPage] hasPrefix:@"document-details"];
    
    [self populateActivityCell:cell];
    
    return cell;
}

- (UITableViewCell *)createActivityErrorTableViewCellInTableView:(UITableView *)tableView 
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ErrorCell"];
    
    cell.textLabel.text = NSLocalizedString(@"activities.empty", @"No activities Available");
    cell.imageView.image = nil;
    
    return cell;
}

- (CGFloat)heightForCellAtIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *)tableView
{
    return [self heightForCellWithMaxWidth:CONST_Cell_titleMaxWidth];
}

- (void)accessoryButtonTapped:(UIControl *)button withEvent:(UIEvent *)event
{
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:[[[event touchesForView:button] anyObject] locationInView:self.tableView]];
    if (indexPath != nil)
    {
        [self.tableView.delegate tableView:self.tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
    }
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

- (NSMutableAttributedString *)boldReplacements:(NSArray *)replacements inString:(NSMutableAttributedString *)attributed
{
    if (!self.mutableString)
    {
        UIFont *boldSystemFont = [UIFont boldSystemFontOfSize:kBoldTextFontSize];
        CTFontRef boldFont = CTFontCreateWithName((__bridge CFStringRef)boldSystemFont.fontName, boldSystemFont.pointSize, NULL);
        
        for (NSInteger index = 0; index < replacements.count; index++)
        {
            NSString *replacement = replacements[index];
            NSRange replacementRange = [attributed.string rangeOfString:replacement];
            
            if (replacementRange.length > 0 && boldFont)
            {
                [attributed addAttribute:(NSString *)kCTFontAttributeName value:(__bridge id)boldFont range:replacementRange];
            }
        }
        
        if (boldFont)
        {
            CFRelease(boldFont);
        }
        self.mutableString = attributed;
    }
    
    return self.mutableString;
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

- (CGFloat)heightForCellWithMaxWidth:(CGFloat)maxWidth
{
    if (self.cellHeight < CONST_Cell_height)
    {
        CGFloat maxHeight = 4000;
        
        //Remove padding, etc
        maxWidth -= 80.0f;
        
        CGSize titleSize    = {0.0f, 0.0f};
        CGSize subtitleSize = {0.0f, 0.0f};
        
        if (self.accesoryType != UITableViewCellAccessoryNone)
        {
            maxWidth -= 20.0f;
        }
        
        if (self.cellTitle && ![self.cellTitle isEqualToString:@""])
        {
            titleSize = [self.cellTitle sizeWithFont:[UIFont boldSystemFontOfSize:CONST_textLabelFontSize]
                               constrainedToSize:CGSizeMake(maxWidth, maxHeight)
                                   lineBreakMode:NSLineBreakByWordWrapping];
        }
        
        if (self.cellSubTitle && ![self.cellSubTitle isEqualToString:@""])
        {
            subtitleSize = [self.cellSubTitle sizeWithFont:[self cellSubTitleFont]
                                     constrainedToSize:CGSizeMake(maxWidth, maxHeight)
                                         lineBreakMode:NSLineBreakByWordWrapping];
        }
        
        int height = 25 + titleSize.height + subtitleSize.height;
        CGFloat myCellHeight = (height < CONST_Cell_height ? CONST_Cell_height : height);

        self.cellHeight = myCellHeight;
        
        return myCellHeight;
    }
    else
    {
        return self.cellHeight;
    }
}

/*
 * Retrieve and Set Avatar For Person
 */
- (void)retrieveAvatar
{
    [self.personService retrievePersonWithIdentifier:self.activity.data[kActivityMemberUserName] completionBlock:^(AlfrescoPerson *person, NSError *error) {
        
        [self.personService retrieveAvatarForPerson:person completionBlock:^(AlfrescoContentFile *contentFile, NSError *error) {
            
            if (!error)
            {
                AlfrescoFileManager *shareManager = [AlfrescoFileManager sharedManager];
                
                UIImage *image = [UIImage imageWithData:[shareManager dataWithContentsOfURL:contentFile.fileUrl]];
                
                self.activityIcon = resizeImage(image, CGSizeMake(CONST_Cell_imageView_width, CONST_Cell_imageView_height));
                [self replaceActivityCellImageViewIconWithIcon:self.activityIcon];
            }
        }];
    }];
}

- (void)replaceActivityCellImageViewIconWithIcon:(UIImage *)icon
{
    if (icon)
    {
        self.activityCell.imageView.image = icon;
    }
    else
    {
        self.activityCell.imageView.image = [UIImage imageNamed:@"avatar.png"];
        
        if (self.isActivityTypeDocument)
        {
            self.activityIcon = imageForType([self.activity.data[kActivityTitle] pathExtension]);
            self.activityCell.imageView.image = self.activityIcon;
        }
        else
        {
            NSString *memberUsername = self.activity.data[kActivityMemberUserName];
            
            if (memberUsername && ![memberUsername isEqualToString:@""])
            {
                [self retrieveAvatar];
            }
        }
    }
}

@end
