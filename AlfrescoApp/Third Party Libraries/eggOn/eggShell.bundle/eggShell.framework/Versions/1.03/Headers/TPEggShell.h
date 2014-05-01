//
//  TPEggShell.h
//  eggShell
//
//  Created by Frank Le Grand on 11/27/13.
//  Copyright (c) 2013 TestPlant. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface TPEggShell : NSObject

+ (BOOL)serverIsRunning;
+ (BOOL)startServer;
+ (BOOL)startServerWithPassword: (char *) password onPort: (int) port;  // TO DEPRECATE
+ (BOOL)launchServerWithPassword:(NSString *)password onPort:(NSInteger)port;
+ (void)stopServer;

+ (BOOL)bonjourIsStarted;
+ (BOOL)enableBonjour;
+ (void)setEnableBonjour:(BOOL)flag;

+ (BOOL)openReverseConnectionToHost:(NSString *)clientHost onPort:(NSInteger)portNum;
+ (BOOL)openReverseConnection;
+ (BOOL)closeReverseConnection;
+ (BOOL)reverseConnectionIsOpen;

+ (NSString *)password;
+ (void)setPassword:(NSString *)password;

+ (BOOL)autoAssignPort;
+ (void)setAutoAssignPort:(BOOL)flag;
+ (NSInteger)port;
+ (void)setPort:(NSInteger)port;

+ (BOOL)shareServer;
+ (void)setShareServer:(BOOL)flag;

+ (NSInteger)maxDepth;
+ (void)setMaxDepth:(NSInteger)maxDepth;

+ (NSString *)reverseConnectionClientHost;
+ (void)setReverseConnectionClientHost:(NSString *)host;

+ (NSInteger)reverseConnectionClientPort;
+ (void)setReverseConnectionClientPort:(NSInteger)port;

+ (BOOL)showDebugInboundMessages;
+ (void)setShowDebugInboundMessages:(BOOL)flag;
+ (BOOL)showDebugOutboundMessages;
+ (void)setShowDebugOutboundMessages:(BOOL)flag;
+ (BOOL)showDebugProceduralMessages;
+ (void)setShowDebugProceduralMessages:(BOOL)flag;
+ (BOOL)showDebugConnectionMessages;
+ (void)setShowDebugConnectionMessages:(BOOL)flag;

+ (NSString *)frameworkVersion;
+ (NSString *)licenseInfo;
+ (NSString *)copyrightInfo;

+ (void)showEggShellSettingsOnViewController:(UIViewController *)viewController;


// Use the sharedEggShell when you need to observe the serverIsRunning property
+ (TPEggShell *)sharedEggShell;

@property (readonly, atomic) BOOL serverIsRunning;
@property (readonly, atomic) BOOL reverseConnectionIsOpen;
@property (readonly, atomic) BOOL bonjourIsStarted;

@end
