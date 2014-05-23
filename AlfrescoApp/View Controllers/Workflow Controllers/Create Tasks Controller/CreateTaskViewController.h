//
//  CreateTaskViewController.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 20/03/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "WorkflowHelper.h"
#import "NodePicker.h"
#import "PeoplePicker.h"
#import "DatePickerViewController.h"

@interface CreateTaskViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, NodePickerDelegate, PeoplePickerDelegate, DatePickerViewControllerDelegate>

- (instancetype)initWithSession:(id<AlfrescoSession>)session workflowType:(WorkflowType)workflowType;
- (instancetype)initWithSession:(id<AlfrescoSession>)session workflowType:(WorkflowType)workflowType attachments:(NSArray *)attachments;

@end
