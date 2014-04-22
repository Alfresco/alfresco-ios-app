//
//  SyncOperation.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 14/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

@interface SyncOperation : NSOperation

- (id)initWithDocumentFolderService:(id)documentFolderService
                   downloadDocument:(AlfrescoDocument *)document
                       outputStream:outputStream
            downloadCompletionBlock:(AlfrescoBOOLCompletionBlock)downloadCompletionBlock
                      progressBlock:(AlfrescoProgressBlock)progressBlock;

- (id)initWithDocumentFolderService:(id)documentFolderService
                     uploadDocument:(AlfrescoDocument *)document
                        inputStream:inputStream
              uploadCompletionBlock:(AlfrescoDocumentCompletionBlock)uploadCompletionBlock
                      progressBlock:(AlfrescoProgressBlock)progressBlock;

- (void)cancelOperation;

@end
