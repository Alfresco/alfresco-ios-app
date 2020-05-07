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

#import "ConfigurationFilesUtils.h"
#import "UserAccount+FileHandling.h"

@implementation ConfigurationFilesUtils

+ (NSString *)fileNameForConfigurationFileType:(ConfigurationFileType)configurationFileType
{
    NSString *fileName = nil;
    
    switch (configurationFileType)
    {
        case ConfigurationFileTypeEmbedded:
        case ConfigurationFileTypeLocal:
            fileName = kAlfrescoEmbeddedConfigurationFileName;
            break;
            
        case ConfigurationFileTypeNoAccounts:
            fileName = kAlfrescoNoAccountConfigurationFileName;
            
        default:
            break;
    }
    
    return fileName;
}

+ (NSString *)filePathForConfigurationFileType:(ConfigurationFileType)configurationFileType
{
    NSString *fileName = [ConfigurationFilesUtils fileNameForConfigurationFileType:configurationFileType];
    
    return [[[AlfrescoFileManager sharedManager] defaultConfigurationFolderPath] stringByAppendingPathComponent:fileName];
}

+ (void)setupConfigurationFileType:(ConfigurationFileType)configurationFileType completionBlock:(void (^)(NSString *configurationFilePath))completionBlock
{
    AlfrescoFileManager *fileManager = [AlfrescoFileManager sharedManager];
    
    // File location to the configuration file
    NSString *completeDestinationPath = [ConfigurationFilesUtils filePathForConfigurationFileType:configurationFileType];
    
    NSString *currentVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSString *versionOfLastRun = [[NSUserDefaults standardUserDefaults] objectForKey:kVersionOfLastRun];
    
    if (versionOfLastRun == nil || [versionOfLastRun isEqual:currentVersion] == NO)
    {
        // First run after installing or the app was updated since last run.
        // Delete current embedded config file if exists in order to use the new version embedded config file from the bundle.
        if ([fileManager fileExistsAtPath:completeDestinationPath])
        {
            NSError *deleteError = nil;
            [fileManager removeItemAtPath:completeDestinationPath error:&deleteError];
            
            if (deleteError)
            {
                AlfrescoLogError(@"Unable to remove file at path: %@", completeDestinationPath);
            }
        }
        
        [[NSUserDefaults standardUserDefaults] setObject:currentVersion forKey:kVersionOfLastRun];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    if (![fileManager fileExistsAtPath:completeDestinationPath])
    {
        NSString *configFileName = [ConfigurationFilesUtils fileNameForConfigurationFileType:configurationFileType];
        NSString *fileLocationInBundle = [[NSBundle mainBundle] pathForResource:configFileName.stringByDeletingPathExtension ofType:configFileName.pathExtension];
        NSError *copyError = nil;
        
        [fileManager copyItemAtPath:fileLocationInBundle toPath:completeDestinationPath error:&copyError];
        
        if (copyError)
        {
            AlfrescoLogError(@"Unable to copy file from path: %@, to path: %@", fileLocationInBundle, completeDestinationPath);
        }
    }
    
    if (completionBlock != NULL)
    {
        completionBlock(completeDestinationPath);
    }
}

+ (BOOL)configServiceShouldIgnoreRequestsForType:(ConfigurationFileType)configurationFileType
{
    BOOL shouldIgnoreRequests = NO;
    
    switch (configurationFileType)
    {
        case ConfigurationFileTypeEmbedded:
            shouldIgnoreRequests = YES;
            break;
            
        case ConfigurationFileTypeLocal:
            shouldIgnoreRequests = YES;
            break;
            
        case ConfigurationFileTypeServer:
            shouldIgnoreRequests = NO;
            break;
            
        default:
            break;
    }
    
    return shouldIgnoreRequests;
}

+ (void)logDefaultProfileError:(NSError *)error forConfigurationWithType:(ConfigurationFileType)configurationFileType
{
    NSString *errorStringFormat = nil;
    
    switch (configurationFileType)
    {
        case ConfigurationFileTypeLocal:
            errorStringFormat = @"Could not retrieve the default local profile: %@";
            break;
            
        case ConfigurationFileTypeEmbedded:
            errorStringFormat = @"Could not retrieve the default embedded profile: %@";
            break;
            
        case ConfigurationFileTypeNoAccounts:
            errorStringFormat = @"Could not retrieve the default profile from no accounts configuration: %@";
            break;
            
        case ConfigurationFileTypeServer:
            errorStringFormat = @"Could not retrieve the default profile from server: %@";
            break;
            
        default:
            break;
    }
    
    AlfrescoLogWarning(errorStringFormat, error.localizedDescription);
}

+ (void)logCustomProfile:(NSString *)profileIdentifier error:(NSError *)error
{
    AlfrescoLogWarning(@"Could not retrieve the profile with identifier: %@ from server: %@", profileIdentifier, error.localizedDescription);
}

@end
