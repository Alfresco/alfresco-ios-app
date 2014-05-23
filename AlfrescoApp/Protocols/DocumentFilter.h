//
//  DocumentFilter.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 10/12/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

@protocol DocumentFilter <NSObject>

- (BOOL)filterDocumentWithExtension:(NSString *)documentExtension;

@end
