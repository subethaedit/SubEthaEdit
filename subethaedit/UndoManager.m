//
//  UndoManager.m
//  SubEthaEdit
//
//  Created by Martin Ott on Wed May 12 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "UndoManager.h"

#import "TCMMillionMonkeys/TCMMillionMonkeys.h"
#import "PlainTextDocument.h"
#import "TextOperation.h"
#import "PlainTextWindowController.h"
#import "PlainTextEditor.h"

NSString * const UndoManagerCheckpointNotification = @"UndoManagerCheckpointNotification";
NSString * const UndoManagerDidOpenUndoGroupNotification = @"UndoManagerDidOpenUndoGroupNotification";
NSString * const UndoManagerDidRedoChangeNotification = @"UndoManagerDidRedoChangeNotification";
NSString * const UndoManagerDidUndoChangeNotification = @"UndoManagerDidUndoChangeNotification";
NSString * const UndoManagerWillCloseUndoGroupNotification = @"UndoManagerWillCloseUndoGroupNotification";
NSString * const UndoManagerWillRedoChangeNotification = @"UndoManagerWillRedoChangeNotification";
NSString * const UndoManagerWillUndoChangeNotification = @"UndoManagerWillUndoChangeNotification";


@interface UndoGroup : NSObject 
{
    UndoGroup *_parent;
    NSMutableArray *_actions;
    NSString *_actionName;
}

- (NSMutableArray *)actions;
- (NSString *)actionName;
- (void)addOperation:(TCMMMOperation *)operation;
- (TCMMMOperation *)lastOperation;
- (id)initWithParent:(UndoGroup *)parent;
- (UndoGroup *)parent;
- (void)setActionName:(NSString *)newName;

@end

#pragma mark -

@implementation UndoGroup

- (NSMutableArray *)actions
{
    return _actions;
}

- (NSString *)actionName
{
    return _actionName;
}

- (void)addOperation:(TCMMMOperation *)operation
{
    if (_actions == nil) {
        _actions = [NSMutableArray new];
    }
    [_actions addObject:operation];
}

- (TCMMMOperation *)lastOperation {
    return [_actions lastObject];
}

- (void)dealloc
{
    [_actions release];
    [_parent release];
    [_actionName release];
    [super dealloc];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"parent: %@\nactions: %@\nactionName: %@", [_parent description], [_actions description], _actionName];
}

- (id)initWithParent:(UndoGroup *)parent
{
    self = [super init];
    
    _actions = nil;
    _actionName = @"";
    _parent = [parent retain];
    
    return self;
}

- (UndoGroup *)parent
{
    return _parent;
}

- (void)setActionName:(NSString *)newName
{
    [_actionName autorelease];
    _actionName = [newName copy];
}

@end

#pragma mark -

@implementation UndoManager

- (void)dealloc {
    _document = nil;
    [_undoGroup release];
    [_undoStack release];
    [_redoGroup release];
    [_redoStack release];
    [super dealloc];
}

            /* Begin/End Grouping */

- (void)beginUndoGrouping {
    if (![self isUndoing]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:UndoManagerCheckpointNotification object:self];
    }
    
    if ([self isUndoing]) {
        if (_redoGroup == nil) {
            UndoGroup *newGroup = [[UndoGroup alloc] initWithParent:_redoGroup]; 
            _redoGroup = newGroup;
        }
    } else if ([self isRedoing]) {
        if (_undoGroup == nil) {
            UndoGroup *newGroup = [[UndoGroup alloc] initWithParent:_undoGroup];
            _undoGroup = newGroup;
        }
    } else {
        if (_flags.automaticGroupLevel == [self groupingLevel]) {
            [self endUndoGrouping];
            _flags.automaticGroupLevel = -1;
        }
        UndoGroup *newGroup = [[UndoGroup alloc] initWithParent:_undoGroup];
        [_undoGroup release];
        _undoGroup = newGroup;
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:UndoManagerDidOpenUndoGroupNotification object:self];
}

