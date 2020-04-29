/*******************************************************************************
 * Copyright (C) 2005-2020 Alfresco Software Limited.
 * 
 * This file is part of the Alfresco Mobile iOS App.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *  
 *  http://www.apache.org/licenses/LICENSE-2.0
 * 
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 ******************************************************************************/
 
#import "TaskTypeViewController.h"
#import "CreateTaskViewController.h"
#import "WorkflowHelper.h"

static NSString * const kTaskTypeCellIdentifier = @"TaskTypeCellIdentifier";

static NSInteger const kNumberOfSections = 2;
static NSInteger const kNumberOfRowsInSection = 1;

static NSInteger const kSectionNumberAdHoc = 0;

@interface TaskTypeViewController ()
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@end

@implementation TaskTypeViewController

- (instancetype)initWithSession:(id<AlfrescoSession>)session
{
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil];
    if (self)
    {
        _session = session;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"task.choose.task.type.title", @"Choose Task Type");
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRefreshed:) name:kAlfrescoSessionRefreshedNotification object:nil];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                  target:self
                                                                                  action:@selector(cancelButtonTapped:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kTaskTypeCellIdentifier];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[AnalyticsManager sharedManager] trackScreenWithName:kAnalyticsViewTaskCreateType];
}

- (void)cancelButtonTapped:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dealloc
{
    _tableView.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)sessionRefreshed:(NSNotification *)notification
{
    self.session = notification.object;
}

#pragma mark - TableView Delegate and Datasource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kNumberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return kNumberOfRowsInSection;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTaskTypeCellIdentifier];
    
    if (indexPath.section == kSectionNumberAdHoc)
    {
        cell.textLabel.text = NSLocalizedString(@"task.type.workflow.todo", @"Todo");
    }
    else
    {
        cell.textLabel.text = NSLocalizedString(@"task.type.workflow.review.and.approve", @"Review & Approve");
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    WorkflowType type = indexPath.section == 0 ? WorkflowTypeAdHoc : WorkflowTypeReview;
    CreateTaskViewController *createTaskViewController = [[CreateTaskViewController alloc] initWithSession:self.session workflowType:type];
    [self.navigationController pushViewController:createTaskViewController animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == kSectionNumberAdHoc)
    {
        return NSLocalizedString(@"task.type.workflow.todo.footer", @"Adhoc task description.");
    }
    return NSLocalizedString(@"task.type.workflow.review.and.approve.footer", @"Review and approve task description.");
}

@end
