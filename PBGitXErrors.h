//
//  PBGitXErrors.h
//  GitX
//
//  Created by Andre Berg on 31.10.09.
//  Copyright 2009 Berg Media. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//    http://www.apache.org/licenses/LICENSE-2.0
//  
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import <Cocoa/Cocoa.h>

OBJC_EXTERN NSString * const PBGitXErrorDomain;
OBJC_EXTERN NSString * const PBCLIProxyErrorDomain;

OBJC_EXTERN NSString * const PBInvalidBranchErrorMessage;
OBJC_EXTERN NSString * const PBMissingRemoteErrorMessage;

OBJC_EXTERN const NSInteger PBFileReadingUnsupportedErrorCode;   /* @"Reading files is not supported." */
OBJC_EXTERN const NSInteger PBNotAGitRepositoryErrorCode;        /* @"%@ does not appear to be a git repository." */
OBJC_EXTERN const NSInteger PBGitBinaryNotFoundErrorCode;
OBJC_EXTERN const NSInteger PBGitInvalidBranchErrorCode;         // branch does not have a remote configured
OBJC_EXTERN const NSInteger PBGitFetchErrorCode;
OBJC_EXTERN const NSInteger PBGitPullErrorCode;
OBJC_EXTERN const NSInteger PBGitPushErrorCode;
OBJC_EXTERN const NSInteger PBGitCheckoutErrorCode;
OBJC_EXTERN const NSInteger PBGitCherryPickErrorCode;
OBJC_EXTERN const NSInteger PBGitRebaseErrorCode;
OBJC_EXTERN const NSInteger PBGitCreateBranchErrorCode;
OBJC_EXTERN const NSInteger PBGitAddTagErrorCode;
OBJC_EXTERN const NSInteger PBGitAddRemoteErrorCode;

