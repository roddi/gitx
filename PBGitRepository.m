//
//  PBGitRepository.m
//  GitTest
//
//  Created by Pieter de Bie on 13-06-08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "PBGitRepository.h"
#import "PBGitCommit.h"
#import "PBGitWindowController.h"
#import "PBGitBinary.h"

#import "NSFileHandleExt.h"
#import "PBEasyPipe.h"
#import "PBGitRef.h"
#import "PBGitRevSpecifier.h"

static NSString * repositoryBasePath = nil;

@implementation PBGitRepository

@synthesize revisionList, branches, currentBranch, refs, hasChanged, config;

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	if (outError) {
		*outError = [NSError errorWithDomain:PBGitXErrorDomain
                                      code:PBFileReadingUnsupportedErrorCode
                                  userInfo:[NSDictionary dictionaryWithObject:@"Reading files is not supported." forKey:NSLocalizedFailureReasonErrorKey]];
	}
	return NO;
}

+ (BOOL) isBareRepository: (NSString*) path
{
	return [[PBEasyPipe outputForCommand:[PBGitBinary path] withArgs:[NSArray arrayWithObjects:@"rev-parse", @"--is-bare-repository", nil] inDir:path] isEqualToString:@"true"];
}

// can be used to return the basePath of a repo when [self fileURL] is unavailable yet
+ (NSString *) basePath {
    if (repositoryBasePath) {
        return repositoryBasePath;
    }
    return nil;
}


+ (NSURL*)gitDirForURL:(NSURL*)repositoryURL;
{
	if (![PBGitBinary path])
		return nil;

	NSString* repositoryPath = [repositoryURL path];

    // save base path
    repositoryBasePath = [repositoryPath stringByDeletingLastPathComponent];

	if ([self isBareRepository:repositoryPath])
		return repositoryURL;

	// Use rev-parse to find the .git dir for the repository being opened
	NSString* newPath = [PBEasyPipe outputForCommand:[PBGitBinary path] withArgs:[NSArray arrayWithObjects:@"rev-parse", @"--git-dir", nil] inDir:repositoryPath];
    
    if ([newPath rangeOfString:@"fatal:"].length != 0)
        return nil;
	
    if ([newPath isEqualToString:@".git"])
		return [NSURL fileURLWithPath:[repositoryPath stringByAppendingPathComponent:@".git"]];
	if ([newPath length] > 0)
		return [NSURL fileURLWithPath:newPath];

	return nil;
}

// For a given path inside a repository, return either the .git dir
// (for a bare repo) or the directory above the .git dir otherwise
+ (NSURL*)baseDirForURL:(NSURL*)repositoryURL;
{
	NSURL* gitDirURL         = [self gitDirForURL:repositoryURL];
	NSString* repositoryPath = [gitDirURL path];

	if (![self isBareRepository:repositoryPath]) {
		repositoryURL = [NSURL fileURLWithPath:[[repositoryURL path] stringByDeletingLastPathComponent]];
	}

	return repositoryURL;
}

// NSFileWrapper is broken and doesn't work when called on a directory containing a large number of directories and files.
//because of this it is safer to implement readFromURL than readFromFileWrapper.
//Because NSFileManager does not attempt to recursively open all directories and file when fileExistsAtPath is called
//this works much better.
- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	if (![PBGitBinary path])
	{
		if (outError) {
			NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[PBGitBinary notFoundError]
																 forKey:NSLocalizedRecoverySuggestionErrorKey];
			*outError = [NSError errorWithDomain:PBGitXErrorDomain code:PBGitBinaryNotFoundErrorCode userInfo:userInfo];
		}
		return NO;
	}

	BOOL isDirectory = FALSE;
	[[NSFileManager defaultManager] fileExistsAtPath:[absoluteURL path] isDirectory:&isDirectory];
	if (!isDirectory) {
		if (outError) {
			NSDictionary* userInfo = [NSDictionary dictionaryWithObject:@"Reading files is not supported."
																 forKey:NSLocalizedRecoverySuggestionErrorKey];
			*outError = [NSError errorWithDomain:PBGitXErrorDomain code:PBFileReadingUnsupportedErrorCode userInfo:userInfo];
		}
		return NO;
	}


	NSURL* gitDirURL = [PBGitRepository gitDirForURL:[self fileURL]];
	if (!gitDirURL) {
		if (outError) {
			NSDictionary* userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%@ does not appear to be a git repository.", [[self fileURL] path]]
																 forKey:NSLocalizedRecoverySuggestionErrorKey];
			*outError = [NSError errorWithDomain:PBGitXErrorDomain code:PBNotAGitRepositoryErrorCode userInfo:userInfo];
		}
		return NO;
	}

	[self setFileURL:gitDirURL];
	[self setup];
	[self readCurrentBranch];
	return YES;
}