- (void)endUndoGrouping {
    [[NSNotificationCenter defaultCenter] postNotificationName:UndoManagerCheckpointNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:UndoManagerWillCloseUndoGroupNotification object:self];

    if (!_flags.internal) {
        
        if ([self isUndoing]) {
        
            if (_redoGroup == nil) {
                [NSException raise:NSInternalInconsistencyException
                            format:@"endUndoGrouping without beginUndoGrouping"];
            }
        
            if ([_redoGroup parent] == nil) {
                [_redoStack addObject:_redoGroup];
                [_redoGroup release];
                _redoGroup = nil;
            } else {
                UndoGroup *parent = [[_redoGroup parent] retain];
                NSArray *actions = [_redoGroup actions];
                unsigned i;
                for (i = 0; i < [actions count]; i++) {
                    [parent addOperation:[actions objectAtIndex:i]];
                }
                [_redoGroup release];
                _redoGroup = parent;
            }
            
        } else {
        
            if (_undoGroup == nil) {
                [NSException raise:NSInternalInconsistencyException
                            format:@"endUndoGrouping without beginUndoGrouping"];
            }
        
            if ([_undoGroup parent] == nil) {
                [_undoStack addObject:_undoGroup];
                [_undoGroup release];
                _undoGroup = nil;
            } else {
                UndoGroup *parent = [[_undoGroup parent] retain];
                NSArray *actions = [_undoGroup actions];
                unsigned i;
                for (i = 0; i < [actions count]; i++) {
                    [parent addOperation:[actions objectAtIndex:i]];
                }
                [_undoGroup release];
                _undoGroup = parent;
            }    
        }
        
    }
}
    // These nest.

- (int)groupingLevel {
    UndoGroup *group;
    int level = 0;
    
    if ([self isUndoing]) {
        group = _redoGroup;
        while (group != nil) {
            level++;
            group = [group parent];
        }
    } else {
        group = _undoGroup;
        while (group != nil) {
            level++;
            group = [group parent];
        }    
    }
    
    return level;
}
    // Zero means no open group.

        /* Enable/Disable registration */

- (void)disableUndoRegistration {
    [NSException raise:NSInternalInconsistencyException format:@"Unimplemented method: %@", NSStringFromSelector(_cmd)];
}

- (void)enableUndoRegistration {
    [NSException raise:NSInternalInconsistencyException format:@"Unimplemented method: %@", NSStringFromSelector(_cmd)];
}

- (BOOL)isUndoRegistrationEnabled {
    [NSException raise:NSInternalInconsistencyException format:@"Unimplemented method: %@", NSStringFromSelector(_cmd)];
    return NO;
}

        /* Groups By Event */

- (BOOL)groupsByEvent {
    [NSException raise:NSInternalInconsistencyException format:@"Unimplemented method: %@", NSStringFromSelector(_cmd)];
    return NO;
}

- (void)setGroupsByEvent:(BOOL)groupsByEvent {
    [NSException raise:NSInternalInconsistencyException format:@"Unimplemented method: %@", NSStringFromSelector(_cmd)];
}
    // If groupsByEvent is enabled, the undoManager automatically groups
    // all undos registered during a single NSRunLoop event together in
    // a single top-level group. This featured is enabled by default.

        /* Undo levels */

- (void)setLevelsOfUndo:(unsigned)levels {
    [NSException raise:NSInternalInconsistencyException format:@"Unimplemented method: %@", NSStringFromSelector(_cmd)];
}

- (unsigned)levelsOfUndo {
    [NSException raise:NSInternalInconsistencyException format:@"Unimplemented method: %@", NSStringFromSelector(_cmd)];
    return 0;
}
    // Sets the number of complete groups (not operations) that should
    // be kept my the manager.  When limit is reached, oldest undos are
    // thrown away.  0 means no limit !

        /* Run Loop Modes */

- (void)setRunLoopModes:(NSArray *)runLoopModes {
    [NSException raise:NSInternalInconsistencyException format:@"Unimplemented method: %@", NSStringFromSelector(_cmd)];
}

- (NSArray *)runLoopModes {
    [NSException raise:NSInternalInconsistencyException format:@"Unimplemented method: %@", NSStringFromSelector(_cmd)];
    return [NSArray array];
}

        /* Undo/Redo */

- (void)undo {
    [[NSNotificationCenter defaultCenter] postNotificationName:UndoManagerCheckpointNotification object:self];

    if (_undoGroup != nil) {
        [self endUndoGrouping];
        _flags.automaticGroupLevel=-1;
    }
    
    if ([self groupingLevel] == 1) {
        [self endUndoGrouping];
    }
    
    if (_undoGroup != nil) {
        [NSException raise:NSInternalInconsistencyException
                    format:@"undo with nested groups"];
    }
    
    [self undoNestedGroup];
}

    // Undo until a matching begin. It terminates a top level undo if
    // necesary. Useful for undoing when groupByEvents is on (default is
    // on)
