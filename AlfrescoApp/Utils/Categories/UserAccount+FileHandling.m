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

#import "UserAccount+FileHandling.h"

@implementation UserAccount (FileHandling)

- (BOOL)serverConfigurationExists
{
    NSString *configurationFilePath = [self configurationFilePath];
    return [[AlfrescoFileManager sharedManager] fileExistsAtPath:configurationFilePath];
}

- (NSString *)configurationFilePath
{
    NSString *accountSpecificConfigurationFolderPath = [self accountSpecificConfigurationFolderPath];
    NSString *configurationFilePath = [accountSpecificConfigurationFolderPath stringByAppendingPathComponent:kAlfrescoEmbeddedConfigurationFileName];
    return configurationFilePath;
}

- (NSString *)accountSpecificConfigurationFolderPath
{
    AlfrescoFileManager *fileManager = [AlfrescoFileManager sharedManager];
    NSString *accountIdentifier = self.accountIdentifier;
    NSString *accountSpecificFolderPath = [[fileManager defaultConfigurationFolderPath] stringByAppendingPathComponent:accountIdentifier];
    
    if (![fileManager fileExistsAtPath:accountSpecificFolderPath])
    {
        NSError *createError = nil;
        [fileManager createDirectoryAtPath:accountSpecificFolderPath withIntermediateDirectories:YES attributes:nil error:&createError];
        
        if (createError)
        {
            AlfrescoLogError(@"Unable to create folder at path: %@", accountSpecificFolderPath);
        }
    }
    
    return accountSpecificFolderPath;
}

- (void)deleteSpecificConfigurationFolder
{
    AlfrescoFileManager *fileManager = [AlfrescoFileManager sharedManager];
    NSString *accountIdentifier = self.accountIdentifier;
    NSString *accountConfigurationFolderPath = [[fileManager defaultConfigurationFolderPath] stringByAppendingPathComponent:accountIdentifier];
    
    [self deleteAccountSpecificFolder:accountConfigurationFolderPath];
}

- (void)deleteSpecificSyncFolder
{
    AlfrescoFileManager *fileManager = [AlfrescoFileManager sharedManager];
    NSString *accountIdentifier = self.accountIdentifier;
    NSString *accountSyncFolderPath = [[fileManager syncFolderPath] stringByAppendingPathComponent:accountIdentifier];
    
    [self deleteAccountSpecificFolder:accountSyncFolderPath];
}

- (void)deleteAccountSpecificFolder:(NSString *)folderPath
{
    [self deleteItemAtPath:folderPath withErrorFormat:@"Unable to delete folder at path: %@"];
}

- (void)deleteConfigurationFile
{
    NSString *configurationFilePath = [self configurationFilePath];
    [self deleteItemAtPath:configurationFilePath withErrorFormat:@"Unable to delete file at path: %@"];
}

- (void)deleteItemAtPath:(NSString *)path withErrorFormat:(NSString *)errorFormat
{
    AlfrescoFileManager *fileManager = [AlfrescoFileManager sharedManager];
    
    if ([fileManager fileExistsAtPath:path])
    {
        NSError *deleteError = nil;
        [fileManager removeItemAtPath:path error:&deleteError];
        
        if (deleteError)
        {
            AlfrescoLogError(errorFormat, path);
        }
    }
}

@end
