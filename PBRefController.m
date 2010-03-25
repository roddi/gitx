//
//  PBLabelController.m
//  GitX
//
//  Created by Pieter de Bie on 21-10-08.
//  Copyright 2008 Pieter de Bie. All rights reserved.
//

#import "PBRefController.h"
#import "PBGitRevisionCell.h"
#import "PBRefMenuItem.h"
#import "KBPopUpToolbarItem.h"

@implementation PBRefController

- (void)awakeFromNib
{
    [checkoutItem setPopUpDelay:0.0];
    [mergeItem setPopUpDelay:0.0];
	[commitList registerForDraggedTypes:[NSArray arrayWithObject:@"PBGitRef"]];
	[historyController addObserver:self forKeyPath:@"repository.branches" options:0 context:@"branchChange"];
	[historyController addObserver:self forKeyPath:@"repository.currentBranch" options:0 context:@"currentBranchChange"];
	[self updateBranchMenus];
	[self selectCurrentBranch];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([(NSString *)context isEqualToString: @"branchChange"]) {
		[self updateBranchMenus];
	}
	else if ([(NSString *)context isEqualToString:@"currentBranchChange"]) {
		[self updateBranchMenus];
	}
	else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

#pragma mark Fetch

// called from toolbar button and the Repository menu
- (void) fetchCurrentRemote:(id)sender
{
    PBGitRevSpecifier *rev = [historyController.repository activeBranch];
    
    if ([historyController.repository fetchRemote:rev presentError:YES]) {
        [commitController rearrangeObjects];
        [historyController updateView];
    }
}

// called from toolbar menu
- (void) fetchFromRemote:(NSMenuItem *)sender
{
    PBGitRevSpecifier *rev = [sender representedObject];
    
    if ([historyController.repository fetchRemote:rev presentError:YES]) {
        [commitController rearrangeObjects];
        [historyController updateView];
    }
}

#pragma mark Pull

// called by the contextual menu for branches with remotes
- (void) pullRemoteForRef:(PBRefMenuItem *)sender
{
    PBGitRevSpecifier *rev = [[PBGitRevSpecifier alloc] initWithRef:[sender ref]];
    
    if ([historyController.repository pullRemote:rev presentError:YES]) {
        [commitController rearrangeObjects];
        [historyController updateView];
    }
}

// called by the toolbar button and the Repository menu
- (void) pullCurrentRemote:(id)sender
{
    PBGitRevSpecifier *rev = [historyController.repository activeBranch];
    
    if ([historyController.repository pullRemote:rev presentError:YES]) {
        [commitController rearrangeObjects];
        [historyController updateView];
    }
}

// called by toolbar menu
- (void) pullFromRemote:(NSMenuItem *)sender
{
    PBGitRevSpecifier *rev = [sender representedObject];
    
    NSError *error = nil;
    if ([historyController.repository pullRemote:rev presentError:YES]) {
        [commitController rearrangeObjects];
        [historyController updateView];
    }
}

#pragma mark Push

// called by the contextual menu for branches with remotes
- (void) pushRemoteForRef:(PBRefMenuItem *)sender
{
    PBGitRevSpecifier *rev = [[PBGitRevSpecifier alloc] initWithRef:[sender ref]];
    
    [historyController.repository pushRemote:rev presentError:YES];
}

// called by the toolbar button and the Repository menu
- (void) pushCurrentRemote:(id)sender
{
    PBGitRevSpecifier *rev = [historyController.repository activeBranch];
    
    [historyController.repository pushRemote:rev presentError:YES];
    [historyController updateView];
}

// called by toolbar menu
- (void) pushToRemote:(NSMenuItem *)sender
{
    PBGitRevSpecifier *rev = [sender representedObject];
    
    [historyController.repository pushRemote:rev presentError:YES];
}

#pragma mark Merge

// called by the contextual menu for branches
- (void) mergeWithRef:(PBRefMenuItem *)sender
{
    PBGitRevSpecifier *rev = [[PBGitRevSpecifier alloc] initWithRef:[sender ref]];
    
    if ([historyController.repository mergeWithBranch:rev presentError:YES]) {
        [commitController rearrangeObjects];
        [historyController updateView];
    }
}

// called by the contextual menu for commits
- (void) mergeWithCommit:(PBRefMenuItem *)sender
{
    PBGitCommit *commit = [sender commit];
    
    if ([historyController.repository mergeWithCommit:commit presentError:YES]) {
        [commitController rearrangeObjects];
        [historyController updateView];
    }
}

// called by toolbar menu
- (void) mergeWithBranch:(NSMenuItem *)sender
{
    PBGitRevSpecifier *rev = [sender representedObject];
    
    if ([historyController.repository mergeWithBranch:rev presentError:YES]) {
        [commitController rearrangeObjects];
        [historyController updateView];
    }
}

#pragma mark Checkout

// called by the contextual menu for a branch, remote or tag
- (void) checkoutRef:(PBRefMenuItem *)sender
{
    NSString *refName = [[sender ref] shortName];
    
    if ([historyController.repository checkoutRefName:refName presentError:YES]) {
        [commitController rearrangeObjects];
        [historyController updateView];
    }
}

// called by the contextual menu for a commit
- (void) checkoutCommit:(PBRefMenuItem *)sender
{
    NSString *refName = [[sender commit] realSha];
    
    if ([historyController.repository checkoutRefName:refName presentError:YES]) {
        [commitController rearrangeObjects];
        [historyController updateView];
    }
}

// called by the toolbar menu for a branch, remote or tag
- (void) checkoutFromRef:(NSMenuItem *)sender
{
    NSString *refName = [[sender representedObject] description];
    
    if ([historyController.repository checkoutRefName:refName presentError:YES]) {
        [commitController rearrangeObjects];
        [historyController updateView];
    }
}

#pragma mark Cherry Pick

// called by the contextual menu for commits
- (void) cherryPick:(PBRefMenuItem *)sender
{
    PBGitCommit *commit = [sender commit];
    
    if ([historyController.repository cherryPickCommit:commit presentError:YES]) {
        [commitController rearrangeObjects];
        [historyController updateView];
    }
}

#pragma mark Rebase

// called by the contextual menu for branches (with remotes???)
- (void) rebaseOnUpstreamRef:(PBRefMenuItem *)sender
{
    PBGitRevSpecifier *upstreamRev = [[PBGitRevSpecifier alloc] initWithRef:[sender ref]];
    PBGitRevSpecifier *currentRev = [historyController.repository activeBranch];
        
    if ([historyController.repository rebaseBranch:currentRev onUpstream:upstreamRev presentError:YES]) {
        [commitController rearrangeObjects];
        [historyController updateView];
    }
}

// called by the contextual menu for commits
- (void) rebaseOnUpstreamCommit:(PBRefMenuItem *)sender
{
    PBGitCommit *commit = [sender commit];
    PBGitRevSpecifier *currentRev = [historyController.repository activeBranch];
    
    if ([historyController.repository rebaseBranch:currentRev onSHA:[commit realSha] presentError:YES]) {
        [commitController rearrangeObjects];
        [historyController updateView];
    }
}

// called by the toolbar button and the Repository menu
- (void)rebaseCurrentBranch:(id)sender
{
    PBGitRevSpecifier *currentRev = [historyController.repository activeBranch];
    
    if ([historyController.repository rebaseBranch:currentRev onUpstream:nil presentError:YES]) {
        [commitController rearrangeObjects];
        [historyController updateView];
    }
}

// called from the toolbar menu
- (void) rebaseOnUpstreamBranch:(NSMenuItem *)sender
{
    PBGitRevSpecifier *upstreamRev = [sender representedObject];
    PBGitRevSpecifier *currentRev = [historyController.repository activeBranch];
    
    if ([historyController.repository rebaseBranch:currentRev onUpstream:upstreamRev presentError:YES]) {
        [commitController rearrangeObjects];
        [historyController updateView];
    }
}

#pragma mark Create Branch

// called by the Create Branch toolbar button and the Repository menu
- (void) showCreateBranchSheet:(id)sender
{    
    [errorMessage setStringValue:@""];
    [NSApp beginSheet:newBranchSheet
       modalForWindow:[[historyController view] window]
        modalDelegate:NULL
       didEndSelector:NULL
          contextInfo:NULL];
}

- (void) saveNewBranch:(id) sender
{
	NSString *branchName = [@"refs/heads/" stringByAppendingString:[newBranchName stringValue]];
    
	if (![historyController.repository checkRefFormat:branchName]) {
		[errorMessage setStringValue:@"Invalid name"];
		return;
	}
	
	PBGitCommit *commit = nil;
    if (cachedCommit) {
        commit = cachedCommit;
	} else if ([[commitController selectedObjects] count]) {
        commit = [[commitController selectedObjects] objectAtIndex:0];
    } else {
		commit = [historyController.repository headCommit];
    }
    
	if (![historyController.repository createBranch:branchName onSHA:[commit realSha] presentError:NO]) {
		[errorMessage setStringValue:@"Branch exists"];
		return;
	}
    
	[self closeCreateBranchSheet:sender];
	[commitController rearrangeObjects];
}

- (void) closeCreateBranchSheet:(id) sender
{	
	[NSApp endSheet:newBranchSheet];
	[newBranchName setStringValue:@""];
	[newBranchSheet orderOut:self];
    cachedCommit = nil;
}

// called by the contextual menu for commits
- (void) createBranchHere:(PBRefMenuItem *)sender
{
    cachedCommit = [sender commit];
    [self showCreateBranchSheet:sender];
}

#pragma mark Change Branch

// called by the branch selector toolbar item to change the currently viewed history
- (void) changeBranch:(NSMenuItem *)sender
{
	PBGitRevSpecifier *rev = [sender representedObject];
	historyController.repository.currentBranch = rev;
}

// called by observeValueForKeyPath when the currently viewed branch changes
- (void) selectCurrentBranch
{
	PBGitRevSpecifier *rev = historyController.repository.currentBranch;
    [branchPopUp setTitle:[rev description]];
}


#pragma mark Remove a branch, remote or tag

// called by the contextual menu for branch, remote and tag
- (void) showDeleteRefSheet:(PBRefMenuItem *)sender
{
	NSString *ref_desc = [NSString stringWithFormat:@"%@ %@", [[sender ref] type], [[sender ref] shortName]];
	NSString *question = [NSString stringWithFormat:@"Are you sure you want to remove the %@?", ref_desc];
    NSBeginAlertSheet([NSString stringWithFormat:@"Delete %@?", ref_desc], @"Delete", @"Cancel", nil, [[historyController view] window], self, @selector(deleteRefSheetDidEnd:returnCode:contextInfo:), NULL, sender, question);
}

- (void) deleteRefSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
	if (returnCode == NSAlertDefaultReturn) {
		int ret = 1;
        PBRefMenuItem *refMenuItem = contextInfo;
		[historyController.repository outputForArguments:[NSArray arrayWithObjects:@"update-ref", @"-d", [[refMenuItem ref] ref], nil] retValue: &ret];
		if (ret) {
			NSLog(@"Removing ref failed!");
			return;
		}
		[historyController.repository removeBranch:[[PBGitRevSpecifier alloc] initWithRef:[refMenuItem ref]]];
		[[refMenuItem commit] removeRef:[refMenuItem ref]];
		[commitController rearrangeObjects];
        [self updateBranchMenus];
	}
}

