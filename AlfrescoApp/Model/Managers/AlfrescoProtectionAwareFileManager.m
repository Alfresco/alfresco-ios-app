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

#import "AlfrescoProtectionAwareFileManager.h"
#import "AccountManager.h"
#import "PreferenceManager.h"
#import "UniversalDevice.h"

static BOOL sFileProtectionEnabled = NO;

@implementation AlfrescoProtectionAwareFileManager

@synthesize homeDirectory = _homeDirectory;
@synthesize documentsDirectory = _documentsDirectory;
@synthesize temporaryDirectory = _temporaryDirectory;

- (id)init
{
    self = [super init];
    if (self)
    {
        _homeDirectory = NSHomeDirectory();
        _documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        _temporaryDirectory = NSTemporaryDirectory();
        
        sFileProtectionEnabled = [[[PreferenceManager sharedManager] preferenceForIdentifier:kSettingsFileProtectionIdentifier] boolValue];
        sFileProtectionEnabled &= [[AccountManager sharedManager] numberOfPaidAccounts] > 0;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(preferenceDidChange:) name:kSettingsDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(firstPaidAccountAdded:) name:kAlfrescoFirstPaidAccountAddedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(lastPaidAccountRemoved:) name:kAlfrescoLastPaidAccountRemovedNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public Methods

- (BOOL)updateProtectionForFileAtPath:(NSString *)path
{
    NSError *error = nil;
    [[NSFileManager defaultManager] setAttributes:@{NSFileProtectionKey : sFileProtectionEnabled ? NSFileProtectionComplete : NSFileProtectionNone } ofItemAtPath:path error:&error];
    
    return error == nil;
}

#pragma mark - Private Methods

- (void)preferenceDidChange:(NSNotification *)notification
{
    NSString *preferenceIdentifier = notification.object;
    
    if ([preferenceIdentifier isEqualToString:kSettingsFileProtectionIdentifier])
    {
        BOOL fileProtectionEnabled = [notification.userInfo[kSettingChangedToKey] boolValue];
        
        if (fileProtectionEnabled == sFileProtectionEnabled)
        {
            // Nothing to do
            return;
        }

        sFileProtectionEnabled = fileProtectionEnabled;
        [self updateProtectionForLocalFiles];
    }
}

- (void)firstPaidAccountAdded:(NSNotification *)notification
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"fileprotection.title", @"File Protection")
                                                                             message:NSLocalizedString(@"fileprotection.available.message", @"Enable File Protection?")
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *noAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"No", @"No")
                                                       style:UIAlertActionStyleCancel
                                                     handler:nil];
    [alertController addAction:noAction];
    UIAlertAction *enableProtectionAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"fileprotection.available.confirm", @"Enable Protection")
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * _Nonnull action) {
                                                                       // Update the preference flag
                                                                       [[PreferenceManager sharedManager] updatePreferenceToValue:@(YES) preferenceIdentifier:kSettingsFileProtectionIdentifier];
                                                                   }];
    [alertController addAction:enableProtectionAction];
    [[UniversalDevice topPresentedViewController] presentViewController:alertController animated:YES completion:nil];
}

- (void)lastPaidAccountRemoved:(NSNotification *)notification
{
    // Update the static flag - this is deliberately done here so that existing files are not unprotected in the preference changed handler
    sFileProtectionEnabled = NO;
    [[PreferenceManager sharedManager] updatePreferenceToValue:@(NO) preferenceIdentifier:kSettingsFileProtectionIdentifier];
}

- (void)updateProtectionForLocalFiles
{
    NSArray *userContentFolders = @[self.documentsDirectory,
                                    self.temporaryDirectory,
                                    [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]];
    
    UIView *view = activeView();
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:view];
    hud.detailsLabel.text = NSLocalizedString(sFileProtectionEnabled ? @"fileprotection.protecting.message" : @"fileprotection.unprotecting.message", @"Protecting/Unprotecting");
    hud.minShowTime = 1;
    [view addSubview:hud];
    [hud showAnimated:YES];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        for (NSString *folder in userContentFolders)
        {
            [self enumerateThroughDirectory:folder includingSubDirectories:YES withBlock:^(NSString *fullFilePath) {
                [self updateProtectionForFileAtPath:fullFilePath];
            } error:nil];
        }
        [hud hideAnimated:YES];
    });
}

#pragma mark - AlfrescoFileManager

