//
//  SettingToggleCell.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 25/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "SettingToggleCell.h"

@interface SettingToggleCell ()

@property (nonatomic, weak) IBOutlet UISwitch *toggle;

- (IBAction)switchToggled:(id)sender;

@end

@implementation SettingToggleCell

- (void)updateCellForCellInfo:(NSDictionary *)cellInfo value:(id)cellValue delegate:(id<SettingsCellProtocol>)delegate
{
    [super updateCellForCellInfo:cellInfo value:cellValue delegate:delegate];

    if ([cellValue isKindOfClass:[NSNumber class]])
    {
        BOOL isOn = [(NSNumber *)cellValue boolValue];
        [self.toggle setOn:isOn animated:NO];
    }
    else
    {
        @throw ([NSException exceptionWithName:@"Invalue cell value"
                                        reason:[NSString stringWithFormat:@"Invaild cell value in class %@", NSStringFromClass([self class])]
                                      userInfo:nil]);
    }
}

- (IBAction)switchToggled:(id)sender
{
    NSNumber *isOn = [NSNumber numberWithBool:[self.toggle isOn]];
    [self.delegate valueDidChangeForCell:self perferenceIdentifier:self.preferenceIdentifier value:isOn];
}

@end
