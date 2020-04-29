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

#import "MDMLaunchViewController.h"

@interface MDMLaunchViewController ()

@property (nonatomic, weak) IBOutlet UILabel *errorTextLabel;
@property (nonatomic, strong) NSArray *missingKeys;

@end

@implementation MDMLaunchViewController

- (instancetype)initWithMissingMDMKeys:(NSArray *)missingKeys
{
    self = [self init];
    if (self)
    {
        self.missingKeys = missingKeys;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSMutableString *missingKeysString = [NSMutableString string];
    
    [self.missingKeys enumerateObjectsUsingBlock:^(NSString *missingKey, NSUInteger idx, BOOL *stop) {
        [missingKeysString appendFormat:@"- %@\n", missingKey];
    }];
    
    NSString *errorMessage = [NSString stringWithFormat:NSLocalizedString(@"mdm.missing.keys.description", @"Missing Keys Description"), missingKeysString];
    self.errorTextLabel.text = errorMessage;
}

@end
