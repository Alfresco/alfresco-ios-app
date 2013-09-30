//
//  SettingsCellProtocol.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 25/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SettingCell;

@protocol SettingsCellProtocol <NSObject>

- (void)valueDidChangeForCell:(SettingCell *)cell perferenceIdentifier:(NSString *)preferenceIdentifier value:(id)value;

@end
