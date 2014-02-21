//
//  TasksCell.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 17/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TasksCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *taskNameTextLabel;
@property (nonatomic, weak) IBOutlet UILabel *taskDueDateTextLabel;

+ (CGFloat)minimumCellHeight;
- (void)setPriorityLevel:(NSNumber *)priorty;

@end