#pragma mark Tags

- (void) showCreateTagSheet:(id)sender
{
    [newTagErrorMessage setStringValue:@""];
	[newTagName setStringValue:@""];
    
    if (cachedCommit) {
        [newTagCommit setStringValue:[cachedCommit subject]];
        [newTagSHA	setStringValue:[cachedCommit realSha]];
        [newTagSHALabel setHidden:NO];
    }
	else if ([[commitController selectedObjects] count] != 0) {
		PBGitCommit *commit = [[commitController selectedObjects] objectAtIndex:0];
        [newTagCommit setStringValue:[commit subject]];
        [newTagSHA	setStringValue:[commit realSha]];
        [newTagSHALabel setHidden:NO];
    } else {
        [newTagCommit setStringValue:historyController.repository.currentBranch.description];
        [newTagSHA	setStringValue:@""];
        [newTagSHALabel setHidden:YES];
    }
    
    [NSApp beginSheet:newTagSheet
       modalForWindow:[[historyController view] window]
        modalDelegate:NULL
       didEndSelector:NULL
          contextInfo:NULL];
}

- (void) saveNewTag:(id)sender
{
    NSString *tagName = [newTagName stringValue];
    
	NSString *refName = [@"refs/tags/" stringByAppendingString:tagName];
	if (![historyController.repository checkRefFormat:refName]) {
		[newTagErrorMessage setStringValue:@"Invalid name"];
		return;
	}

    PBGitCommit *commit = nil;
    if  (cachedCommit) {
        commit = cachedCommit;
    } else if ([[commitController selectedObjects] count] != 0) {
		commit = [[commitController selectedObjects] objectAtIndex:0];
    }
    
	NSString *message = [newTagMessage string];
	if (![historyController.repository addTag:tagName message:message forCommit:commit presentError:NO]) {
		[newTagErrorMessage setStringValue:@"Tag exists"];
		return;
	}
    
    [self closeCreateTagSheet:sender];
	[commitController rearrangeObjects];
}