- (void) setup
{
	config = [[PBGitConfig alloc] initWithRepositoryPath:[[self fileURL] path]];
	self.branches = [NSMutableArray array];
	[self reloadRefs];
	revisionList = [[PBGitRevList alloc] initWithRepository:self];
}

- (id) initWithURL: (NSURL*) path
{
	if (![PBGitBinary path])
		return nil;

	NSURL* gitDirURL = [PBGitRepository gitDirForURL:path];
	if (!gitDirURL)
		return nil;

	if (self = [super init]) {
        [self setFileURL: gitDirURL];
        
        [self setup];
        
        // We don't want the window controller to display anything yet..
        // We'll leave that to the caller of this method.
        #ifndef CLI
            [self addWindowController:[[PBGitWindowController alloc] initWithRepository:self displayDefault:NO]];
        #endif
        
        [self showWindows];
    }
    return self;
}

// The fileURL the document keeps is to the .git dir, but that’s pretty
// useless for display in the window title bar, so we show the directory above
- (NSString*)displayName
{
	NSString* dirName = [[[self fileURL] path] lastPathComponent];
	if ([dirName isEqualToString:@".git"])
		dirName = [[[[self fileURL] path] stringByDeletingLastPathComponent] lastPathComponent];
	NSString* displayName;
	if (![[PBGitRef refFromString:[[self headRef] simpleRef]] type]) {
		displayName = [NSString stringWithFormat:@"%@ (detached HEAD)", dirName];
	} else {
        NSString *headRef = [[self headRef] description];
        NSString *remote = [self remoteForRefName:[[self headRef] refName] presentError:NO];
        if (remote) {
            displayName = [NSString stringWithFormat:@"%@ (branch: %@ — remote: %@)", dirName, headRef, remote];
        } else {
            displayName = [NSString stringWithFormat:@"%@ (branch: %@)", dirName, headRef];
        }
	}

	return displayName;
}

// Get the .gitignore file at the root of the repository
- (NSString*)gitIgnoreFilename
{
	return [[self workingDirectory] stringByAppendingPathComponent:@".gitignore"];
}

- (BOOL)isBareRepository
{
	if([self workingDirectory]) {
		return [PBGitRepository isBareRepository:[self workingDirectory]];
	} else {
		return true;
	}
}

// Overridden to create our custom window controller
- (void)makeWindowControllers
{
#ifndef CLI
	[self addWindowController: [[PBGitWindowController alloc] initWithRepository:self displayDefault:YES]];
#endif
}

- (PBGitWindowController *)windowController
{
	if ([[self windowControllers] count] == 0)
		return NULL;
	
	return [[self windowControllers] objectAtIndex:0];
}

- (void) addRef: (PBGitRef *) ref fromParameters: (NSArray *) components
{
	NSString* type = [components objectAtIndex:1];

	NSString* sha;
	if ([type isEqualToString:@"tag"] && [components count] == 4)
		sha = [components objectAtIndex:3];
	else
		sha = [components objectAtIndex:2];

	NSMutableArray* curRefs;
	if (curRefs = [refs objectForKey:sha])
		[curRefs addObject:ref];
	else
		[refs setObject:[NSMutableArray arrayWithObject:ref] forKey:sha];
}

