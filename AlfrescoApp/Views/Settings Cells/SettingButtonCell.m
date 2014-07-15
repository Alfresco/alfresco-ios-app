//
//  SettingButtonCell.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 14/07/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "SettingButtonCell.h"
#import "SettingConstants.h"

@interface SettingButtonCell ()

@property (nonatomic, weak) IBOutlet UIButton *cellButton;

@end

@implementation SettingButtonCell

- (void)updateCellForCellInfo:(NSDictionary *)cellInfo value:(id)cellValue delegate:(id<SettingsCellProtocol>)delegate
{
    [super updateCellForCellInfo:cellInfo value:cellValue delegate:delegate];
    
    NSString *cellTitle = NSLocalizedString([cellInfo objectForKey:kSettingsCellLocalizedTitleKey], @"Cell text");
    [self.cellButton setTitle:cellTitle forState:UIControlStateNormal];
}

- (IBAction)didPressButton:(id)sender
{
    [self.delegate valueDidChangeForCell:self preferenceIdentifier:self.preferenceIdentifier value:nil];
}

@end