- (void) closeCreateTagSheet:(id)sender
{	
	[NSApp endSheet:newTagSheet];
    [newTagErrorMessage setStringValue:@""];
	[newTagName setStringValue:@""];
	[newTagSheet orderOut:self];
    cachedCommit = nil;
}

- (void) addTagHere:(PBRefMenuItem *)sender
{
    cachedCommit = [sender commit];
    [self showCreateTagSheet:sender];
}

- (void) showTagInfoSheet:(PBRefMenuItem *)sender
{
    NSString *message = [NSString stringWithFormat:@"Info for tag: %@", [[sender ref] shortName]];
    
    int ret = 1;
    NSString *info = [historyController.repository outputInWorkdirForArguments:[NSArray arrayWithObjects:@"tag", @"-n50", @"-l", [[sender ref] shortName], nil] retValue: &ret];
    
    if (!ret) {
	    [[historyController.repository windowController] showMessageSheet:message infoText:info];
    }
    return;
}

#pragma mark Remotes

- (void) showAddRemoteSheet:(id)sender
{
    [addRemoteErrorMessage setStringValue:@""];
	[addRemoteName setStringValue:@""];
    [addRemoteName setTextColor:[NSColor blackColor]];
	[addRemoteURL setStringValue:@""];
    
    [NSApp beginSheet:addRemoteSheet
       modalForWindow:[[historyController view] window]
        modalDelegate:NULL
       didEndSelector:NULL
          contextInfo:NULL];
}