- (void)redo {
    [[NSNotificationCenter defaultCenter] postNotificationName:UndoManagerCheckpointNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:UndoManagerWillRedoChangeNotification object:self];
    
    _flags.redoing++;
    [self beginUndoGrouping];
    _flags.internal++;
    
    if (_redoGroup != nil) {
        UndoGroup *parent = [_redoGroup parent];
        [self performUndoGroup:_redoGroup];
        [_redoGroup release];
        _redoGroup = parent;
    } else {
        UndoGroup *group = [_redoStack lastObject];
        [self performUndoGroup:group];
        [_redoStack removeLastObject];
    }
    
    _flags.internal--;
    [self endUndoGrouping];
    _flags.redoing--;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UndoManagerDidRedoChangeNotification object:self];
}
    // Will redo last top-level undo.

- (void)undoNestedGroup {
    [[NSNotificationCenter defaultCenter] postNotificationName:UndoManagerCheckpointNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:UndoManagerWillUndoChangeNotification object:self];

    _flags.undoing++;
    [self beginUndoGrouping];
    _flags.internal++;

    if (_undoGroup != nil) {
        UndoGroup *parent = [_undoGroup parent];
        [self performUndoGroup:_undoGroup];
        [_undoGroup release];
        _undoGroup = parent;
    } else {
        UndoGroup *group = [_undoStack lastObject];
        [self performUndoGroup:group];
        [_undoStack removeLastObject];
    }
    
    _flags.internal--;
    [self endUndoGrouping];
    _flags.undoing--;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:UndoManagerDidUndoChangeNotification object:self];
}
    // Undoes a nested grouping without first trying to close a top level
    // undo group.

- (BOOL)canUndo {
    if ([_undoStack count] > 0) {
        return YES;
    }
    
    if (_undoGroup != nil && [[_undoGroup actions] count] > 0) {
        return YES;
    }
    
    return NO;
}

- (BOOL)canRedo {
    [[NSNotificationCenter defaultCenter] postNotificationName:UndoManagerCheckpointNotification object:self];
    
    if ([_redoStack count] > 0) {
        return YES;
    }
    
    if (_redoGroup != nil && [[_redoGroup actions] count] > 0) {
        return YES;
    }
    
    return NO;
}
    // returns whether or not the UndoManager has anything to undo or redo

- (BOOL)isUndoing {
    return _flags.undoing;
}

- (BOOL)isRedoing {
    return _flags.redoing;
}
    // returns whether or not the undo manager is currently in the process
    // of invoking undo or redo operations.

        /* remove */

- (void)removeAllActions {
    [_undoStack removeAllObjects];
    [_undoGroup release];
    _undoGroup = nil;
    [_redoStack removeAllObjects];
    [_redoGroup release];
    _redoGroup = nil;
}

- (void)removeAllActionsWithTarget:(id)target {
    [NSException raise:NSInternalInconsistencyException format:@"Unimplemented method: %@", NSStringFromSelector(_cmd)];
}
    // Should be called from the dealloc method of any object that may have
    // registered as a target for undo operations

        /* Object based Undo */

- (void)registerUndoWithTarget:(id)target selector:(SEL)selector object:(id)anObject {
    [NSException raise:NSInternalInconsistencyException format:@"Unimplemented method: %@", NSStringFromSelector(_cmd)];
}

        /* Invocation based undo */

- (id)prepareWithInvocationTarget:(id)target {
    [NSException raise:NSInternalInconsistencyException format:@"Unimplemented method: %@", NSStringFromSelector(_cmd)];
    return nil;
}
   // called as:
   // [[undoManager prepareWithInvocationTarget:self] setFont:oldFont color:oldColor]
   // When undo is called, the specified target will be called with
   // [target setFont:oldFont color:oldColor]

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    [NSException raise:NSInternalInconsistencyException format:@"Unimplemented method: %@", NSStringFromSelector(_cmd)];
}

    	/* Undo/Redo action name */

- (NSString *)undoActionName {
    if (_undoGroup != nil) {
        return [_undoGroup actionName];
    }
    
    if ([_undoStack count] > 0) {
        return [[_undoStack lastObject] actionName];
    }
    
    return nil;
}

