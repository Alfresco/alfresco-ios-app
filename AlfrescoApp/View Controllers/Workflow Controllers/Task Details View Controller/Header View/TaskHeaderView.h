//
//  TaskHeaderView.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 24/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TaskHeaderView : UIView

@property (nonatomic, strong) NSString *taskInitiator;

- (void)updateTaskFilterLabelToString:(NSString *)taskTypeString;
- (void)configureViewForProcess:(AlfrescoWorkflowProcess *)process;
- (void)configureViewForTask:(AlfrescoWorkflowTask *)task;

@end
