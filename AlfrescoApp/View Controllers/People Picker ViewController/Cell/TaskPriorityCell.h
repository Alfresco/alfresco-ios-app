//
//  TaskPriorityCell.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 21/03/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TaskPriorityCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UISegmentedControl *segmentControl;

@end
