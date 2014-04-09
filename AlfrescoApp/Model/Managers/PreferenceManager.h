//
//  PreferenceManager.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 26/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SettingConstants.h"

@interface PreferenceManager : NSObject

+ (instancetype)sharedManager;

// Convenience Methods
- (BOOL)shouldSyncOnCellular;
- (BOOL)shouldSendDiagnostics;

// Accessors and Modifiers
- (id)preferenceForIdentifier:(NSString *)preferenceIdentifier;
- (void)updatePreferenceToValue:(id)obj preferenceIdentifier:(NSString *)preferenceIdentifier;

@end
