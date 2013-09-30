//
//  SettingCell.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 25/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "SettingCell.h"
#import "SettingConstants.h"

@implementation SettingCell

- (void)updateCellForCellInfo:(NSDictionary *)cellInfo value:(id)cellValue delegate:(id<SettingsCellProtocol>)delegate
{
    self.preferenceIdentifier = [cellInfo objectForKey:kSettingsCellPerferenceIdentifier];
    NSString *cellTitle = NSLocalizedString([cellInfo objectForKey:kSettingsCellLocalizedTitleKey], @"Cell text");
    self.cellTitle.text = cellTitle;
    self.delegate = delegate;
}

@end
