//
//  AboutViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "AboutViewController.h"

@implementation AboutViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Title
    self.title = NSLocalizedString(@"about.title", @"About Title");
    
    // About text
    self.aboutTextView.text = NSLocalizedString(@"about.content", @"Main about text block");
    
    // Version and Build Info
    self.versionNumberLabel.text = [NSString stringWithFormat:NSLocalizedString(@"about.version.number", @"Version: %@ (%@)"),
                                    [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                                    [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]];
    
    self.buildDateLabel.text = [NSString stringWithFormat:NSLocalizedString(@"about.build.date.time", @"Build Date: %s %s"), __DATE__, __TIME__];
}

@end