- (BOOL)fileExistsAtPath:(NSString *)path
{
    return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

- (BOOL)fileExistsAtPath:(NSString *)path isDirectory:(BOOL *)isDirectory
{
    return [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:isDirectory];
}

- (BOOL)createFileAtPath:(NSString *)path contents:(NSData *)data error:(NSError **)error
{
    BOOL createFileAtPath = [[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:nil];
    if (createFileAtPath)
    {
        [self updateProtectionForFileAtPath:path];
    }
    return createFileAtPath;
}

- (BOOL)createDirectoryAtPath:(NSString *)path withIntermediateDirectories:(BOOL)createIntermediates attributes:(NSDictionary *)attributes error:(NSError **)error
{
    return [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:createIntermediates attributes:attributes error:error];
}

- (BOOL)removeItemAtPath:(NSString *)path error:(NSError **)error
{
    return [[NSFileManager defaultManager] removeItemAtPath:path error:error];
}

- (BOOL)removeItemAtURL:(NSURL *)URL error:(NSError **)error
{
    return [[NSFileManager defaultManager] removeItemAtURL:URL error:error];
}

- (BOOL)copyItemAtPath:(NSString *)sourcePath toPath:(NSString *)destinationPath error:(NSError **)error
{
    BOOL copyItemAtPath = [[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:destinationPath error:error];
    if (copyItemAtPath)
    {
        [self updateProtectionForFileAtPath:destinationPath];
    }
    return copyItemAtPath;
}

- (BOOL)copyItemAtURL:(NSURL *)sourceURL toURL:(NSURL *)destinationURL error:(NSError **)error
{
    BOOL copyItemAtURL = [[NSFileManager defaultManager] copyItemAtURL:sourceURL toURL:destinationURL error:error];
    if (copyItemAtURL)
    {
        [self updateProtectionForFileAtPath:[destinationURL path]];
    }
    return copyItemAtURL;
}

- (BOOL)moveItemAtPath:(NSString *)sourcePath toPath:(NSString *)destinationPath error:(NSError **)error
{
    BOOL moveItemAtPath = [[NSFileManager defaultManager] moveItemAtPath:sourcePath toPath:destinationPath error:error];
    if (moveItemAtPath)
    {
        [self updateProtectionForFileAtPath:destinationPath];
    }
    return moveItemAtPath;
}

- (BOOL)moveItemAtURL:(NSURL *)sourceURL toURL:(NSURL *)destinationURL error:(NSError **)error
{
    BOOL moveItemAtURL = [[NSFileManager defaultManager] moveItemAtURL:sourceURL toURL:destinationURL error:error];
    if (moveItemAtURL)
    {
        [self updateProtectionForFileAtPath:[destinationURL path]];
    }
    return moveItemAtURL;
}

- (NSDictionary *)attributesOfItemAtPath:(NSString *)path error:(NSError **)error
{
    BOOL isDir;
    [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
    
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:error];
    NSDictionary *alfrescoAttributeDictionary = nil;
    
    if (attributes)
    {
        alfrescoAttributeDictionary = @{kAlfrescoFileSize: attributes[NSFileSize],
                                        kAlfrescoFileLastModification: attributes[NSFileModificationDate],
                                        kAlfrescoIsFolder: @(isDir)};
    }
    
    return alfrescoAttributeDictionary;
}

- (NSArray *)contentsOfDirectoryAtPath:(NSString *)directoryPath error:(NSError **)error
{
    return [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryPath error:error];
}

- (BOOL)enumerateThroughDirectory:(NSString *)directory includingSubDirectories:(BOOL)includeSubDirectories withBlock:(void (^)(NSString *fullFilePath))block error:(NSError **)error
{
    __block BOOL completedWithoutError = YES;
    __block NSError *enumerationError;
    
    NSDirectoryEnumerationOptions options;
    if (!includeSubDirectories)
    {
        options = NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants;
    }
    else
    {
        options = NSDirectoryEnumerationSkipsHiddenFiles;
    }
    
    NSCharacterSet *set = [NSCharacterSet URLHostAllowedCharacterSet];
    NSString *string = [directory stringByAddingPercentEncodingWithAllowedCharacters:set];
    
    NSEnumerator *folderContents = [[NSFileManager defaultManager] enumeratorAtURL:[NSURL URLWithString:string]
                                                        includingPropertiesForKeys:@[NSURLNameKey]
                                                                           options:options
                                                                      errorHandler:^BOOL(NSURL *url, NSError *fileError) {
                                                                          AlfrescoLogDebug(@"Error retrieving contents of the URL: %@ with the error: %@", [url absoluteString], [fileError localizedDescription]);
                                                                          if (fileError)
                                                                          {
                                                                              enumerationError = fileError;
                                                                          }
                                                                          
                                                                          completedWithoutError = NO;
                                                                          // continue enumeration
                                                                          return YES;
                                                                      }];
    if (enumerationError)
    {
        *error = enumerationError;
    }
    
    for (NSURL *fileURL in folderContents)
    {
        NSString *fullPath = [fileURL path];
        if (block != NULL)
        {
            block(fullPath);
        }
    }
    
    return completedWithoutError;
}

- (NSData *)dataWithContentsOfURL:(NSURL *)url
{
    return [[NSFileManager defaultManager] contentsAtPath:[url path]];
}

- (void)appendToFileAtPath:(NSString *)filePath data:(NSData *)data
{
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:filePath];
    
    if (fileHandle)
    {
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:data];
    }
    
    [fileHandle closeFile];
}

- (NSString *)internalFilePathFromName:(NSString *)fileName
{
    return [self.temporaryDirectory stringByAppendingPathComponent:fileName];
}

- (BOOL)fileStreamIsOpen:(NSStream *)stream
{
    NSOutputStream *outputStream = (NSOutputStream *)stream;
    return (outputStream.streamStatus == NSStreamStatusOpen);
}

- (NSInputStream *)inputStreamWithFilePath:(NSString *)filePath
{
    NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:filePath];
    return inputStream;
}

- (NSOutputStream *)outputStreamToFileAtPath:(NSString *)filePath append:(BOOL)shouldAppend
{
    [self updateProtectionForFileAtPath:filePath];
    NSOutputStream *outputStream = [NSOutputStream outputStreamToFileAtPath:filePath append:shouldAppend];
    return outputStream;
}

@end
