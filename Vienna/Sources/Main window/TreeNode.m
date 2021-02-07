//
//  TreeNode.m
//  Vienna
//
//  Created by Steve on Sat Jan 31 2004.
//  Copyright (c) 2004-2005 Steve Palmer. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "TreeNode.h"
#import "Preferences.h"
#import "Constants.h"
#import "Folder.h"

@implementation TreeNode

/* init
 * Initialises a treenode.
 */
-(instancetype)init:(TreeNode *)parent atIndex:(NSInteger)insertIndex folder:(Folder *)theFolder canHaveChildren:(BOOL)childflag
{
	if ((self = [super init]) != nil)
 	{
		NSInteger folderId = (theFolder ? theFolder.itemId : VNAFolderTypeRoot);
		_folder = theFolder;
		_parentNode = parent;
		_canHaveChildren = childflag;
		_nodeId = folderId;
		if (parent != nil)
		{
			[parent addChild:self atIndex:insertIndex];
		}
		children = [NSMutableArray array];
	}
	return self;
}

/* addChild
 * Add the specified node to the our list of children. The position at which the new child
 * is added depends on the type of the folder associated with the node and thus this code
 * is tightly coupled with the folder view and database. Specifically:
 *
 * 1. The folder type value dictates the order of each type relative to each other.
 * 2. Within a specified type, all folders are organised by the active sort method.
 *
 * This function does not fail. It is assumed that the child can always be inserted into
 * place one way or the other.
 */
-(void)addChild:(TreeNode *)child atIndex:(NSInteger)insertIndex
{
	NSAssert(_canHaveChildren, @"Trying to add children to a node that cannot have children (canHaveChildren==NO)");
	NSUInteger count = children.count;
	NSInteger sortMethod = [Preferences standardPreferences].foldersTreeSortMethod;

	if (sortMethod != VNAFolderSortManual)
	{
		insertIndex = 0;

		while (insertIndex < count)
		{
			TreeNode * theChild = children[insertIndex];
			if (sortMethod == VNAFolderSortByName)
			{
				if ([child folderNameCompare:theChild] == NSOrderedAscending)
					break;
			}
			else
			{
				NSAssert1(TRUE, @"Unsupported folder sort method in addChild: %ld", (long)sortMethod);
			}
			++insertIndex;
		}
	}
	else if ((insertIndex < 0) || (insertIndex > count))
		insertIndex = count;
	
	child.parentNode = self;
	[children insertObject:child atIndex:insertIndex];
}

/* removeChild
 * Remove the specified child from the node list and any children
 * that it may have.
 */
-(void)removeChild:(TreeNode *)child andChildren:(BOOL)removeChildrenFlag
{
	if (removeChildrenFlag)
		[child removeChildren];
	[children removeObject:child];
}

/* sortChildren
 * Sort the children of this node.
 */
-(void)sortChildren:(NSInteger)sortMethod
{
	switch (sortMethod)
	{
	case VNAFolderSortManual:
		// Do nothing
		break;

	case VNAFolderSortByName:
		[children sortUsingSelector:@selector(folderNameCompare:)];
		break;
		
	default:
		NSAssert1(TRUE, @"Unsupported folder sort method in sortChildren: %ld", (long)sortMethod);
		break;
	}
}

/* folderNameCompare
 * Returns the result of comparing two folders by folder name.
 */
-(NSComparisonResult)folderNameCompare:(TreeNode *)otherObject
{
	Folder * thisFolder = self.folder;
	Folder * otherFolder = otherObject.folder;

    if (thisFolder.type < otherFolder.type) {
		return NSOrderedAscending;
    }
    if (thisFolder.type > otherFolder.type) {
		return NSOrderedDescending;
    }
	return [thisFolder.name caseInsensitiveCompare:otherFolder.name];
}

/* removeChildren
 * Removes all of our child nodes.
 */
-(void)removeChildren
{
	[children removeAllObjects];
}

/* nodeFromID
 * Searches down from the current node to find the node that
 * has the given ID.
 */
-(TreeNode *)nodeFromID:(NSInteger)n
{
	if (self.nodeId == n)
		return self;
	
	TreeNode * theNode;
	
	for (TreeNode * node in children)
	{
		if ((theNode = [node nodeFromID:n]) != nil)
			return theNode;
	}
	return nil;
}

/* childByIndex
 * Returns the TreeNode for the child at the specified index offset. (Note that we don't
 * assert index here. The objectAtIndex function will take care of that for us.)
 */
-(TreeNode *)childByIndex:(NSInteger)index
{
	return children[index];
}

/* indexOfChild
 * Returns the index of the specified TreeNode or NSNotFound if it is not found.
 */
-(NSInteger)indexOfChild:(TreeNode *)node
{
	return [children indexOfObject:node];
}

/* nextSibling
 * Returns the next child.
 */
-(TreeNode *)nextSibling
{
	NSInteger childIndex = [_parentNode indexOfChild:self];
	if (childIndex == NSNotFound || ++childIndex >= _parentNode.countOfChildren)
		return nil;
	return [_parentNode childByIndex:childIndex];
}

/* firstChild
 * Returns the first child node or nil if we have no children
 */
-(TreeNode *)firstChild
{
	if (children.count == 0)
		return nil;
	return children[0];
}

/* nodeName
 * Returns the node's name which is basically the name of the folder
 * associated with the node. If no folder is associated with this node
 * then the name is an empty string.
 */
-(NSString *)nodeName
{
	if (_folder != nil) {
		if (_folder.type == VNAFolderTypeOpenReader) {
			return [NSString stringWithFormat:@"☁️ %@",_folder.name];
		} else {
			return _folder.name;
		}
	} 
	return @"";
}

/* countOfChildren
 * Returns the number of direct child nodes of this node
 */
-(NSUInteger)countOfChildren
{
	return children.count;
}

/* description
 * Returns a TreeNode description
 */
-(NSString *)description
{
	return [NSString stringWithFormat:@"%@ (Parent=%p, # of children=%ld)",
            _folder.name, _parentNode, (unsigned long)children.count];
}

@end
