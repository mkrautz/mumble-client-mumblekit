/* Copyright (C) 2011 Mikkel Krautz <mikkel@krautz.dk>

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

#import "MUServerViewDataSource.h"

@implementation MUServerViewDataSource

- (id) initWithServerModel:(MKServerModel *)model {
    if ((self = [super init])) {
        _model = model;
    }
    return self;
}

- (id) outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {    
    if (item == nil && index == 0) {
        return [_model rootChannel];
    } else if ([item class] == [MKChannel class]) {
        MKChannel *chan = item;
        NSInteger numChans = [[chan channels] count];
        if (index < numChans) {
            return [[chan channels] objectAtIndex:index];
        } else {
            return [[chan users] objectAtIndex:index - numChans];
        }
    }
    return nil;
}

- (BOOL) outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    BOOL isExpandable = NO;
    if (item == nil) {
        isExpandable = YES;
    } else if ([item class] == [MKChannel class]) {
        MKChannel *chan = item;
        if ([[chan channels] count] > 0)
            isExpandable = YES;
        if ([[chan users] count] > 0)
            isExpandable = YES;
    }
    return isExpandable;
}

- (NSInteger) outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    NSInteger numChildren = 0;
    if (item == nil) {
        numChildren = 1;
    } else if ([item class] == [MKChannel class]) {
        MKChannel *chan = item;
        numChildren = [[chan channels] count] + [[chan users] count];
    }
    return numChildren;
}

@end
