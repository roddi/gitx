//
//  PBGitDefaults.h
//  GitX
//
//  Created by Jeff Mesnil on 19/10/08.
//  Copyright 2008 Jeff Mesnil (http://jmesnil.net/). All rights reserved.
//

@interface PBGitDefaults : NSObject
{

}

+ (int) commitMessageViewVerticalLineLength;
+ (BOOL) commitMessageViewHasVerticalLine;
+ (BOOL) isGistEnabled;
+ (BOOL) isGravatarEnabled;
+ (BOOL) confirmPublicGists;
+ (BOOL) isGistPublic;
+ (BOOL) showWhitespaceDifferences;
+ (BOOL) refreshAutomatically;
+ (BOOL)openCurDirOnLaunch;
+ (BOOL)showOpenPanelOnLaunch;
+ (BOOL) openPreviousDocumentsOnLaunch;
+ (void) setPreviousDocumentPaths:(NSArray *)documentPaths;
+ (NSArray *) previousDocumentPaths;
+ (void) removePreviousDocumentPaths;

@end