// reloadRefs: reload all refs in the repository, like in readRefs
// To stay compatible, this does not remove a ref from the branches list
// even after it has been deleted.
// returns YES when a ref was changed
- (BOOL) reloadRefs
{
	_headRef = nil; 
	BOOL ret = NO;

	refs = [NSMutableDictionary dictionary];

    NSString * binPath = [PBGitBinary path];
    NSString * dirPath = [[self fileURL] path];
	NSString* output = [PBEasyPipe outputForCommand:binPath
										   withArgs:[NSArray arrayWithObjects:@"for-each-ref", @"--format=%(refname) %(objecttype) %(objectname)"
													 " %(*objectname)", @"refs", nil]
											  inDir:dirPath];
	NSArray* lines = [output componentsSeparatedByString:@"\n"];

	for (NSString* line in lines) {
		// If its an empty line, skip it (e.g. with empty repositories)
		if ([line length] == 0)
			continue;

		NSArray* components = [line componentsSeparatedByString:@" "];

		// First do the ref matching. If this ref is new, add it to our ref list
		PBGitRef *newRef = [PBGitRef refFromString:[components objectAtIndex:0]];
		PBGitRevSpecifier* revSpec = [[PBGitRevSpecifier alloc] initWithRef:newRef];
		if ([self addBranch:revSpec] != revSpec)
			ret = YES;

		// Also add this ref to the refs list
		[self addRef:newRef fromParameters:components];
	}

	// Add an "All branches" option in the branches list
	[self addBranch:[PBGitRevSpecifier allBranchesRevSpec]];
	[self addBranch:[PBGitRevSpecifier localBranchesRevSpec]];

	[[[self windowController] window] setTitle:[self displayName]];

	return ret;
}

- (void) lazyReload
{
	if (!hasChanged)
		return;

	[self reloadRefs];
	[self.revisionList reload];
	hasChanged = NO;
}

- (PBGitRevSpecifier *)headRef
{
	if (_headRef)
		return _headRef;

	NSString* branch = [self parseSymbolicReference: @"HEAD"];
	if (branch && [branch hasPrefix:@"refs/heads/"])
		_headRef = [[PBGitRevSpecifier alloc] initWithRef:[PBGitRef refFromString:branch]];
	else
		_headRef = [[PBGitRevSpecifier alloc] initWithRef:[PBGitRef refFromString:@"HEAD"]];

	return _headRef;
}

- (NSString *) headSHA
{
    return [self outputForCommand:@"rev-list -1 HEAD"];
}

- (PBGitCommit *) headCommit
{
    char const *hex = [[self headSHA] UTF8String];
    git_oid sha;
    if (git_oid_mkstr(&sha, hex) == GIT_SUCCESS)
        return [PBGitCommit commitWithRepository:self andSha:sha];
    return nil;
}

- (NSString *) realSHAForRev:(PBGitRevSpecifier *)rev
{
    if (![rev isSimpleRef])
        return nil;
    
    return [self outputForArguments:[NSArray arrayWithObjects:@"rev-list", @"-1", [rev refName], nil]];
}

- (PBGitCommit *) commitForRev:(PBGitRevSpecifier *)rev
{
    char const *hex = [[self realSHAForRev:rev] UTF8String];
    git_oid sha;
    if (git_oid_mkstr(&sha, hex) == GIT_SUCCESS)
        return [PBGitCommit commitWithRepository:self andSha:sha];
    return nil;
}


- (BOOL) checkRefFormat:(NSString *)refName
{
	int ret = 1;
	[self outputForArguments:[NSArray arrayWithObjects:@"check-ref-format", refName, nil] retValue:&ret];
    if (ret)
        return NO;
    return YES;
}

// the active branch is the currently viewed branch, unless the view is for all or local 
// branches, in which case it's the currently checked out branch
// this is used by some actions to determine what branch to act on
- (PBGitRevSpecifier *)activeBranch
{
    if ([self.currentBranch isAllBranchesRev] || [self.currentBranch isLocalBranchesRev])
        return [self headRef];
    
    return self.currentBranch;
}

- (void) readCurrentBranch
{
    PBGitRevSpecifier *branch = [self addBranch:[self headRef]];
    if ([self.currentBranch isAllBranchesRev] || [self.currentBranch isLocalBranchesRev])
        self.currentBranch = self.currentBranch; // cause KVO notification
    else
        self.currentBranch = branch;
}

