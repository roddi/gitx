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
    NSString *headRef = [[commit.repository headRef] refName];
    
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
    
    // merge HEAD with ref
    item = [[PBRefMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Merge %@ with %@", headRef, targetRef]
                                         action:@selector(mergeWithRef:)
                                  keyEquivalent:@""];
    if ([commit isOnActiveBranch])
        [item setEnabled:NO];
    [array addObject:item];

    // delete ref
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
    
    // merge HEAD with commit
    menuItem = [[PBRefMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Merge %@ here", headBranch]
                                         action:@selector(mergeWithCommit:)
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


+ (NSUInteger) addLocalBranches:(NSMutableArray *)localBranches toMenu:(NSMenu *)toolbarMenu target:(id)target action:(SEL)action
{    
    for (PBGitRevSpecifier *rev in localBranches) {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[rev description] action:action keyEquivalent:@""];
        [item setTarget:target];
        [item setRepresentedObject:rev];
        [toolbarMenu addItem:item];
    }
    
    return [localBranches count];
}

+ (NSUInteger) addRemoteBranches:(NSMutableArray *)remoteBranches toMenu:(NSMenu *)toolbarMenu target:(id)target action:(SEL)action
{    
	NSMenu *currentMenu = nil;
	for (PBGitRevSpecifier *rev in remoteBranches) {
		NSString *ref = [rev simpleRef];
		NSArray *components = [ref componentsSeparatedByString:@"/"];
        
		NSString *remoteName = [components objectAtIndex:2];
		if (![[currentMenu title] isEqualToString:remoteName]) {
			currentMenu = [[NSMenu alloc] initWithTitle:remoteName];
			NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:remoteName action:NULL keyEquivalent:@""];
			[item setSubmenu:currentMenu];
			[toolbarMenu addItem:item];
		}
        
		NSString *branchName = [[components subarrayWithRange:NSMakeRange(3, [components count] - 3)] componentsJoinedByString:@"/"];
		NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:branchName action:action keyEquivalent:@""];
		[item setTarget:target];
		[item setRepresentedObject:rev];
		[currentMenu addItem:item];
	}
    
    return [remoteBranches count];
}

+ (NSUInteger) addTrackingRemotes:(NSMutableArray *)remoteBranches toMenu:(NSMenu *)toolbarMenu target:(id)target action:(SEL)action
{    
    NSString *currentRemoteName = nil;
    for (PBGitRevSpecifier *rev in remoteBranches) {
        NSString *ref = [rev simpleRef];
        NSArray *components = [ref componentsSeparatedByString:@"/"];
        
        NSString *remoteName = [components objectAtIndex:2];
        if (![currentRemoteName isEqualToString:remoteName]) {
            currentRemoteName = remoteName;
            
            NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:currentRemoteName action:action keyEquivalent:@""];
            [item setTarget:target];
            [item setRepresentedObject:[[PBGitRevSpecifier alloc] initWithRef:[PBGitRef refFromString:currentRemoteName]]];
            [toolbarMenu addItem:item];
        }
    }
    
    return [remoteBranches count];
}

+ (NSUInteger) addTags:(NSMutableArray *)tags toMenu:(NSMenu *)toolbarMenu target:(id)target action:(SEL)action
{
    NSMenu *tagMenu = [[NSMenu alloc] initWithTitle:@""];
    for (PBGitRevSpecifier *rev in tags) {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[rev description] action:action keyEquivalent:@""];
        [item setTarget:target];
        [item setRepresentedObject:rev];
        [tagMenu addItem:item];
    }		
    
    NSMenuItem *tagItem = [[NSMenuItem alloc] initWithTitle:@"Tags" action:NULL keyEquivalent:@""];
    [tagItem setSubmenu:tagMenu];
    [toolbarMenu addItem:tagItem];
    
    return [tags count];
}

+ (NSUInteger) addOtherItems:(NSMutableArray *)other toMenu:(NSMenu *)toolbarMenu target:(id)target action:(SEL)action
{
	for (PBGitRevSpecifier *rev in other)
	{
		NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[rev description] action:action keyEquivalent:@""];
		[item setRepresentedObject:rev];
		[item setTarget:target];
		[toolbarMenu addItem:item];
	}
    
    return [other count];
}


+ (NSMenu *) pullDownMenuForRemotes:(NSMutableArray *)remoteBranches target:(id)target action:(SEL)action
{
    if (![remoteBranches count])
        return nil;
    
    NSMenu *toolbarMenu = [[NSMenu alloc] initWithTitle:@""];
    
    [self addTrackingRemotes:remoteBranches toMenu:toolbarMenu target:target action:action];
    [toolbarMenu addItem:[NSMenuItem separatorItem]];
    [self addRemoteBranches:remoteBranches toMenu:toolbarMenu target:target action:action];
    
    return toolbarMenu;
}

+ (NSMenu *) pullDownMenuForLocalBranches:(NSMutableArray *)localBranches remotes:(NSMutableArray *)remoteBranches tags:(NSMutableArray *)tags target:(id)target action:(SEL)action
{
    NSMenu *toolbarMenu = [[NSMenu alloc] initWithTitle:@""];
    
    NSUInteger itemCount = [self addLocalBranches:localBranches toMenu:toolbarMenu target:target action:action];
    
    if ([remoteBranches count]) {
        if (itemCount)
            [toolbarMenu addItem:[NSMenuItem separatorItem]];
        itemCount += [self addRemoteBranches:remoteBranches toMenu:toolbarMenu target:target action:action];
    }
    
    if ([tags count]) {
        if (itemCount)
            [toolbarMenu addItem:[NSMenuItem separatorItem]];
        itemCount += [self addTags:tags toMenu:toolbarMenu target:target action:action];
    }
    
    return toolbarMenu;
}

+ (NSMenu *) pullDownMenuForLocalBranches:(NSMutableArray *)localBranches remotes:(NSMutableArray *)remoteBranches tags:(NSMutableArray *)tags other:(NSMutableArray *)other target:(id)target action:(SEL)action
{
    NSMenu *toolbarMenu = [[NSMenu alloc] initWithTitle:@""];
    
    NSUInteger itemCount = [self addLocalBranches:localBranches toMenu:toolbarMenu target:target action:action];
    
    if ([remoteBranches count]) {
        if (itemCount)
            [toolbarMenu addItem:[NSMenuItem separatorItem]];
        NSMenu *subMenu = [[NSMenu alloc] initWithTitle:@""];
        itemCount += [self addRemoteBranches:remoteBranches toMenu:subMenu target:target action:action];
        NSMenuItem *remoteItem = [[NSMenuItem alloc] initWithTitle:@"Remotes" action:nil keyEquivalent:@""];
        [remoteItem setSubmenu:subMenu];
        [toolbarMenu addItem:remoteItem];
    }
    
    if ([tags count]) {
        if (itemCount && ![remoteBranches count])
            [toolbarMenu addItem:[NSMenuItem separatorItem]];
        itemCount += [self addTags:tags toMenu:toolbarMenu target:target action:action];
    }
    
    if ([other count]) {
        if (itemCount)
            [toolbarMenu addItem:[NSMenuItem separatorItem]];
        [self addOtherItems:other toMenu:toolbarMenu target:target action:action];
    }
    
    return toolbarMenu;
}


@end
