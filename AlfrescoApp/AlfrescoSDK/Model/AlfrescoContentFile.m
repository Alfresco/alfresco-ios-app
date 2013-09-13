/*******************************************************************************
 * Copyright (C) 2005-2012 Alfresco Software Limited.
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
 ******************************************************************************/

#import "AlfrescoContentFile.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "AlfrescoErrors.h"
#import <math.h>
#import "AlfrescoFileManager.h"
#import "AlfrescoConstants.h"

@interface AlfrescoContentFile ()
@property (nonatomic, strong, readwrite) NSURL *fileUrl;
@end

@implementation AlfrescoContentFile

- (id)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (id)initWithUrl:(NSURL *)url
{
    return [self initWithUrl:url mimeType:nil];
}


- (id)initWithUrl:(NSURL *)url mimeType:(NSString *)mimeType
{
    NSURL *localFileUrl = nil;
    
    // try and get mime type from file name if not provided
    NSString *filename = [url lastPathComponent];
    if (nil == mimeType)
    {
        mimeType = [AlfrescoContentFile mimeTypeFromFilename:filename];
    }
    
    if ([url isFileReferenceURL])
    {
        localFileUrl = url;
    }
    else
    {
        // create temporary file if URL does not point to a local file
        NSString *pathname = [[[AlfrescoFileManager sharedManager] temporaryDirectory] stringByAppendingPathComponent:filename];
        NSData *fileContent = [[AlfrescoFileManager sharedManager] dataWithContentsOfURL:url];
        
        localFileUrl = [NSURL fileURLWithPath:pathname];
        [[AlfrescoFileManager sharedManager] createFileAtPath:[localFileUrl path] contents:fileContent error:nil];
    }
    
    // retrieve the length of the file
    NSError *fileError = nil;
    NSDictionary *fileDictionary =  [[AlfrescoFileManager sharedManager] attributesOfItemAtPath:[localFileUrl path] error:&fileError];
    
    // use super class to initialise with mime type and length
    self = [super initWithMimeType:mimeType length:[[fileDictionary valueForKey:kAlfrescoFileSize] unsignedLongLongValue]];
    if (nil != self && nil != url)
    {
        self.fileUrl = localFileUrl;
    }
    return self;    
}


- (id)initWithData:(NSData *)data mimeType:(NSString *)mimeType
{
    NSURL *localFileUrl = nil;
    
    NSString *tmpName = [AlfrescoContentFile GUIDString];
    if (nil != tmpName)
    {
        NSURL *pathURL = [NSURL fileURLWithPath:[[[AlfrescoFileManager sharedManager] temporaryDirectory] stringByAppendingPathComponent:tmpName]];
        [[AlfrescoFileManager sharedManager] createFileAtPath:[pathURL path] contents:data error:nil];
        localFileUrl = pathURL;
    }
    
    self = [super initWithMimeType:mimeType length:data.length];
    if (nil != self)
    {
        self.fileUrl = localFileUrl;
    }
    return self;
}


#pragma mark - private methods
+ (NSString *)mimeTypeFromFilename:(NSString *)filename
{
    NSRange extensionRange = [filename rangeOfString:@"." options:NSBackwardsSearch];
    if (NSNotFound == extensionRange.location) 
    {
        return nil;
    }
    NSString *extension = [[filename substringFromIndex:extensionRange.location + 1] lowercaseString];
    // Get the UTI from the file's extension:
    CFStringRef pathExtension = (__bridge_retained CFStringRef)extension;
    CFStringRef type = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, NULL);
    NSString *mimeType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass(type, kUTTagClassMIMEType);
    if (NULL != type) 
    {
        CFRelease(type);
    }
    if (NULL != pathExtension) 
    {
        CFRelease(pathExtension);
    }
    return mimeType;
}

+ (NSString *)GUIDString
{
    CFUUIDRef CFGUID = CFUUIDCreate(NULL);
    CFStringRef guidString = CFUUIDCreateString(NULL, CFGUID);
    if (NULL != CFGUID)
    {
        CFRelease(CFGUID);
    }
    return (__bridge_transfer NSString *)guidString;
}

@end
