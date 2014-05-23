//
//  ProcessTasksCell.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 06/03/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "ThumbnailImageView.h"

@interface ProcessTasksCell : UITableViewCell

@property (nonatomic, weak) IBOutlet ThumbnailImageView *avatarImageView;

+ (NSString *)cellIdentifier;
- (void)updateStatusLabelUsingTask:(AlfrescoWorkflowTask *)task;

@end
