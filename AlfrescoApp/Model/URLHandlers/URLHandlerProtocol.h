//
//  URLHandlerProtocol.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol URLHandlerProtocol <NSObject>

/**
 * Determines whether the URL can be handled by the protocol implementor.
 * The url parameter will be
 */
- (BOOL)canHandleURL:(NSURL *)url;

/**
 * Performs the operation on the input URL
 */
- (BOOL)handleURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;
@end