- (NSString *) remoteForRefName:(NSString *)refName presentError:(BOOL)shouldPresentError
{
	NSString *remote = [[self config] valueForKeyPath:[NSString stringWithFormat:@"branch.%@.remote", refName]];
    if (remote) 
        return remote;
    
	int ret = 1;
	NSString *rval = [self outputForCommand:@"remote" retValue:&ret];
    if (![rval isEqualToString:@""]) {
        NSArray *remotes = [rval componentsSeparatedByString:@"\n"];
        for (NSString *remoteName in remotes) {
        	if ([remoteName isEqualToString:refName])
                return refName;
        }
    }
    
    if (shouldPresentError) {
        NSError *error = [NSError errorWithDomain:PBGitXErrorDomain code:PBGitInvalidBranchErrorCode 
                                         userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                   [NSString stringWithFormat:@"No remote configured for %@.", refName], NSLocalizedDescriptionKey,
                                                   PBInvalidBranchErrorMessage, NSLocalizedRecoverySuggestionErrorKey,
                                                   nil]];
        [self.windowController showErrorSheet:error];
    }
    return nil;
}

- (NSString *) workingDirectory
{
    NSString * dotGitSuffix = @"/.git";
	if ([[[self fileURL] path] hasSuffix:dotGitSuffix])
		return [[[self fileURL] path] substringToIndex:[[[self fileURL] path] length] - [dotGitSuffix length]];
	else if ([[self outputForCommand:@"rev-parse --is-inside-work-tree"] isEqualToString:@"true"])
		return [PBGitBinary path];
	
	return nil;
}	

#pragma mark Repository commands

- (BOOL) fetchRemote:(PBGitRevSpecifier *)rev presentError:(BOOL)shouldPresentError
{
    NSString *branchName = [rev refName];
	NSString *remote = [self remoteForRefName:branchName presentError:shouldPresentError];
    if (!remote) {
        NSLog(@"%s branch: %@", _cmd, branchName);
        return NO;
    }
    
	int ret = 1;
    NSString *command = nil;
    if ([remote isEqualToString:[rev simpleRef]]) 
        command = [NSString stringWithFormat:@"fetch %@", remote];
    else
        command = [NSString stringWithFormat:@"fetch %@ %@", remote, branchName];
    NSLog(@"%s %@", _cmd, command);
	NSString *rval = [self outputForCommand:command retValue:&ret];
	if (ret) {
        if (shouldPresentError) {
            NSString *description = [NSString stringWithFormat:@"Fetch failed for %@/%@.", remote, branchName];
            NSString *info = [NSString stringWithFormat:@"There was an error fetching from the remote repository.\n\ncommand: git $@\n%d\n%@", command, ret, rval];
            NSError *error = [NSError errorWithDomain:PBGitXErrorDomain code:PBGitFetchErrorCode 
                                             userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                       description, NSLocalizedDescriptionKey,
                                                       info, NSLocalizedRecoverySuggestionErrorKey,
                                                       nil]];
            [self.windowController showErrorSheet:error];
        }
		return NO;
	}
    [self reloadRefs];
    return YES;
}

- (BOOL) pullRemote:(PBGitRevSpecifier *)rev presentError:(BOOL)shouldPresentError
{
    NSString *branchName = [rev refName];
	NSString *remote = [self remoteForRefName:branchName presentError:shouldPresentError];
    if (!remote) {
        NSLog(@"%s branch: %@", _cmd, branchName);
        return NO;
    }
    
	int ret = 1;
    NSString *command = nil;
    if ([remote isEqualToString:[rev simpleRef]]) 
        command = [NSString stringWithFormat:@"pull %@", remote];
    else
        command = [NSString stringWithFormat:@"pull %@ %@", remote, branchName];
    NSLog(@"%s %@", _cmd, command);
	NSString *rval = [self outputForCommand:command retValue:&ret];
	if (ret) {
        if (shouldPresentError) {
            NSString *description = [NSString stringWithFormat:@"Pull failed for %@/%@.", remote, branchName];
            NSString *info = [NSString stringWithFormat:@"There was an error pulling from the remote repository.\n\ncommand: git %@\n%d\n%@", command, ret, rval];
            NSError *error = [NSError errorWithDomain:PBGitXErrorDomain code:PBGitPullErrorCode 
                                             userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                       description, NSLocalizedDescriptionKey,
                                                       info, NSLocalizedRecoverySuggestionErrorKey,
                                                       nil]];
            [self.windowController showErrorSheet:error];
        }
		return NO;
	}
    [self reloadRefs];
    return YES;
}

