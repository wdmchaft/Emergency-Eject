//
//  EjectListener.h
//  Emergency Eject
//
//  Created by Wil Hall on 4/1/12.
//  Copyright 2012 Wil Hall. All rights reserved.
//

#include <Cocoa/Cocoa.h>
#import <IOKit/hidsystem/ev_keymap.h>
#import <Carbon/Carbon.h>
#import <Foundation/Foundation.h>

@interface EjectListener : NSObject {
	CFMachPortRef eventPort;
	CFRunLoopSourceRef eventSource;
	CFRunLoopRef listenThread;
	DASessionRef daSession;
}

@property(retain) NSMutableArray* ejectedDisks;

-(void)listenForKeys;
-(void)doDiskEject:(DADiskRef)disk;
-(void)handleEjectKeyPressed:(NSEvent*)ejectEvent;

@end
