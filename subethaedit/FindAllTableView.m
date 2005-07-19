//
//  FindAllTableView.m
//  SubEthaEdit
//
//  Created by Martin Pittenauer on 7/19/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "FindAllTableView.h"


@implementation FindAllTableView

// Implement copying lines
- (void)copy:(id)sender
{
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    NSString *string = @"";

    switch ([self numberOfSelectedRows])
    {
        case 0:
			NSBeep();
            return;

        default:
        {
            id selection = [self selectedRowIndexes];
            int index = [selection firstIndex]; 

            do
            {
				string = [string stringByAppendingFormat: @"%@", [[[[[self delegate] arrangedObjects] objectAtIndex:index] objectForKey:@"foundString"] string]];
            } while ((index = [selection indexGreaterThanIndex: index]) != NSNotFound);
        }
    }

    [pb 
        declareTypes: [NSArray arrayWithObject:NSStringPboardType] 
        owner:nil];

    [pb setString:string
         forType: NSStringPboardType];
}

@end
