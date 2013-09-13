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


/** The AlfrescoFileManager is used for all file system usage
 
 Author: Tauseef Mughal (Alfresco)
 */

#import <Foundation/Foundation.h>

@interface AlfrescoFileManager : NSObject

/**
 Property holds a string representation to the home directory on the file system
 */
@property (nonatomic, strong, readonly) NSString *homeDirectory;

/**
 Property holds a string representation to the documents directory on the file system
 */
@property (nonatomic, strong, readonly) NSString *documentsDirectory;

/**
 Property holds a string representation to the temp directory on the file system
 */
@property (nonatomic, strong, readonly) NSString *temporaryDirectory;

/**
 Call this function to get a shared instance of the AlfrescoFileManager
 */
+ (id)sharedManager;

/**
 Call this to check if a file exists at the path location
 
 @returns bool - True if the file/folder exists
 */
- (BOOL)fileExistsAtPath:(NSString *)path;

/**
 Call this to check if a file exists at the path location passing in a memory reference pointer to a BOOL which
 indicates if the path points to a directory
 
 @returns bool - True if the file/folder exists
 */
- (BOOL)fileExistsAtPath:(NSString *)path isDirectory:(BOOL *)isDirectory;

/*
 Call this to create a file with data passed in at a given location
 
 @returns bool - True if the file was created successfully
 */
- (BOOL)createFileAtPath:(NSString *)path contents:(NSData *)data error:(NSError **)error;

/*
 Call this to create a directory at a given path. Set the createIntermediateDirectories to true if you would like to
 create leading directories if they do not exist
 
 @returns bool - True if the directory was created successfully
 */
- (BOOL)createDirectoryAtPath:(NSString *)path withIntermediateDirectories:(BOOL)createIntermediates attributes:(NSDictionary *)attributes error:(NSError **)error;

/*
 Call this to remove an item at a given path
 
 @returns bool - True if the file/folder was removed successfully
 */
- (BOOL)removeItemAtPath:(NSString *)path error:(NSError **)error;

/*
 Call this to copy an item from a given path to another path within the current file system
 
 @returns bool - True if the file was copied successfully
 */
- (BOOL)copyItemAtPath:(NSString *)sourcePath toPath:(NSString *)destinationPath error:(NSError **)error;

/*
 Call this to move an item from a given path to another within the current file system
 
 @returns bool - True if the item was moved successfully
 */
- (BOOL)moveItemAtPath:(NSString *)sourcePath toPath:(NSString *)destinationPath error:(NSError **)error;

/*
 Call this to return the attributes of a given item at a path
 
 @returns dictionary - dictionary containing fileSize, isFolder and lastModifiedDate
 */
- (NSDictionary *)attributesOfItemAtPath:(NSString *)path error:(NSError **)error;

/*
 Call this to return an array of all items in a given directory
 
 @returns array - array containing a list of items in a given directory
 */
- (NSArray *)contentsOfDirectoryAtPath:(NSString *)directoryPath error:(NSError **)error;

/*
 Enumerates through a given directory either including or not including sub directories
 */
- (BOOL)enumerateThroughDirectory:(NSString *)directory includingSubDirectories:(BOOL)includeSubDirectories withBlock:(void (^)(NSString *fullFilePath))block error:(NSError **)error;

/*
 Returns the data representation of the file at a given URL
 
 @returns data - NSData representation of the item at the given URL location
 */
- (NSData *)dataWithContentsOfURL:(NSURL *)url;

/*
 Call this to append data to the file at a given path
 */
- (void)appendToFileAtPath:(NSString *)filePath data:(NSData *)data;

/*
 Call this to retrieve the internal filePath from a file name
 
 @returns string - the filePath in relation to a given fileName
 */
- (NSString *)internalFilePathFromName:(NSString *)fileName;

/*
 Call this to return an input stream to the requested file path.
 
 @returns inputStream - an input stream to the requested file path
 */
- (NSInputStream *)inputStreamWithFilePath:(NSString *)filePath;

/*
 Call this to return an output stream to the requested file path.
 
 @returns outputStream - an output stream to the requested file path
 */
- (NSOutputStream *)outputStreamToFileAtPath:(NSString *)filePath append:(BOOL)shouldAppend;

@end