- (NSString *)redoActionName {
    if (_redoGroup != nil) {
        return [_redoGroup actionName];
    }
    
    if ([_redoStack count] > 0) {
        return [[_redoStack lastObject] actionName];
    }
    
    return nil;
}
    // Call undoActionName or redoActionName to get the name of the next action to be undone or redone.
    // Returns @"" if there is nothing to undo/redo or no action names were registered.

- (void)setActionName:(NSString *)actionName {
    if (actionName != nil) {
        if ([self isUndoing]) {
            if (_redoGroup != nil) {
                [_redoGroup setActionName:actionName];
            } else if ([_redoStack count] > 0) {
                [[_redoStack lastObject] setActionName:actionName];
            } else {
                [NSException raise:NSInternalInconsistencyException
                            format:@"setActionName on nil action"];
            }
        } else {
            if (_undoGroup != nil) {
                [_undoGroup setActionName:actionName];
            } else if ([_undoStack count] > 0) {
                [[_undoStack lastObject] setActionName:actionName];
            } else {
                [NSException raise:NSInternalInconsistencyException
                            format:@"setActionName on nil action"];
            }
        }
    }
}
    // Call setActionName: to set the name of an action.
    // The actionName parameter can not be nil

    	/* Undo/Redo menu item title */

- (NSString *)undoMenuItemTitle {
    [NSException raise:NSInternalInconsistencyException format:@"Unimplemented method: %@", NSStringFromSelector(_cmd)];
    return @"";
}

- (NSString *)redoMenuItemTitle {
    [NSException raise:NSInternalInconsistencyException format:@"Unimplemented method: %@", NSStringFromSelector(_cmd)];
    return @"";
}
    // Call undoMenuItemTitle or redoMenuItemTitle to get the string for the undo or redo menu item.
    // In English they will return "Undo <action name>"/"Redo <action name>" or "Undo"/"Redo" if there is
    // nothing to undo/redo or no action names were set.

    	/* localization hooks */

- (NSString *)undoMenuTitleForUndoActionName:(NSString *)actionName {
    [NSException raise:NSInternalInconsistencyException format:@"Unimplemented method: %@", NSStringFromSelector(_cmd)];
    return @"";
}

- (NSString *)redoMenuTitleForUndoActionName:(NSString *)actionName {
    [NSException raise:NSInternalInconsistencyException format:@"Unimplemented method: %@", NSStringFromSelector(_cmd)];
    return @"";
}
    // The localization of the pattern is usually done by localizing the string patterns in
    // undo.strings. But undo/redoMenuTitleForUndoActionName can also be overridden if
    // localizing the pattern happens to not be sufficient.

#pragma mark -

- (id)initWithDocument:(PlainTextDocument *)document {
    self = [super init];
    if (self) {
        _document = document;
        _flags.undoing = 0;
        _flags.redoing = 0;
        _flags.internal = 0;
        _flags.automaticGroupLevel = -1;
        _undoStack = [NSMutableArray new];
        _redoStack = [NSMutableArray new];
        _undoGroup = nil;
        _redoGroup = nil;
    }
    return self;
}

- (void)performUndoGroup:(UndoGroup *)group {
    NSArray *actions = [group actions];
    
    if (actions != nil) {
        unsigned i = [actions count];
        [[_document textStorage] beginEditing];
        TextOperation *operation;
        while (i-- > 0) {
            operation = [actions objectAtIndex:i];
            [_document handleOperation:operation];
        }
        [[_document textStorage] endEditing];
        if (operation) {
            NSTextView *textView=[[[_document topmostWindowController] activePlainTextEditor] textView];
            [textView setSelectedRange:NSMakeRange([operation affectedCharRange].location+[[operation replacementString] length],0)];
            [textView scrollRangeToVisible:[textView selectedRange]];
        }
    }
}

