//
//  TextFileViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 10/12/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "TextFileViewController.h"
#import "UniversalDevice.h"
#import "UploadFormViewController.h"
#import "UIAlertView+ALF.h"

static NSString * const kTextFileMimeType = @"text/plain";

@interface TextFileViewController () <UITextViewDelegate>

@property (nonatomic, strong) AlfrescoFolder *uploadDestinationFolder;
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, weak) id<UploadFormViewControllerDelegate> uploadFormViewControllerDelegate;
@property (nonatomic, weak) UITextView *textView;

@end

@implementation TextFileViewController

- (instancetype)initWithUploadFileDestinationFolder:(AlfrescoFolder *)uploadFolder session:(id<AlfrescoSession>)session delegate:(id<UploadFormViewControllerDelegate>)delegate
{
    self = [self init];
    if (self)
    {
        self.uploadDestinationFolder = uploadFolder;
        self.session = session;
        self.uploadFormViewControllerDelegate = delegate;
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
    
    NSDictionary *views = NSDictionaryOfVariableBindings(textView);
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[textView]|" options:NSLayoutFormatAlignAllTop | NSLayoutFormatAlignAllBottom metrics:nil views:views]];
    [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[textView]|" options:NSLayoutFormatAlignAllBaseline metrics:nil views:views]];

    view.autoresizesSubviews = YES;
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // configure
    self.title = NSLocalizedString(@"createtextfile.title", @"Create Text File");
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonPressed:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    UIBarButtonItem *nextButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Next", @"Next") style:UIBarButtonItemStylePlain target:self action:@selector(nextButtonPressed:)];
    self.navigationItem.rightBarButtonItem = nextButton;
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.textView becomeFirstResponder];
    });
}

#pragma mark - Private Functions

- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)cancelButtonPressed:(id)sender
{
    void (^dismissController)(void) = ^{
        [self dismissViewControllerAnimated:YES completion:nil];
    };
    
    if (self.textView.text.length > 0)
    {
        UIAlertView *confirmationAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"createtextfile.dismiss.confirmation.title", @"Discard Title")
                                                                    message:NSLocalizedString(@"createtextfile.dismiss.confirmation.message", @"Discard Message")
                                                                   delegate:self
                                                          cancelButtonTitle:NSLocalizedString(@"Yes", @"Yes")
                                                          otherButtonTitles:NSLocalizedString(@"No", @"No"), nil];
        [confirmationAlert showWithCompletionBlock:^(NSUInteger buttonIndex, BOOL isCancelButton) {
            if (isCancelButton)
            {
                dismissController();
            }
        }];
    }
    else
    {
        dismissController();
    }
}

- (void)nextButtonPressed:(id)sender
{
    NSData *textData = [self.textView.text dataUsingEncoding:NSUTF8StringEncoding];
    
    AlfrescoContentFile *contentFile = [[AlfrescoContentFile alloc] initWithData:textData mimeType:kTextFileMimeType];
    
    UploadFormViewController *uploadFormController = [[UploadFormViewController alloc] initWithSession:self.session uploadContentFile:contentFile inFolder:self.uploadDestinationFolder uploadFormType:UploadFormTypeDocument delegate:self.uploadFormViewControllerDelegate];
    [self.navigationController pushViewController:uploadFormController animated:YES];
}

#pragma mark - Keyboard Managment

- (void)keyboardWasShown:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    CGRect keyboardRectForScreen = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    
    UIEdgeInsets textViewInsets = self.textView.contentInset;
    textViewInsets.bottom = [self calculateBottomInsetForTextViewUsingKeyboardFrame:keyboardRectForScreen];
    self.textView.contentInset = textViewInsets;
    self.textView.scrollIndicatorInsets = textViewInsets;
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    [UIView animateWithDuration:0.3 animations:^{
        UIEdgeInsets textViewInsets = self.textView.contentInset;
        textViewInsets.bottom = 0.0f;
        self.textView.contentInset = textViewInsets;
        self.textView.scrollIndicatorInsets = textViewInsets;
    }];
}

- (CGFloat)calculateBottomInsetForTextViewUsingKeyboardFrame:(CGRect)keyboardFrame
{
    CGRect keyboardRectForView = [self.view convertRect:keyboardFrame fromView:self.view.window];
    CGSize kbSize = keyboardRectForView.size;
    UIView *mainAppView = [[UniversalDevice revealViewController] view];
    CGRect viewFrame = self.view.frame;
    CGRect viewFrameRelativeToMainController = [self.view convertRect:viewFrame toView:mainAppView];
    
    return (viewFrameRelativeToMainController.origin.y + viewFrame.size.height) - (mainAppView.frame.size.height - kbSize.height);
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

//
// http://craigipedia.blogspot.ca/2013/09/last-lines-of-uitextview-may-scroll.html
//
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    [textView scrollRangeToVisible:range];
    
    if ([text isEqualToString:@"\n"])
    {
        [UIView animateWithDuration:0.2 animations:^{
            [textView setContentOffset:CGPointMake(textView.contentOffset.x, textView.contentOffset.y + 20)];
        }];
    }
    
    return YES;
}

@end