- (void) saveNewRemote:(id)sender
{
    NSString *remoteName = [addRemoteName stringValue];
    NSString *remoteURL = [addRemoteURL stringValue];
    
    if ([remoteName isEqualToString:@""]) {
        [addRemoteErrorMessage setStringValue:@"Remote name is required"];
        return;
    }
    
    NSRange range = [remoteName rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
    if (range.location != NSNotFound) {
        [addRemoteErrorMessage setStringValue:@"Whitespace is not allowed"];
        [addRemoteName setTextColor:[NSColor redColor]];
        return;
    }
    
    [addRemoteName setTextColor:[NSColor blackColor]];
    
    if ([remoteURL isEqualToString:@""]) {
        [addRemoteErrorMessage setStringValue:@"Remote URL is required"];
        return;
    }
    
    [addRemoteURL setTextColor:[NSColor blackColor]];
    
    [self closeAddRemoteSheet:sender];
    
    if ([historyController.repository addRemote:remoteName forURL:remoteURL presentError:YES])
        [commitController rearrangeObjects];
}

- (void) closeAddRemoteSheet:(id)sender
{	
	[NSApp endSheet:addRemoteSheet];
    [addRemoteErrorMessage setStringValue:@""];
	[addRemoteName setStringValue:@""];
    [addRemoteName setTextColor:[NSColor blackColor]];
	[addRemoteURL setStringValue:@""];
	[addRemoteSheet orderOut:self];
}

#pragma mark Copy info

- (void) copySHA:(PBRefMenuItem *)sender
{
    PBGitCommit *commit = [sender commit];
    
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    [pasteboard setString:[commit realSha] forType:NSStringPboardType];
}

- (void) copyPatch:(PBRefMenuItem *)sender
{
    PBGitCommit *commit = [sender commit];
    
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    [pasteboard setString:[commit patch] forType:NSStringPboardType];
}

# pragma mark Menus

- (NSArray *) menuItemsForRef:(PBGitRef *)ref commit:(PBGitCommit *)commit
{
	return [PBRefMenuItem defaultMenuItemsForRef:ref commit:commit target:self];
}

- (NSArray *) menuItemsForCommit:(PBGitCommit *)commit
{
	return [PBRefMenuItem defaultMenuItemsForCommit:commit target:self];
}    

- (void) updateBranchMenus
{
	NSMutableArray *localBranches = [NSMutableArray array];
	NSMutableArray *remoteBranches = [NSMutableArray array];
	NSMutableArray *tags = [NSMutableArray array];
	NSMutableArray *other = [NSMutableArray array];

	for (PBGitRevSpecifier *rev in historyController.repository.branches) {
		NSString *ref = [rev simpleRef];
        if (!ref)
			[other addObject:rev];
		else if ([ref hasPrefix:@"refs/heads"])
			[localBranches addObject:rev];
		else if ([ref hasPrefix:@"refs/tags"])
			[tags addObject:rev];
		else if ([ref hasPrefix:@"refs/remote"])
			[remoteBranches addObject:rev];
	}
    
    [[branchPopUp cell] setMenu:[PBRefMenuItem pullDownMenuForLocalBranches:localBranches remotes:remoteBranches tags:tags other:other target:self action:@selector(changeBranch:)]];
    [self selectCurrentBranch];
    
    [fetchItem setMenu:[PBRefMenuItem pullDownMenuForRemotes:remoteBranches target:self action:@selector(fetchFromRemote:)]];
    [pushItem  setMenu:[PBRefMenuItem pullDownMenuForRemotes:remoteBranches target:self action:@selector(pushToRemote:)]];
    [pullItem  setMenu:[PBRefMenuItem pullDownMenuForRemotes:remoteBranches target:self action:@selector(pullFromRemote:)]];
    
    [checkoutItem setMenu:[PBRefMenuItem pullDownMenuForLocalBranches:localBranches remotes:remoteBranches tags:tags target:self action:@selector(checkoutFromRef:)]];
     
    NSString *activeBranchName = [[historyController.repository activeBranch] refName];
    NSMenu *rebaseMenu = [PBRefMenuItem pullDownMenuForLocalBranches:localBranches remotes:remoteBranches tags:tags target:self action:@selector(rebaseOnUpstreamBranch:)];
    [rebaseMenu insertItem:[[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Rebase %@ starting at:", activeBranchName] action:nil keyEquivalent:@""] atIndex:0];
    [rebaseMenu insertItem:[NSMenuItem separatorItem] atIndex:1];
    [rebaseItem setMenu:rebaseMenu];
    
    NSString *headRefName = [[historyController.repository headRef] refName];
    NSMenu *mergeMenu = [PBRefMenuItem pullDownMenuForLocalBranches:localBranches remotes:remoteBranches tags:tags target:self action:@selector(mergeWithBranch:)];
    [mergeMenu insertItem:[[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Merge %@ with:", headRefName] action:nil keyEquivalent:@""] atIndex:0];
    [mergeMenu insertItem:[NSMenuItem separatorItem] atIndex:1];
    [mergeItem setMenu:mergeMenu];
}

# pragma mark Tableview delegate methods

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
	NSPoint location = [tv convertPointFromBase:[(PBCommitList *)tv mouseDownPoint]];
	int row = [tv rowAtPoint:location];
	int column = [tv columnAtPoint:location];
	if (column != 0)
		return NO;
	
	PBGitRevisionCell *cell = (PBGitRevisionCell *)[tv preparedCellAtColumn:column row:row];
	
	int index = [cell indexAtX:location.x];
	
	if (index == -1)
		return NO;
	
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:[NSArray arrayWithObjects:[NSNumber numberWithInt:row], [NSNumber numberWithInt:index], NULL]];
	[pboard declareTypes:[NSArray arrayWithObject:@"PBGitRef"] owner:self];
	[pboard setData:data forType:@"PBGitRef"];
	
	return YES;
}

- (NSDragOperation)tableView:(NSTableView*)tv
				validateDrop:(id <NSDraggingInfo>)info
				 proposedRow:(NSInteger)row
	   proposedDropOperation:(NSTableViewDropOperation)operation
{
	if (operation == NSTableViewDropAbove)
		return NSDragOperationNone;
	
	NSPasteboard *pboard = [info draggingPasteboard];
	if ([pboard dataForType:@"PBGitRef"])
		return NSDragOperationMove;
	
	return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)aTableView
	   acceptDrop:(id <NSDraggingInfo>)info
			  row:(NSInteger)row
	dropOperation:(NSTableViewDropOperation)operation
{
	if (operation != NSTableViewDropOn)
		return NO;
	
	NSPasteboard *pboard = [info draggingPasteboard];
	NSData *data = [pboard dataForType:@"PBGitRef"];
	if (!data)
		return NO;
	
	NSArray *numbers = [NSKeyedUnarchiver unarchiveObjectWithData:data];
	int oldRow = [[numbers objectAtIndex:0] intValue];
	int oldRefIndex = [[numbers objectAtIndex:1] intValue];
	PBGitCommit *oldCommit = [[commitController arrangedObjects] objectAtIndex: oldRow];
	PBGitRef *ref = [[oldCommit refs] objectAtIndex:oldRefIndex];
	
	PBGitCommit *dropCommit = [[commitController arrangedObjects] objectAtIndex:row];
	
	int a = [[NSAlert alertWithMessageText:@"Change branch"
							 defaultButton:@"Change"
						   alternateButton:@"Cancel"
							   otherButton:nil
				 informativeTextWithFormat:@"Do you want to change branch\n\n\t'%@'\n\n to point to commit\n\n\t'%@'", [ref shortName], [dropCommit subject]] runModal];
	if (a != NSAlertDefaultReturn)
		return NO;
	
	int retValue = 1;
	[historyController.repository outputForArguments:[NSArray arrayWithObjects:@"update-ref", @"-mUpdate from GitX", [ref ref], [dropCommit realSha], NULL] retValue:&retValue];
	if (retValue)
		return NO;
	
	[dropCommit addRef:ref];
	[oldCommit removeRef:ref];
	
	[commitController rearrangeObjects];
	[aTableView needsToDrawRect:[aTableView rectOfRow:oldRow]];
	return YES;
}

@end
