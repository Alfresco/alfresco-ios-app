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

static NSInteger const kTodoRowNumber = 0;
static NSInteger const kReviewAndApproveRowNumber = 1;

static CGFloat const kTaskTypeFooterHeight = 28.0f;

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
    
    if (indexPath.section == kTodoRowNumber)
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
    WorkflowType type = indexPath.section == 0 ? WorkflowTypeTodo : WorkflowTypeReview;
    CreateTaskViewController *createTaskViewController = [[CreateTaskViewController alloc] initWithSession:self.session workflowType:type];
    [self.navigationController pushViewController:createTaskViewController animated:YES];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectZero];
    [footerView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth];
    
    UILabel *footerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    footerLabel.numberOfLines = 0;
    footerLabel.backgroundColor = self.tableView.backgroundColor;
    footerLabel.textAlignment = NSTextAlignmentCenter;
    footerLabel.textColor = [UIColor colorWithRed:76.0/255.0f green:86.0/255.0f blue:108.0/255.0f alpha:1.0f];
    footerLabel.font = [UIFont systemFontOfSize:15];
    [footerLabel setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
    
    if (section == kTodoRowNumber)
    {
        footerLabel.text = NSLocalizedString(@"task.type.workflow.todo.footer", @"Adhoc task description.");
    }
    else if (section == kReviewAndApproveRowNumber)
    {
        footerLabel.text = NSLocalizedString(@"task.type.workflow.review.and.approve.footer", @"Review and approve task description.");
    }
    
    [footerLabel sizeToFit];
    [footerView addSubview:footerLabel];
    
    return footerLabel;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return kTaskTypeFooterHeight;
}

@end
