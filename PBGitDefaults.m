//
//  PBGitDefaults.m
//  GitX
//
//  Created by Jeff Mesnil on 19/10/08.
//  Copyright 2008 Jeff Mesnil (http://jmesnil.net/). All rights reserved.
//

#import "PBGitDefaults.h"

#define kDefaultVerticalLineLength 50
#define kCommitMessageViewVerticalLineLength @"PBCommitMessageViewVerticalLineLength"
#define kCommitMessageViewHasVerticalLine @"PBCommitMessageViewHasVerticalLine"
#define kEnableGist @"PBEnableGist"
#define kEnableGravatar @"PBEnableGravatar"
#define kConfirmPublicGists @"PBConfirmPublicGists"
#define kPublicGist @"PBGistPublic"
#define kShowWhitespaceDifferences @"PBShowWhitespaceDifferences"
#define kRefreshAutomatically @"PBRefreshAutomatically"
#define kOpenCurDirOnLaunch @"PBOpenCurDirOnLaunch"
#define kShowOpenPanelOnLaunch @"PBShowOpenPanelOnLaunch"
#define kOpenPreviousDocumentsOnLaunch @"PBOpenPreviousDocumentsOnLaunch"
#define kPreviousDocumentPaths @"PBPreviousDocumentPaths"

@implementation PBGitDefaults

+ (void)initialize
{
	NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
	[defaultValues setObject:[NSNumber numberWithInt:kDefaultVerticalLineLength]
                      forKey:kCommitMessageViewVerticalLineLength];
    [defaultValues setObject:[NSNumber numberWithBool:YES]
                      forKey:kCommitMessageViewHasVerticalLine];
	[defaultValues setObject:[NSNumber numberWithBool:YES]
			  forKey:kEnableGist];
	[defaultValues setObject:[NSNumber numberWithBool:YES]
			  forKey:kEnableGravatar];
	[defaultValues setObject:[NSNumber numberWithBool:YES]
			  forKey:kConfirmPublicGists];
	[defaultValues setObject:[NSNumber numberWithBool:NO]
			  forKey:kPublicGist];
	[defaultValues setObject:[NSNumber numberWithBool:YES]
			  forKey:kShowWhitespaceDifferences];
	[defaultValues setObject:[NSNumber numberWithBool:YES]
			  forKey:kOpenCurDirOnLaunch];
	[defaultValues setObject:[NSNumber numberWithBool:YES]
			  forKey:kShowOpenPanelOnLaunch];
	[defaultValues setObject:[NSNumber numberWithBool:NO]
                      forKey:kOpenPreviousDocumentsOnLaunch];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}

+ (int) commitMessageViewVerticalLineLength
{
	return [[NSUserDefaults standardUserDefaults] integerForKey:kCommitMessageViewVerticalLineLength];
}

+ (BOOL) commitMessageViewHasVerticalLine
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:kCommitMessageViewHasVerticalLine];
}

+ (BOOL) isGistEnabled
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:kEnableGist];
}

+ (BOOL) isGravatarEnabled
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:kEnableGravatar];
}

+ (BOOL) confirmPublicGists
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:kConfirmPublicGists];
}

+ (BOOL) isGistPublic
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:kPublicGist];
}

+ (BOOL) refreshAutomatically
{
   return [[NSUserDefaults standardUserDefaults] boolForKey:kRefreshAutomatically];
}

+ (BOOL)showWhitespaceDifferences
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:kShowWhitespaceDifferences];
}

+ (BOOL)openCurDirOnLaunch
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:kOpenCurDirOnLaunch];
}

+ (BOOL)showOpenPanelOnLaunch
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:kShowOpenPanelOnLaunch];
}

+ (BOOL) openPreviousDocumentsOnLaunch
{
	return [[NSUserDefaults standardUserDefaults] boolForKey:kOpenPreviousDocumentsOnLaunch];
}

+ (void) setPreviousDocumentPaths:(NSArray *)documentPaths
{
	[[NSUserDefaults standardUserDefaults] setObject:documentPaths forKey:kPreviousDocumentPaths];
}

+ (NSArray *) previousDocumentPaths
{
	return [[NSUserDefaults standardUserDefaults] arrayForKey:kPreviousDocumentPaths];
}

+ (void) removePreviousDocumentPaths
{
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:kPreviousDocumentPaths];
}

@end
