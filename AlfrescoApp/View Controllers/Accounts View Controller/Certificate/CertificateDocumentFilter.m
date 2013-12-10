//
//  CertificateDocumentFilter.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 10/12/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "CertificateDocumentFilter.h"

@implementation CertificateDocumentFilter

- (BOOL)filterDocumentWithExtension:(NSString *)documentExtension
{
    BOOL isCertificate = [documentExtension isEqualToString:@"p12"] || [documentExtension isEqualToString:@"pfx"];
    return !isCertificate;
}

@end
