//
//  TasksCell.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 17/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TasksCell : UITableViewCell

@property (nonatomic, strong) NSNumber *priority;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSDate *dueDate;
@property (nonatomic, strong) NSString *processType;

@end
