//
//  TaskTypeViewController.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 20/03/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

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
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                  target:self
                                                                                  action:@selector(cancelButtonTapped:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:kTaskTypeCellIdentifier];
}

- (void)cancelButtonTapped:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
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
