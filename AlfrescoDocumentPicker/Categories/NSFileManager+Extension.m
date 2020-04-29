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

#import "NSFileManager+Extension.h"

@implementation NSFileManager (Extension)

- (BOOL)copyItemAtURL:(NSURL *)srcURL toURL:(NSURL *)dstURL overwritingExistingFile:(BOOL)overwrite error:(NSError **)error
{
    if (overwrite)
    {
        if([self fileExistsAtPath:[dstURL path]])
        {
            [self removeItemAtURL:dstURL error:error];
        }
    }
    
    return [self copyItemAtURL:srcURL toURL:dstURL error:error];
}

- (BOOL)copyItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath overwritingExistingFile:(BOOL)overwrite error:(NSError **)error
{
    if (overwrite)
    {
        if([self fileExistsAtPath:dstPath])
        {
            [self removeItemAtPath:dstPath error:error];
        }
    }
    
    return [self copyItemAtPath:srcPath toPath:dstPath error:error];
}

@end