- (BOOL) pushRemote:(PBGitRevSpecifier *)rev presentError:(BOOL)shouldPresentError
{
    NSString *branchName = [rev refName];
	NSString *remote = [self remoteForRefName:branchName presentError:shouldPresentError];
    if (!remote) {
        NSLog(@"%s branch: %@", _cmd, branchName);
        return NO;
    }
    
	int ret = 1;
    NSString *command = nil;
    if ([remote isEqualToString:[rev simpleRef]]) 
        command = [NSString stringWithFormat:@"push %@", remote];
    else
        command = [NSString stringWithFormat:@"push %@ %@", remote, branchName];
    NSLog(@"%s %@", _cmd, command);
	NSString *rval = [self outputForCommand:command retValue:&ret];
	if (ret) {
        if (shouldPresentError) {
            NSString *description = [NSString stringWithFormat:@"Push failed for %@/%@.", remote, branchName];
            NSString *info = [NSString stringWithFormat:@"There was an error pushing to the remote repository.\n\ncommand: git %@\n%d\n%@", command, ret, rval];
            NSError *error = [NSError errorWithDomain:PBGitXErrorDomain code:PBGitPushErrorCode 
                                             userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                       description, NSLocalizedDescriptionKey,
                                                       info, NSLocalizedRecoverySuggestionErrorKey,
                                                       nil]];
            [self.windowController showErrorSheet:error];
        }
		return NO;
	}
    [self reloadRefs];
    return YES;
}

- (BOOL) checkoutRefName:(NSString *)refName presentError:(BOOL)shouldPresentError
{
	int ret = 1;
	NSString *rval = [self outputInWorkdirForArguments:[NSArray arrayWithObjects:@"checkout", refName, nil] retValue:&ret];
	if (ret) {
        if (shouldPresentError) {
            NSString *info = [NSString stringWithFormat:@"There was an error checking out the branch or commit. Perhaps your working directory is not clean?\n\n%d\n%@", ret, rval];
            NSError *error = [NSError errorWithDomain:PBGitXErrorDomain code:PBGitCheckoutErrorCode 
                                             userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                       @"Checkout failed.", NSLocalizedDescriptionKey,
                                                       info, NSLocalizedRecoverySuggestionErrorKey,
                                                       nil]];
            [self.windowController showErrorSheet:error];
        }
		return NO;
	}
	[self reloadRefs];
	[self readCurrentBranch];
    return YES;
}

// cherry pick only applies to the currently checked out branch
- (BOOL) cherryPickCommit:(PBGitCommit *)commit presentError:(BOOL)shouldPresentError
{
	int ret = 1;
	NSString *rval = [self outputInWorkdirForArguments:[NSArray arrayWithObjects:@"cherry-pick", [commit realSha], nil] retValue: &ret];
	if (ret) {
        if (shouldPresentError) {
            NSString *info = [NSString stringWithFormat:@"There was an error applying the commit to the branch. Perhaps your working directory is not clean?\n\n%d\n%@", ret, rval];
            NSError *error = [NSError errorWithDomain:PBGitXErrorDomain code:PBGitCherryPickErrorCode 
                                             userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                       @"Cherry pick failed.", NSLocalizedDescriptionKey,
                                                       info, NSLocalizedRecoverySuggestionErrorKey,
                                                       nil]];
            [self.windowController showErrorSheet:error];
        }
		return NO;
	}
	[self reloadRefs];
	[self readCurrentBranch];
    return YES;
}

