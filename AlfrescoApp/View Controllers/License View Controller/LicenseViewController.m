//
//  LicenseViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "LicenseViewController.h"

@interface LicenseViewController ()
@property (nonatomic, strong) NSString *libraryToDisplay;
@property (nonatomic, strong) UITextView *licenseTextView;
@end

@implementation LicenseViewController

- (id)initWithLibraryName:(NSString *)libraryName
{
    self = [super init];
    if (self)
    {
        _libraryToDisplay = libraryName;
    }
    return self;
}

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    view.backgroundColor = [UIColor whiteColor];
    
    // Title
    self.navigationItem.title = _libraryToDisplay;
    
    // Text view
    UITextView *licenseTextView = [[UITextView alloc] initWithFrame:view.frame];
    self.licenseTextView = licenseTextView;
    licenseTextView.editable = NO;
    licenseTextView.backgroundColor = [UIColor clearColor];
    licenseTextView.textColor = [UIColor darkTextColor];

    // Load the licence file's content
    NSString *path = [self retrievePathForLibraryName:_libraryToDisplay];
    NSString *licenseText = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    licenseTextView.text = licenseText;
    licenseTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [view addSubview:licenseTextView];
    
    view.autoresizesSubviews = YES;
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismiss:)];
    self.navigationItem.rightBarButtonItem = doneButton;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.licenseTextView setContentOffset:CGPointMake(0, 0) animated:NO];
}

#pragma mark - Private Functions

- (NSString *)retrievePathForLibraryName:(NSString *)libraryName
{
    NSDictionary *infoPlist = [[NSBundle mainBundle] infoDictionary];
    NSDictionary *libraries = [infoPlist objectForKey:kLicenseDictionaries];
    NSString *libraryFileName = [[libraries objectForKey:libraryName] stringByDeletingPathExtension];
    return [[NSBundle mainBundle] pathForResource:libraryFileName ofType:@".txt"];
}

- (void)dismiss:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:NULL];
}

@end