- (void)registerUndoChangeTextInRange:(NSRange)aAffectedCharRange
                    replacementString:(NSString *)aReplacementString shouldGroupWithPriorOperation:(BOOL)shouldGroup {
    TextOperation *operation = [TextOperation textOperationWithAffectedCharRange:aAffectedCharRange
                                                               replacementString:aReplacementString
                                                                          userID:[TCMMMUserManager myUserID]];

    if ([self isUndoing]) {
        if (_redoGroup == nil) {
                [NSException raise:NSInternalInconsistencyException
                            format:@"endUndoGrouping without beginUndoGrouping"];
        }
        [_redoGroup addOperation:operation];
    } else {
        if (_undoGroup == nil) {
            if (_flags.automaticGroupLevel != -1) {
            [NSException raise:NSInternalInconsistencyException
                        format:@"endUndoGrouping without beginUndoGrouping"];
            } else {
                [self beginUndoGrouping];
                _flags.automaticGroupLevel = [self groupingLevel];
            }
        } else if (_flags.automaticGroupLevel == [self groupingLevel]) {
            TCMMMOperation *lastOperation = [_undoGroup lastOperation];
            if (lastOperation && !shouldGroup) {
                [self endUndoGrouping];
                [self beginUndoGrouping];
            }
        }
        [_undoGroup addOperation:operation];
        if (![self isRedoing]) {
            [_redoGroup release];
            _redoGroup = nil;
            [_redoStack removeAllObjects];
        }
    }
}

- (void)transformStacksWithOperation:(TCMMMOperation *)anOperation {

    if ([anOperation isKindOfClass:[TextOperation class]]) {

        TCMMMTransformator *transformator = [TCMMMTransformator sharedInstance];
        
        int i, k;
        UndoGroup *group;
        NSMutableArray *actions;
        BOOL isServer = [[_document session] isServer]; 
        
        TextOperation *operation = [anOperation copy];
        
        group = _undoGroup;
        while (group != nil) {
            actions = [group actions];
            for (i = [actions count] - 1; i >= 0; i--) {
                if (isServer) {
                    //[[actions objectAtIndex:i] transform:operation];
                    [transformator transformOperation:[actions objectAtIndex:i] serverOperation:operation];
                } else {
                    //[operation transform:[actions objectAtIndex:i]];
                    [transformator transformOperation:operation serverOperation:[actions objectAtIndex:i]];
                }
                
                if ([[actions objectAtIndex:i] isIrrelevant]) {
                    [actions removeObjectAtIndex:i];
                }
            }
            group = [group parent];
        }
            
        for (i = [_undoStack count] - 1; i >= 0; i--) {
            group = [_undoStack objectAtIndex:i];
            actions = [group actions];
            for (k = [actions count] -1; k >= 0; k--) {
                if (isServer) {
                    //[[actions objectAtIndex:k] transform:operation];
                    [transformator transformOperation:[actions objectAtIndex:k] serverOperation:operation];
                } else {
                    //[operation transform:[actions objectAtIndex:k]];
                    [transformator transformOperation:operation serverOperation:[actions objectAtIndex:k]];
                }
            
                if ([[actions objectAtIndex:k] isIrrelevant]) {
                    [actions removeObjectAtIndex:k];
                }
            }
            
            if ([actions count] == 0) {
                [_undoStack removeObjectAtIndex:i];
            }
        }

        [operation release];


        operation = [anOperation copy];
        
        group = _redoGroup;
        while (group != nil) {
            actions = [group actions];
            for (i = [actions count] - 1; i >= 0; i--) {
                if (isServer) {
                    //[[actions objectAtIndex:i] transform:operation];
                    [transformator transformOperation:[actions objectAtIndex:i] serverOperation:operation];
                } else {
                    //[operation transform:[actions objectAtIndex:i]];
                    [transformator transformOperation:operation serverOperation:[actions objectAtIndex:i]];
                }
                
                if ([[actions objectAtIndex:i] isIrrelevant]) {
                    [actions removeObjectAtIndex:i];
                }
            }
            group = [group parent];
        }
        
        for (i = [_redoStack count] - 1; i >= 0; i--) {

            group = [_redoStack objectAtIndex:i];
            actions = [group actions];        
            for (k = [actions count] -1; k >= 0; k--) {
                if (isServer) {
                    //[[actions objectAtIndex:k] transform:operation];
                    [transformator transformOperation:[actions objectAtIndex:k] serverOperation:operation];
                } else {
                    //[operation transform:[actions objectAtIndex:k]];
                    [transformator transformOperation:operation serverOperation:[actions objectAtIndex:k]];                }
                
                if ([[actions objectAtIndex:k] isIrrelevant]) {
                    [actions removeObjectAtIndex:k];
                }
            }
            
            if ([actions count] == 0) {
                [_redoStack removeObjectAtIndex:i];
            }
        }

        [operation release];
    }
}

@end
