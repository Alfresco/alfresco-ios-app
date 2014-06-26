//
//  NSObject+debugCheck.h
//  Reverse Me
//
//  Created by Derek Selander on a happy day.
//  Copyright (c) 2013 Derek Selander. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#include <string.h>

@interface NSObject (DebugCheck)

#define SEC_IS_BEING_DEBUGGED_RETURN_VOID()    size_t size = sizeof(struct kinfo_proc); \
                                    struct kinfo_proc info; \
                                    int ret, name[4]; \
                                    memset(&info, 0, sizeof(struct kinfo_proc)); \
                                    name[0] = CTL_KERN; \
                                    name[1] = KERN_PROC; \
                                    name[2] = KERN_PROC_PID; \
                                    name[3] = getpid(); \
                                    if ((ret = (sysctl(name, 4, &info, &size, NULL, 0)))) { \
                                        if (ret) return; \
                                    } \
                                    if (info.kp_proc.p_flag & P_TRACED) return

#define SEC_IS_BEING_DEBUGGED_RETURN_NIL()  size_t size = sizeof(struct kinfo_proc); \
                                            struct kinfo_proc info; \
                                            int ret, name[4]; \
                                            memset(&info, 0, sizeof(struct kinfo_proc)); \
                                            name[0] = CTL_KERN; \
                                            name[1] = KERN_PROC; \
                                            name[2] = KERN_PROC_PID; \
                                            name[3] = getpid(); \
                                            if ((ret = (sysctl(name, 4, &info, &size, NULL, 0)))) { \
                                            if (ret) return nil; \
                                            } \
                                            if (info.kp_proc.p_flag & P_TRACED) return nil

@end
