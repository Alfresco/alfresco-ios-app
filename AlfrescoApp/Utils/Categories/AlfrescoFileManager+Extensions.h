//
//  AlfrescoFileManager+Extensions.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 12/12/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

@interface AlfrescoFileManager (Extensions)

// preview documents
- (NSString *)documentPreviewDocumentFolderPath;

// sync
- (NSString *)syncFolderPath;

// downloads
- (NSString *)downloadsFolderPath;
- (NSString *)downloadsInfoContentPath;
- (NSString *)downloadsContentFolderPath;

@end