// a nil upstream means the default remote branch
// a nil branch means the head ref
- (BOOL) rebaseBranch:(PBGitRevSpecifier *)branch onUpstream:(PBGitRevSpecifier *)upstream presentError:(BOOL)shouldPresentError
{
    NSString *branchRefName = nil;
    if (branch)
        branchRefName = [branch refName];
    else
        branchRefName = [[self headRef] refName];
    
    NSString *upstreamRefName = nil;
    if (upstream)
        upstreamRefName = [upstream refName];
    else {
        NSString *remote = [self remoteForRefName:branchRefName presentError:shouldPresentError];
        if (!remote) {
            NSLog(@"%s branch: %@", _cmd, branchRefName);
            return NO;
        }
        upstreamRefName = [NSString stringWithFormat:@"%@/%@", remote, branchRefName];
    }
    
	int ret = 1;
    NSArray * args = [NSArray arrayWithObjects:@"rebase", upstreamRefName, branchRefName, nil]; 
	NSString *rval = [self outputInWorkdirForArguments:args retValue:&ret];
	if (ret) {
        if (shouldPresentError) {
            NSString *description = [NSString stringWithFormat:@"Rebase of %@ on %@ failed.", branchRefName, upstreamRefName];
            NSString *info = [NSString stringWithFormat:@"There was an error rebasing the branch.\n\n%d\n%@", ret, rval];
            NSError *error = [NSError errorWithDomain:PBGitXErrorDomain code:PBGitRebaseErrorCode 
                                             userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                       description, NSLocalizedDescriptionKey,
                                                       info, NSLocalizedRecoverySuggestionErrorKey,
                                                       nil]];
            [self.windowController showErrorSheet:error];
        }
		return NO;
	}
	[self reloadRefs];
    [self readCurrentBranch];
    return YES;
}

// a nil branch means the head ref
// a nil onSHA is not allowed
- (BOOL) rebaseBranch:(PBGitRevSpecifier *)branch onSHA:(NSString *)upstreamSHA presentError:(BOOL)shouldPresentError
{
    if (!upstreamSHA)
        return NO;
        
    NSString *branchRefName = nil;
    if (branch)
        branchRefName = [branch refName];
    else
        branchRefName = [[self headRef] refName];
    
	int ret = 1;
    NSArray * args = [NSArray arrayWithObjects:@"rebase", upstreamSHA, branchRefName, nil]; 
	NSString *rval = [self outputInWorkdirForArguments:args retValue:&ret];
	if (ret) {
        if (shouldPresentError) {
            NSString *description = [NSString stringWithFormat:@"Rebase of %@ on %@ failed.", branchRefName, [upstreamSHA substringToIndex:8]];
            NSString *info = [NSString stringWithFormat:@"There was an error rebasing the branch.\n\n%d\n%@", ret, rval];
            NSError *error = [NSError errorWithDomain:PBGitXErrorDomain code:PBGitRebaseErrorCode 
                                             userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                       description, NSLocalizedDescriptionKey,
                                                       info, NSLocalizedRecoverySuggestionErrorKey,
                                                       nil]];
            [self.windowController showErrorSheet:error];
        }
		return NO;
	}
	[self reloadRefs];
    [self readCurrentBranch];
    return YES;
}

- (BOOL) createBranch:(NSString *)branchRefName onSHA:(NSString *)sha presentError:(BOOL)shouldPresentError
{
	int ret = 1;
	NSString *rval = [self outputForArguments:[NSArray arrayWithObjects:@"update-ref", @"-mCreate branch from GitX", branchRefName, sha, @"0000000000000000000000000000000000000000", nil] retValue:&ret];
	if (ret) {
        if (shouldPresentError) {
            NSString *description = [NSString stringWithFormat:@"Create Branch failed for %@.", branchRefName];
            NSString *info = [NSString stringWithFormat:@"There was an error creatin a branch in the repository.\n\n%d\n%@", ret, rval];
            NSError *error = [NSError errorWithDomain:PBGitXErrorDomain code:PBGitCreateBranchErrorCode 
                                             userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                       description, NSLocalizedDescriptionKey,
                                                       info, NSLocalizedRecoverySuggestionErrorKey,
                                                       nil]];
            [self.windowController showErrorSheet:error];
        }
		return NO;
	}
    [self reloadRefs];
    return YES;
}
		
