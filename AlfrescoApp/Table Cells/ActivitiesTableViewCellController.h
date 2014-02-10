//
//  ActivitiesTableViewCellController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>
@class AlfrescoActivityEntry;
@class AlfrescoDocument;
@class AlfrescoDocumentFolderService;
@class ActivityTableViewCell;

@protocol AlfrescoSession;

NSString * const kActivityCellIdentifier;
NSString * const kActivityNodeRef;

@interface ActivitiesTableViewCellController : NSObject

@property (nonatomic, strong) AlfrescoActivityEntry *activity;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, assign) BOOL isActivityTypeDocument;
@property (nonatomic, strong) AlfrescoDocument *activityDocument;

- (ActivityTableViewCell *)createActivityTableViewCellInTableView:(UITableView *)tableView;
- (UITableViewCell *)createActivityErrorTableViewCellInTableView:(UITableView *)tableView;
- (CGFloat)heightForCellAtIndexPath:(NSIndexPath *)indexPath inTableView:(UITableView *)tableView withSections:(NSArray *)sections;

- (id)initWithSession:(id<AlfrescoSession>)session;

@end
