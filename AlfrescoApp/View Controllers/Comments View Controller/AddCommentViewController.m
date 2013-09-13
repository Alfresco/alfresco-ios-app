//
//  AddCommentViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "AddCommentViewController.h"
#import "Utility.h"
#import "MBProgressHUD.h"
#import "ErrorDescriptions.h"

@interface AddCommentViewController ()

@property (nonatomic, strong) AlfrescoNode *node;
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, weak) id<AddCommentViewControllerDelegate> delegate;
@property (nonatomic, strong) AlfrescoCommentService *commentService;
@property (nonatomic, weak) UITextView *textView;

@end

@implementation AddCommentViewController

- (id)initWithAlfrescoNode:(AlfrescoNode *)node session:(id<AlfrescoSession>)session delegate:(id<AddCommentViewControllerDelegate>)delegate;
{
    self = [super init];
    if (self)
    {
        self.node = node;
        self.session = session;
        self.delegate = delegate;
        [self createAlfrescoServicesWithSession:session];
        [self registerForNotifications];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    UITextView *textView = [[UITextView alloc] initWithFrame:view.frame];
    textView.delegate = self;
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [view addSubview:textView];
    self.textView = textView;
    
    view.autoresizesSubviews = YES;
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"add.comments.title", @"Add Comment Title");
	
    UIBarButtonItem *postCommentButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"add.comments.post.button", @"Add Comment Button")
                                                                          style:UIBarButtonItemStyleDone
                                                                         target:self
                                                                         action:@selector(postComment:)];
    postCommentButton.enabled = NO;
    self.navigationItem.rightBarButtonItem = postCommentButton;
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.textView becomeFirstResponder];
}

#pragma mark - Private Functions

- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sessionReceived:)
                                                 name:kAlfrescoSessionReceivedNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)createAlfrescoServicesWithSession:(id<AlfrescoSession>)session
{
    self.commentService = [[AlfrescoCommentService alloc] initWithSession:session];
}

- (void)sessionReceived:(NSNotification *)notification
{
    id <AlfrescoSession> session = notification.object;
    self.session = session;
    
    [self createAlfrescoServicesWithSession:session];
    
    if (self == [self.navigationController.viewControllers lastObject])
    {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)postComment:(id)sender
{
    [self.textView resignFirstResponder];
    
    __block MBProgressHUD *postingCommentHUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:postingCommentHUD];
    [postingCommentHUD show:YES];
    
    __weak AddCommentViewController *weakkSelf = self;
    [self.commentService addCommentToNode:self.node content:self.textView.text title:nil completionBlock:^(AlfrescoComment *comment, NSError *error) {
        [postingCommentHUD hide:YES];
        postingCommentHUD = nil;
        
        if (comment)
        {
            [weakkSelf.delegate didSuccessfullyAddComment:comment];
            [weakkSelf.navigationController popViewControllerAnimated:YES];
        }
        else
        {
            displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.add.comment.failed", @"Adding Comment Failed"), [ErrorDescriptions descriptionForError:error]]);
            [Notifier notifyWithAlfrescoError:error];
            [weakkSelf.textView becomeFirstResponder];
        }
    }];
}

#pragma mark - Keyboard Managment

- (void)keyboardWasShown:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    CGRect keyboardRectForScreen = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGRect keyboardRectForView = [self.view convertRect:keyboardRectForScreen fromView:self.view.window];
    
    CGSize kbSize = keyboardRectForView.size;

    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0,
                                                  0.0,
                                                  (kbSize.height - self.tabBarController.tabBar.frame.size.height),
                                                  0.0);
    self.textView.contentInset = contentInsets;
    self.textView.scrollIndicatorInsets = contentInsets;
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    [UIView animateWithDuration:0.3 animations:^{
        UIEdgeInsets contentInsets = UIEdgeInsetsZero;
        self.textView.contentInset = contentInsets;
        self.textView.scrollIndicatorInsets = contentInsets;
    }];
}

#pragma mark - UITextViewDelegate Functions

- (void)textViewDidChange:(UITextView *)textView
{
    NSString *trimmedText = [textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([trimmedText length] > 0)
    {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    else
    {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
}

@end
