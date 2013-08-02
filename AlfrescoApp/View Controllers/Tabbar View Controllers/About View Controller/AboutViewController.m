//
//  AboutViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "AboutViewController.h"
#import "LicenseViewController.h"
#import "UniversalDevice.h"
#import <QuartzCore/QuartzCore.h>
#import "NavigationViewController.h"

@interface AboutViewController ()

@property (strong, nonatomic) NSDictionary *thirdPartyLibrariesWithLicenseFileNames;
@property (strong, nonatomic) NSArray *thirdPartyLibraryNames;
@property (assign, nonatomic) CGFloat librariesBottomEdge;

@end

@implementation AboutViewController

- (id)init
{
    self = [super init];
    if (self)
    {
        self.title = NSLocalizedString(@"about.title", @"About Title");
        [self loadThirdPartyLibraries];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.view addSubview:self.contentView];
    
    // About text
    self.aboutTextView.text = NSLocalizedString(@"about.content", @"Main about text block");
    
    // Libraries title
    self.librariesLabel.text = NSLocalizedString(@"about.libraries.used", "Libraries used:");
    
    // Generate library buttons
    self.librariesBottomEdge = [self listLibraries];
    
    // Version and Build Info
    self.versionNumberLabel.text = [NSString stringWithFormat:NSLocalizedString(@"about.version.number", @"Version: %@ (%@)"),
                                    [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                    [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
    
    self.buildDateLabel.text = [NSString stringWithFormat:NSLocalizedString(@"about.build.date.time", @"Build Date: %s %s"), __DATE__, __TIME__];
}

- (void)viewWillLayoutSubviews
{
    [self calculateViewLayouts];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self calculateViewLayouts];
}

- (void)calculateViewLayouts
{
    CGRect aboutTextRect = self.aboutTextView.frame;
    aboutTextRect.size.height = self.aboutTextView.contentSize.height;
    self.aboutTextView.frame = aboutTextRect;
    
    CGRect librariesLabelRect = self.librariesLabel.frame;
    librariesLabelRect.origin.y = aboutTextRect.origin.y + aboutTextRect.size.height + 22.0;
    self.librariesLabel.frame = librariesLabelRect;

    CGRect librariesContainerRect = self.librariesContainerView.frame;
    librariesContainerRect.origin.y = self.librariesLabel.frame.origin.y + self.librariesLabel.frame.size.height + 8.0;
    librariesContainerRect.size.height = self.librariesBottomEdge;
    self.librariesContainerView.frame = librariesContainerRect;

    CGRect versionRect = self.versionInfoView.frame;
    versionRect.origin.y = self.librariesContainerView.frame.origin.y + self.librariesContainerView.frame.size.height + 22.0;
    self.versionInfoView.frame = versionRect;
    
    // Adjust contentView's frame to the correct height
    CGRect contentRect = self.contentView.frame;
    contentRect.size.height = self.versionInfoView.frame.origin.y + self.versionInfoView.frame.size.height + 8.0;
    self.contentView.frame = contentRect;

    [(UIScrollView *)self.view setContentSize:CGSizeMake(self.view.frame.size.width, self.contentView.frame.size.height)];
}

#pragma mark - Private Functions

- (void)loadThirdPartyLibraries
{
    NSDictionary *infoPlist = [[NSBundle mainBundle] infoDictionary];
    self.thirdPartyLibrariesWithLicenseFileNames = [infoPlist objectForKey:kLicenseDictionaries];
    self.thirdPartyLibraryNames = [[self.thirdPartyLibrariesWithLicenseFileNames allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2)
    {
        return [obj1 compare:obj2 options:NSCaseInsensitiveSearch];
    }];
}

- (CGFloat)listLibraries
{
    int numOfColumns = 1;
    float textSize = 12.0f;
    int x, y = 0;
    
    // iPad specific config
    if (IS_IPAD)
    {
        numOfColumns = 3;
    }
    
    int buttonWidth = self.librariesContainerView.frame.size.width / numOfColumns;
    int buttonHeight = 44.0f;
    
    for (int i = 0; i < self.thirdPartyLibraryNames.count; i++)
    {
        if (i % numOfColumns == 0)
        {
            x = 0;
            if (i != 0)
            {
                y += buttonHeight;
            }
        }
        else
        {
            x += buttonWidth;
        }
        
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(x, y, buttonWidth, buttonHeight)];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button setTitle:[self.thirdPartyLibraryNames objectAtIndex:i] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont boldSystemFontOfSize:textSize];
        button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        button.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [button addTarget:self action:@selector(libraryButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.librariesContainerView addSubview:button];
    }
    
    return y + buttonHeight;
}

- (void)libraryButtonPressed:(id)sender
{
    UIButton *pressedButton = (UIButton *)sender;

    LicenseViewController *licenseViewController = [[LicenseViewController alloc] initWithLibraryName:pressedButton.titleLabel.text];
    NavigationViewController *controller = [[NavigationViewController alloc] initWithRootViewController:licenseViewController];
    
    [UniversalDevice displayModalViewController:controller onController:self.navigationController withCompletionBlock:nil];
}

- (void)viewDidUnload {
    [self setAboutTextView:nil];
    [self setLibrariesLabel:nil];
    [super viewDidUnload];
}
@end
