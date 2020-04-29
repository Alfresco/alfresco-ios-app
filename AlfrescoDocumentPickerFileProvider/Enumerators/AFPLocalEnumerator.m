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

#import "AFPLocalEnumerator.h"
#import "AFPItem.h"
#import "AlfrescoFileManager+Extensions.h"
#import "AFPErrorBuilder.h"

@implementation AFPLocalEnumerator

- (void)enumerateItemsForObserver:(id<NSFileProviderEnumerationObserver>)observer startingAtPage:(NSFileProviderPage)page
{
    NSError *authenticationError = [AFPErrorBuilder authenticationErrorForPIN];
    if (authenticationError)
    {
        [observer finishEnumeratingWithError:authenticationError];
    }
    else
    {
        __block NSMutableArray *documents = [NSMutableArray array];
        NSError *enumeratorError = nil;
        
        AlfrescoFileManager *fileManager = [AlfrescoFileManager sharedManager];
        NSString *downloadContentPath = [fileManager downloadsContentFolderPath];
        [fileManager enumerateThroughDirectory:downloadContentPath includingSubDirectories:NO withBlock:^(NSString *fullFilePath) {
            AFPItem *item = [[AFPItem alloc] initWithLocalFilesPath:fullFilePath];
            [documents addObject:item];
        } error:&enumeratorError];
        
        if (enumeratorError)
        {
            AlfrescoLogError(@"Enumeration Error: %@", enumeratorError.localizedDescription);
        }
        
        NSSortDescriptor *sortOrder = [NSSortDescriptor sortDescriptorWithKey:nil ascending:YES comparator:^NSComparisonResult(AFPItem *firstDocument, AFPItem *secondDocument) {
            return [firstDocument.filename caseInsensitiveCompare:secondDocument.filename];
        }];
        
        [observer didEnumerateItems:[documents sortedArrayUsingDescriptors:@[sortOrder]]];
        [observer finishEnumeratingUpToPage:nil];
    }
}

- (void)invalidate
{
    // TODO: perform invalidation of server connection if necessary
}

@end
