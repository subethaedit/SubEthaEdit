//
//  TCMMMUserSEEAdditions.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Tue Mar 02 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "TCMMMUserSEEAdditions.h"
#import "TCMMMUser.h"
#import "TCMBencodingUtilities.h"
#import "NSImageTCMAdditions.h"

@implementation TCMMMUser (TCMMMUserSEEAdditions) 

+ (TCMMMUser *)userWithBencodedUser:(NSData *)aData {
    NSDictionary *userDict=TCM_BdecodedObjectWithData(aData);
    return [self userWithDictionaryRepresentation:userDict];
}

+ (TCMMMUser *)userWithDictionaryRepresentation:(NSDictionary *)aRepresentation {
    TCMMMUser *user=[TCMMMUser new];
    [user setName:[aRepresentation objectForKey:@"name"]];
    [user setUserID:[NSString stringWithUUIDData:[aRepresentation objectForKey:@"uID"]]];
    [user setChangeCount:[[aRepresentation objectForKey:@"cnt"] longLongValue]];
    NSData *pngData=[aRepresentation objectForKey:@"PNG"];
    NSString *string=[aRepresentation objectForKey:@"AIM"];
    [[user properties] setObject:string?string:@"" forKey:@"AIM"];
    string=[aRepresentation objectForKey:@"mail"];
    [[user properties] setObject:string?string:@"" forKey:@"Email"];
    [[user properties] setObject:pngData forKey:@"ImageAsPNG"];
    [[user properties] setObject:[[[NSImage alloc] initWithData:[[user properties] objectForKey:@"ImageAsPNG"]] autorelease] forKey:@"Image"];
    [user prepareImages];
    [user setUserHue:[aRepresentation objectForKey:@"hue"]];
    //NSLog(@"Created User: %@",[user description]);
    return [user autorelease];
}

- (void)prepareImages {
    NSImage *image=[[self properties] objectForKey:@"Image"];
    NSMutableDictionary *properties=[self properties];
    [properties setObject:[image resizedImageWithSize:NSMakeSize(32.,32.)] forKey:@"Image32"];
    [properties setObject:[image resizedImageWithSize:NSMakeSize(16.,16.)] forKey:@"Image16"];
    [properties setObject:[[properties objectForKey:@"Image32"] dimmedImage] forKey:@"Image32Dimmed"];
}

- (NSDictionary *)dictionaryRepresentation {
    return [NSDictionary dictionaryWithObjectsAndKeys:
        [[self properties] objectForKey:@"AIM"],@"AIM",
        [[self properties] objectForKey:@"Email"],@"mail",
        [self name],@"name",
        [NSData dataWithUUIDString:[self userID]],@"uID",
        [[self properties] objectForKey:@"ImageAsPNG"],@"PNG",
        [NSNumber numberWithLong:[self changeCount]],@"cnt",
        [[self properties] objectForKey:@"Hue"],@"hue",
        nil];
}

- (NSData *)userBencoded {
    NSDictionary *user=[self dictionaryRepresentation];
    return TCM_BencodedObject(user);
}

- (void)setUserHue:(NSNumber *)aHue {
    if (aHue) {
        [[self properties] setObject:aHue forKey:@"Hue"];

        NSValueTransformer *hueTrans=[NSValueTransformer valueTransformerForName:@"HueToColor"];
        
        NSColor *color=[hueTrans transformedValue:aHue];
        NSRect rect=NSMakeRect(0,0,13,8);
        NSImage *image=[[[NSImage alloc] initWithSize:rect.size] autorelease];
        [image lockFocus];
        [color drawSwatchInRect:rect];
    //    [aColor set];
    //    NSRectFill(rect);
        [[NSColor blackColor] set];
        [NSBezierPath strokeRect:rect];
        [image unlockFocus];
        [[self properties] setObject:image forKey:@"ColorImage"];
        [[self properties] setObject:color forKey:@"ChangeColor"];
    }
}

- (NSColor *)changeColor {
    NSColor *changeColor=[[self properties] objectForKey:@"ChangeColor"];
    if (!changeColor) {
        changeColor = [NSColor redColor];
    }
    return changeColor;
}


    
@end
