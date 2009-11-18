//
//  PBGitRepository.h
//  GitTest
//
//  Created by Pieter de Bie on 13-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PBGitRevList.h"
#import "PBGitRevSpecifier.h"
#import "PBGitConfig.h"
#import "PBGitXErrors.h"

@class PBGitWindowController;
@class PBGitCommit;

@interface PBGitRepository : NSDocument {
	PBGitRevList* revisionList;
	PBGitConfig *config;

	BOOL hasChanged;
	NSMutableArray *branches;
	PBGitRevSpecifier *currentBranch;
	NSMutableDictionary *refs;

	PBGitRevSpecifier *_headRef; // Caching
}

- (BOOL) fetchRemote:(PBGitRevSpecifier *)rev presentError:(BOOL)shouldPresentError;
- (BOOL) pullRemote:(PBGitRevSpecifier *)rev presentError:(BOOL)shouldPresentError;
- (BOOL) pushRemote:(PBGitRevSpecifier *)rev presentError:(BOOL)shouldPresentError;
- (BOOL) checkoutRefName:(NSString *)refName presentError:(BOOL)shouldPresentError;
- (BOOL) cherryPickCommit:(PBGitCommit *)commit presentError:(BOOL)shouldPresentError;
- (BOOL) rebaseBranch:(PBGitRevSpecifier *)branch onUpstream:(PBGitRevSpecifier *)upstream presentError:(BOOL)shouldPresentError;
- (BOOL) rebaseBranch:(PBGitRevSpecifier *)branch onSHA:(NSString *)upstreamSHA presentError:(BOOL)shouldPresentError;
- (BOOL) createBranch:(NSString *)branchRefName onSHA:(NSString *)sha presentError:(BOOL)shouldPresentError;
- (PBGitRevSpecifier*) addBranch:(PBGitRevSpecifier*)rev;
- (BOOL) removeBranch:(PBGitRevSpecifier *)rev;
- (BOOL) addTag:(NSString *)tagName message:(NSString *)message forCommit:(PBGitCommit *)commit presentError:(BOOL)shouldPresentError;
- (BOOL) addRemote:(NSString *)remoteName forURL:(NSString *)remoteURL presentError:(BOOL)shouldPresentError;

- (NSFileHandle*) handleForCommand:(NSString*) cmd;
- (NSFileHandle*) handleForArguments:(NSArray*) args;
- (NSFileHandle *) handleInWorkDirForArguments:(NSArray *)args;
- (NSString*) outputForCommand:(NSString*) cmd;
- (NSString *)outputForCommand:(NSString *)str retValue:(int *)ret;
- (NSString *)outputForArguments:(NSArray *)arguments inputString:(NSString *)input retValue:(int *)ret;
- (NSString *)outputForArguments:(NSArray *)arguments inputString:(NSString *)input byExtendingEnvironment:(NSDictionary *)dict retValue:(int *)ret;


- (NSString*) outputForArguments:(NSArray*) args;
- (NSString*) outputForArguments:(NSArray*) args retValue:(int *)ret;
- (NSString *)outputInWorkdirForArguments:(NSArray*) arguments;
- (NSString *)outputInWorkdirForArguments:(NSArray*) arguments retValue:(int *)ret;
- (BOOL)executeHook:(NSString *)name output:(NSString **)output;
- (BOOL)executeHook:(NSString *)name withArgs:(NSArray*) arguments output:(NSString **)output;

- (NSString *)workingDirectory;
- (NSString *)gitIgnoreFilename;
- (BOOL)isBareRepository;

- (BOOL) reloadRefs;
- (void) addRef:(PBGitRef *)ref fromParameters:(NSArray *)params;
- (void) lazyReload;
- (PBGitRevSpecifier*) headRef;
- (NSString *) headSHA;
- (PBGitCommit *) headCommit;
- (NSString *) realSHAForRev:(PBGitRevSpecifier *)rev;
- (PBGitCommit *) commitForRev:(PBGitRevSpecifier *)rev;
- (NSString *) remoteForRefName:(NSString *)refName presentError:(BOOL)shouldPresentError;
- (BOOL) checkRefFormat:(NSString *)refName;

- (void) readCurrentBranch;
- (PBGitRevSpecifier *)activeBranch;

- (NSString*) parseSymbolicReference:(NSString*) ref;
- (NSString*) parseReference:(NSString*) ref;

+ (NSURL*)gitDirForURL:(NSURL*)repositoryURL;
+ (NSURL*)baseDirForURL:(NSURL*)repositoryURL;
+ (NSString *) basePath;

- (id) initWithURL: (NSURL*) path;
- (void) setup;

@property (assign) BOOL hasChanged;
@property (readonly) PBGitWindowController *windowController;
@property (readonly) PBGitConfig *config;
@property (retain) PBGitRevList* revisionList;
@property (assign) NSMutableArray* branches;
@property (assign) PBGitRevSpecifier *currentBranch;
@property (retain) NSMutableDictionary* refs;

@end