// Returns either this object, or an existing, equal object
- (PBGitRevSpecifier*) addBranch:(PBGitRevSpecifier*)rev
{
	if ([[rev parameters] count] == 0)
		rev = [self headRef];

	// First check if the branch doesn't exist already
	for (PBGitRevSpecifier* r in branches)
		if ([rev isEqualTo: r])
			return r;

	[self willChangeValueForKey:@"branches"];
	[branches addObject: rev];
	[self didChangeValueForKey:@"branches"];
	return rev;
}

- (BOOL) removeBranch:(PBGitRevSpecifier *)rev
{
	for (PBGitRevSpecifier *r in branches) {
		if ([rev isEqualTo:r]) {
			[self willChangeValueForKey:@"branches"];
			[branches removeObject:r];
			[self didChangeValueForKey:@"branches"];
			return TRUE;
		}
	}
	return FALSE;
}

- (BOOL) addTag:(NSString *)tagName message:(NSString *)message forCommit:(PBGitCommit *)commit presentError:(BOOL)shouldPresentError
{    
    NSMutableArray *arguments = [NSMutableArray arrayWithObject:@"tag"];
    
    // if there is a message then make this an annotated tag
    if (message && ![message isEqualToString:@""]) {
        [arguments addObject:@"-a"];
        [arguments addObject:[@"-m" stringByAppendingString:message]];
    }
    
    [arguments addObject:tagName];
    
    if (commit)
        [arguments addObject:[commit realSha]];
    
	int ret = 1;
	NSString *rval = [self outputForArguments:arguments retValue:&ret];
	if (ret) {
        if (shouldPresentError) {
            NSString *description = [NSString stringWithFormat:@"Add Tag failed for %@.", tagName];
            NSString *info = [NSString stringWithFormat:@"There was an error adding the tag.\n\n%d\n%@", ret, rval];
            NSError *error = [NSError errorWithDomain:PBGitXErrorDomain code:PBGitAddTagErrorCode 
                                             userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                       description, NSLocalizedDescriptionKey,
                                                       info, NSLocalizedRecoverySuggestionErrorKey,
                                                       nil]];
            [self.windowController showErrorSheet:error];
        }
		return NO;
	}
	[self reloadRefs];
    return YES;
}

- (BOOL) addRemote:(NSString *)remoteName forURL:(NSString *)remoteURL presentError:(BOOL)shouldPresentError
{
	int ret = 1;
	NSString *rval = [self outputInWorkdirForArguments:[NSArray arrayWithObjects:@"remote",  @"add", @"-f", remoteName, remoteURL, nil] retValue: &ret];
	if (ret) {
        if (shouldPresentError) {
            NSString *description = [NSString stringWithFormat:@"Add Remote failed for %@.", remoteName];
            NSString *info = [NSString stringWithFormat:@"There was an error adding the remote.\nURL: %@\n\n%d\n%@", remoteURL, ret, rval];
            NSError *error = [NSError errorWithDomain:PBGitXErrorDomain code:PBGitAddRemoteErrorCode 
                                             userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                       description, NSLocalizedDescriptionKey,
                                                       info, NSLocalizedRecoverySuggestionErrorKey,
                                                       nil]];
            [self.windowController showErrorSheet:error];
        }
		return NO;
	}
	[self reloadRefs];
    return YES;
}	


#pragma mark low level 

- (int) returnValueForCommand:(NSString *)cmd
{
	int i;
	[self outputForCommand:cmd retValue: &i];
	return i;
}

- (NSFileHandle*) handleForArguments:(NSArray *)args
{
	NSString* gitDirArg = [@"--git-dir=" stringByAppendingString:[[self fileURL] path]];
	NSMutableArray* arguments =  [NSMutableArray arrayWithObject: gitDirArg];
	[arguments addObjectsFromArray: args];
	return [PBEasyPipe handleForCommand:[PBGitBinary path] withArgs:arguments];
}

- (NSFileHandle*) handleInWorkDirForArguments:(NSArray *)args
{
	NSString* gitDirArg = [@"--git-dir=" stringByAppendingString:[[self fileURL] path]];
	NSMutableArray* arguments =  [NSMutableArray arrayWithObject: gitDirArg];
	[arguments addObjectsFromArray: args];
	return [PBEasyPipe handleForCommand:[PBGitBinary path] withArgs:arguments inDir:[self workingDirectory]];
}

