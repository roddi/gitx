//
//  PBRefMenuItem.m
//  GitX
//
//  Created by Pieter de Bie on 01-11-08.
//  Copyright 2008 Pieter de Bie. All rights reserved.
//

#import "PBRefMenuItem.h"


@implementation PBRefMenuItem
@synthesize ref, commit;

+ (PBRefMenuItem *)addRemoteMethod:(BOOL)hasRemote title:(NSString *)title action:(SEL)selector
{
	PBRefMenuItem *item = [[PBRefMenuItem alloc] initWithTitle:title action:selector keyEquivalent:@""];
	[item setEnabled:hasRemote];
	return item;
}

+ (NSArray *)defaultMenuItemsForRef:(PBGitRef *)ref commit:(PBGitCommit *)commit target:(id)target
{
	NSMutableArray *array = [NSMutableArray array];
	NSString *type = [ref type];
	if ([type isEqualToString:@"remote"])
		type = @"remote branch";
	else if ([type isEqualToString:@"head"])
		type = @"branch";
    
    NSString *targetRef = [ref shortName];
	NSString *remote = [commit.repository remoteForRefName:targetRef presentError:NO];
	BOOL hasRemote = (remote ? YES : NO);
    NSString *activeBranch = [[commit.repository activeBranch] refName];
    
	if ([type isEqualToString:@"branch"]) {
        if (hasRemote) {        
            PBRefMenuItem *item = [[PBRefMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Remote: %@", remote] action:nil keyEquivalent:@""];
            [item setEnabled:NO];
            [array addObject:item];
            PBRefMenuItem *sepItem = [PBRefMenuItem separatorItem];
            [array addObject:sepItem];
        }
        
        [array addObject:[self addRemoteMethod:hasRemote title:[NSString stringWithFormat:@"Push %@ to remote", targetRef] action:@selector(pushRemoteForRef:)]];
		[array addObject:[self addRemoteMethod:hasRemote title:[NSString stringWithFormat:@"Pull down latest"] action:@selector(pullRemoteForRef:)]];
		//[array addObject:[self addRemoteMethod:hasRemote title:[NSString stringWithFormat:@"Rebase %@ starting here", activeBranch] action:@selector(rebaseOnUpstreamRef:)]];
    }
    
    // view tag info
    if ([type isEqualToString:@"tag"])
		[array addObject:[[PBRefMenuItem alloc] initWithTitle:@"View tag info"
													   action:@selector(showTagInfoSheet:)
												keyEquivalent:@""]];
    
    // checkout ref
    PBRefMenuItem *item = [[PBRefMenuItem alloc] initWithTitle:[@"Checkout " stringByAppendingString:targetRef]
                                                        action:@selector(checkoutRef:)
                                                 keyEquivalent:@""];
    if ([targetRef isEqualToString:[[[commit repository] headRef] description]])
        [item setEnabled:NO];
    [array addObject:item];
    
    // rebase active branch starting at ref
    item = [[PBRefMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Rebase %@ starting at %@", activeBranch, targetRef]
                                                        action:@selector(rebaseOnUpstreamRef:)
                                                 keyEquivalent:@""];
    if ([commit isOnActiveBranch])
        [item setEnabled:NO];
    [array addObject:item];

    // delet ref
	[array addObject:[[PBRefMenuItem alloc] initWithTitle:[@"Delete " stringByAppendingString:targetRef]
												   action:@selector(showDeleteRefSheet:)
											keyEquivalent: @""]];

	for (PBRefMenuItem *item in array)
	{
		[item setTarget: target];
		[item setRef: ref];
		[item setCommit:commit];
	}

	return array;
}

+ (NSArray *) defaultMenuItemsForCommit:(PBGitCommit *)commit target:(id)target
{
    NSMutableArray *items = [NSMutableArray array];
    NSMenuItem *menuItem = nil;
    NSString *activeBranch = [[commit.repository activeBranch] refName];
    NSString *headBranch = [[commit.repository headRef] refName];
    
    [items addObject:[[PBRefMenuItem alloc] initWithTitle:@"Copy SHA" action:@selector(copySHA:) keyEquivalent:@""]];
    
    [items addObject:[[PBRefMenuItem alloc] initWithTitle:@"Copy Patch" action:@selector(copyPatch:) keyEquivalent:@""]];
    
    [items addObject:[[PBRefMenuItem alloc] initWithTitle:@"Checkout Commit" action:@selector(checkoutCommit:) keyEquivalent:@""]];
    
    // cherry pick (only works on checked out branch)
    menuItem = [[PBRefMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Cherry pick commit to %@", headBranch]
                                             action:@selector(cherryPick:) 
                                      keyEquivalent:@""];
    if ([commit isOnHeadBranch])
        [menuItem setEnabled:NO];
    [items addObject:menuItem];
    
    // rebase active branch starting here
    menuItem = [[PBRefMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Rebase %@ starting here", activeBranch]
                                             action:@selector(rebaseOnUpstreamCommit:)
                                      keyEquivalent:@""];
    if ([commit isOnActiveBranch])
        [menuItem setEnabled:NO];
    [items addObject:menuItem];
    
    [items addObject:[[PBRefMenuItem alloc] initWithTitle:@"Add Tag here" action:@selector(addTagHere:) keyEquivalent:@""]];
    
    [items addObject:[[PBRefMenuItem alloc] initWithTitle:@"Create Branch here" action:@selector(createBranchHere:) keyEquivalent:@""]];
    
	for (PBRefMenuItem *menuItem in items)
	{
		[menuItem setTarget:target];
		[menuItem setCommit:commit];
	}
    
	return items;
}

+ (PBRefMenuItem *)separatorItem {
    PBRefMenuItem * item = (PBRefMenuItem *) [super separatorItem];
    return item;
}

@end
