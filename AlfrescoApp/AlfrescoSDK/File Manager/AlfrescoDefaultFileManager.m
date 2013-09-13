/*
 ******************************************************************************
 * Copyright (C) 2005-2013 Alfresco Software Limited.
 *
 * This file is part of the Alfresco Mobile SDK.
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
 *****************************************************************************
 */

#import "AlfrescoDefaultFileManager.h"
#import "AlfrescoConstants.h"
#import "AlfrescoLog.h"

@implementation AlfrescoDefaultFileManager

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
    }
    return self;
}

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
    return [[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:nil];
}

- (BOOL)createDirectoryAtPath:(NSString *)path withIntermediateDirectories:(BOOL)createIntermediates attributes:(NSDictionary *)attributes error:(NSError **)error
{
    return [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:createIntermediates attributes:attributes error:error];
}

- (BOOL)removeItemAtPath:(NSString *)path error:(NSError **)error
{
    return [[NSFileManager defaultManager] removeItemAtPath:path error:error];
}

- (BOOL)copyItemAtPath:(NSString *)sourcePath toPath:(NSString *)destinationPath error:(NSError **)error
{
    return [[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:destinationPath error:error];
}

- (BOOL)moveItemAtPath:(NSString *)sourcePath toPath:(NSString *)destinationPath error:(NSError **)error
{
    return [[NSFileManager defaultManager] moveItemAtPath:sourcePath toPath:destinationPath error:error];
}

- (NSDictionary *)attributesOfItemAtPath:(NSString *)path error:(NSError **)error
{
    BOOL isDir;
    [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
    
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:error];
    
    NSDictionary *alfrescoAttributeDictionary = nil;
    
    if (attributes)
    {
        alfrescoAttributeDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[attributes objectForKey:NSFileSize], kAlfrescoFileSize,
                                       [attributes objectForKey:NSFileModificationDate], kAlfrescoFileLastModification,
                                       [NSNumber numberWithBool:isDir], kAlfrescoIsFolder,
                                       nil];
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
    
    NSDirectoryEnumerationOptions options;
    if (!includeSubDirectories)
    {
        options = NSDirectoryEnumerationSkipsHiddenFiles | NSDirectoryEnumerationSkipsSubdirectoryDescendants;
    }
    else
    {
        options = NSDirectoryEnumerationSkipsHiddenFiles;
    }
    
    NSEnumerator *folderContents = [[NSFileManager defaultManager] enumeratorAtURL:[NSURL URLWithString:[directory stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
                                                        includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLNameKey, nil]
                                                                           options:options
                                                                      errorHandler:^BOOL(NSURL *url, NSError *fileError) {
                                                                          AlfrescoLogDebug(@"Error retrieving contents of the URL: %@ with the error: %@", [url absoluteString], [fileError localizedDescription]);
                                                                          *error = fileError;
                                                                          completedWithoutError = NO;
                                                                          return YES;
                                                                      }];
    
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
    BOOL isStreamOpen = NO;
    NSOutputStream *outputStream = (NSOutputStream *)stream;
    isStreamOpen = (outputStream.streamStatus == NSStreamStatusOpen);
    return isStreamOpen;
}

- (NSInputStream *)inputStreamWithFilePath:(NSString *)filePath
{
    NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:filePath];
    return inputStream;
}

- (NSOutputStream *)outputStreamToFileAtPath:(NSString *)filePath append:(BOOL)shouldAppend
{
    NSOutputStream *outputStream = [NSOutputStream outputStreamToFileAtPath:filePath append:shouldAppend];
    return outputStream;
}

@end