- (NSFileHandle*) handleForCommand:(NSString *)cmd
{
	NSArray* arguments = [cmd componentsSeparatedByString:@" "];
	return [self handleForArguments:arguments];
}

- (NSString*) outputForCommand:(NSString *)cmd
{
	NSArray* arguments = [cmd componentsSeparatedByString:@" "];
	return [self outputForArguments: arguments];
}

- (NSString*) outputForCommand:(NSString *)str retValue:(int *)ret;
{
	NSArray* arguments = [str componentsSeparatedByString:@" "];
	return [self outputForArguments: arguments retValue: ret];
}

- (NSString*) outputForArguments:(NSArray*) arguments
{
	return [PBEasyPipe outputForCommand:[PBGitBinary path] withArgs:arguments inDir: [[self fileURL] path]];
}

- (NSString*) outputInWorkdirForArguments:(NSArray*) arguments
{
	return [PBEasyPipe outputForCommand:[PBGitBinary path] withArgs:arguments inDir: [self workingDirectory]];
}

- (NSString*) outputInWorkdirForArguments:(NSArray *)arguments retValue:(int *)ret
{
	return [PBEasyPipe outputForCommand:[PBGitBinary path] withArgs:arguments inDir:[self workingDirectory] retValue: ret];
}

- (NSString*) outputForArguments:(NSArray *)arguments retValue:(int *)ret
{
	return [PBEasyPipe outputForCommand:[PBGitBinary path] withArgs:arguments inDir: [[self fileURL] path] retValue: ret];
}

- (NSString*) outputForArguments:(NSArray *)arguments inputString:(NSString *)input retValue:(int *)ret
{
	return [PBEasyPipe outputForCommand:[PBGitBinary path]
							   withArgs:arguments
								  inDir:[self workingDirectory]
							inputString:input
							   retValue: ret];
}

- (NSString *)outputForArguments:(NSArray *)arguments inputString:(NSString *)input byExtendingEnvironment:(NSDictionary *)dict retValue:(int *)ret
{
	return [PBEasyPipe outputForCommand:[PBGitBinary path]
							   withArgs:arguments
								  inDir:[self workingDirectory]
				 byExtendingEnvironment:dict
							inputString:input
							   retValue: ret];
}

- (BOOL)executeHook:(NSString *)name output:(NSString **)output
{
	return [self executeHook:name withArgs:[NSArray array] output:output];
}

- (BOOL)executeHook:(NSString *)name withArgs:(NSArray *)arguments output:(NSString **)output
{
	NSString *hookPath = [[[[self fileURL] path] stringByAppendingPathComponent:@"hooks"] stringByAppendingPathComponent:name];
	if (![[NSFileManager defaultManager] isExecutableFileAtPath:hookPath])
		return TRUE;

	NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
		[self fileURL].path, @"GIT_DIR",
		[[self fileURL].path stringByAppendingPathComponent:@"index"], @"GIT_INDEX_FILE",
		nil
	];

	int ret = 1;
	NSString *_output =	[PBEasyPipe outputForCommand:hookPath withArgs:arguments inDir:[self workingDirectory] byExtendingEnvironment:info inputString:nil retValue:&ret];

	if (output)
		*output = _output;

	return ret == 0;
}

- (NSString *)parseReference:(NSString *)reference
{
	int ret = 1;
	NSString *ref = [self outputForArguments:[NSArray arrayWithObjects: @"rev-parse", @"--verify", reference, nil] retValue: &ret];
	if (ret)
		return nil;

	return ref;
}

- (NSString*) parseSymbolicReference:(NSString*) reference
{
	NSString* ref = [self outputForArguments:[NSArray arrayWithObjects: @"symbolic-ref", @"-q", reference, nil]];
	if ([ref hasPrefix:@"refs/"])
		return ref;

	return nil;
}

- (void) finalize
{
	NSLog(@"Dealloc of repository");
	[super finalize];
}
@end
