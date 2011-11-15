/* Copyright (C) 2010 Mikkel Krautz <mikkel@krautz.dk>

   All rights reserved.

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions
   are met:

   - Redistributions of source code must retain the above copyright notice,
     this list of conditions and the following disclaimer.
   - Redistributions in binary form must reproduce the above copyright notice,
     this list of conditions and the following disclaimer in the documentation
     and/or other materials provided with the distribution.
   - Neither the name of the Mumble Developers nor the names of its
     contributors may be used to endorse or promote products derived from this
     software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
   ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
   A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE FOUNDATION OR
   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
   PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "MUGlobalShortcutController.h"

#define MOD_OFFSET   0x10000
#define MOUSE_OFFSET 0x20000

@interface MUGlobalShortcutController () {
    CFMachPortRef                           _port;
    id<MUGlobalShortcutControllerDelegate>  _delegate;
    CGEventFlags                            _modmask;
    BOOL                                    _suppressAll;
}
- (CFMachPortRef) eventTap;
- (BOOL) handleButton:(NSUInteger)keyCode down:(BOOL)flag;
- (void) handleModButton:(CGEventFlags)newmask;
@end

static CGEventRef GlobalShortcutCallback(CGEventTapProxy proxy, CGEventType type,
										 CGEventRef event, void *udata) {
	MUGlobalShortcutController *gs = (__bridge MUGlobalShortcutController *) udata;
	NSUInteger keycode;
    BOOL suppress = NO;
	BOOL forward = NO;
    BOOL down = NO;
    
	switch (type) {
		case kCGEventRightMouseDown:
		case kCGEventOtherMouseDown:
			down = YES;
		case kCGEventRightMouseUp:
		case kCGEventOtherMouseUp: {
			keycode = (NSUInteger) CGEventGetIntegerValueField(event, kCGMouseEventButtonNumber);
			suppress = [gs handleButton:MOUSE_OFFSET+keycode down:down];
			if (keycode == 0)
				suppress = NO;
			forward = !suppress;
			break;
		}
		case kCGEventFlagsChanged:
			[gs handleModButton:CGEventGetFlags(event)];
			forward = !suppress;
			break;
            
		case kCGEventTapDisabledByTimeout:
			NSLog(@"MUGlobalShortcutController: EventTap disabled by timeout. Re-enabling.");
			/*
			 * On Snow Leopard, we get this event type quite often. It disables our event
			 * tap completely. Possible Apple bug.
			 *
			 * For now, simply call CGEventTapEnable() to enable our event tap again.
			 *
			 * See: http://lists.apple.com/archives/quartz-dev/2009/Sep/msg00007.html
			 */
			CGEventTapEnable([gs eventTap], YES);
			break;
		case kCGEventTapDisabledByUserInput:
			NSLog(@"MUGlobalShortcutController: EventTap disabled by user input.");
			break;
            
		default:
			break;
	}
	return suppress ? NULL : event;
}

@implementation MUGlobalShortcutController

+ (MUGlobalShortcutController *) sharedController {
    static dispatch_once_t pred;
    static MUGlobalShortcutController *gs;
    dispatch_once(&pred, ^{
        gs = [[MUGlobalShortcutController alloc] init];
    });
    return gs;
}

- (id) init {
	if ((self = [super init])) {
        const CGEventMask evmask = CGEventMaskBit(kCGEventLeftMouseDown) |
                                   CGEventMaskBit(kCGEventLeftMouseUp) |
                                   CGEventMaskBit(kCGEventRightMouseDown) |
                                   CGEventMaskBit(kCGEventRightMouseUp) |
                                   CGEventMaskBit(kCGEventOtherMouseDown) |
                                   CGEventMaskBit(kCGEventOtherMouseUp) |
                                   CGEventMaskBit(kCGEventKeyDown) |
                                   CGEventMaskBit(kCGEventKeyUp) |
                                   CGEventMaskBit(kCGEventFlagsChanged) |
                                   CGEventMaskBit(kCGEventMouseMoved) |
                                   CGEventMaskBit(kCGEventLeftMouseDragged) |
                                   CGEventMaskBit(kCGEventRightMouseDragged) |
                                   CGEventMaskBit(kCGEventOtherMouseDragged) |
                                   CGEventMaskBit(kCGEventScrollWheel);

      /*
       _port = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap, 0, evmask, GlobalShortcutCallback, (__bridge void *)self);
        if (_port == NULL) {
            NSLog(@"Unable to create event tap.");
            return nil;
        }

        CFRunLoopRef loop = CFRunLoopGetCurrent();
        CFRunLoopSourceRef src = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, _port, 0);
        CFRunLoopAddSource(loop, src, kCFRunLoopCommonModes);
    */
    }
	return self;
}

- (void) setDelegate:(id<MUGlobalShortcutControllerDelegate>)delegate {
    _delegate = delegate;
}

- (id<MUGlobalShortcutControllerDelegate>) delegate {
    return _delegate;
}

- (void) setSuppressAll:(BOOL)shouldSuppress {
    _suppressAll = shouldSuppress;
}

- (CFMachPortRef) eventTap {
    return _port;
}

- (NSString *) keyCodeDescription:(NSUInteger)keyCode {
    return [NSString stringWithFormat:@"0x%lx", keyCode];
}

- (BOOL) handleButton:(NSUInteger)keyCode down:(BOOL)flag {
    if (_delegate)
        [_delegate globalShortcutController:self keyCode:keyCode down:flag];
    return _suppressAll;
}

- (void) handleModButton:(CGEventFlags)newmask {
#define MOD_CHANGED(flag, off) \
    if ((_modmask & flag) == 0) { \
        if ((newmask & flag) != 0) { \
            [self handleButton:MOD_OFFSET+off down:YES]; \
        } \
    } else { \
        if ((newmask & flag) == 0) { \
            [self handleButton:MOD_OFFSET+off down:NO]; \
        } \
    } \

	MOD_CHANGED(kCGEventFlagMaskAlphaShift, 0);
	MOD_CHANGED(kCGEventFlagMaskShift, 1);
	MOD_CHANGED(kCGEventFlagMaskControl, 2);
	MOD_CHANGED(kCGEventFlagMaskAlternate, 3);
	MOD_CHANGED(kCGEventFlagMaskCommand, 4);
	MOD_CHANGED(kCGEventFlagMaskHelp, 5);
	MOD_CHANGED(kCGEventFlagMaskSecondaryFn, 6);
	MOD_CHANGED(kCGEventFlagMaskNumericPad, 7);

    _modmask = newmask;
}

@end
