//
//  SEEWebPreview.m
//  SubEthaEdit
//
//  Created by Matthias Bartelmeß on 16.11.19.
//  Copyright © 2019 SubEthaEdit Contributors. All rights reserved.
//

#import <JavaScriptCore/JavaScriptCore.h>
#import "SEEWebPreview.h"
#import "NSStringSEEAdditions.h"

@implementation SEEWebPreview {
    NSString *script;
    NSURL *scriptURL;
    JSVirtualMachine *vm;
    JSContext *ctx;
    NSLock *vmLock;
}

- (instancetype)initWithURL:(NSURL *)url {
    if (!url) {
        return nil;
    }

    self = [super init];
    if (self) {
        NSError *error = nil;

        scriptURL = [url copy];

        script = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&error];

        vm = [[JSVirtualMachine alloc] init];
        ctx = [[JSContext alloc] initWithVirtualMachine:vm];
        ctx.name = @"Mode Web Preview";
        
        [ctx evaluateScript:script withSourceURL:scriptURL];
        
        vmLock = [[NSLock alloc] init];

        if (ctx.exception) {
            DEBUGLOG(@"ModesDomain", AllLogLevel, @"Failed to load %@: %@", scriptURL, ctx.exception.toString);
            return nil;
        }

        if (error) {
            return nil;
        }
    }
    return self;
}

- (NSString *)webPreviewForText:(NSString *)text {
    [vmLock lock];
    JSValue *result = [ctx.globalObject invokeMethod:@"webPreview" withArguments:@[ text ]];
    JSValue *exception = ctx.exception;
    [vmLock unlock];
    
    NSString *preview = nil;

    if (exception) {
        DEBUGLOG(@"ModesDomain", AllLogLevel, @"Failed to generate preview %@", exception.toString);
        return [NSString stringWithFormat:@"<pre>%@</pre>", [exception.toString stringByReplacingEntitiesForUTF8:YES]];
    }
    
    if (result.isString) {
        preview = [result toString];
    }

    return preview;
}

@end
