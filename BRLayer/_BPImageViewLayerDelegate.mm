//
//  _BPImageViewLayerDelegate.mm
//  BRLayer
//
//  Created by Jinwoo Kim on 2/13/24.
//

#import "_BPImageViewLayerDelegate.hpp"
#import <objc/runtime.h>

@implementation _BPImageViewLayerDelegate

+ (void *)imageContextKey {
    static void *imageContextKey = &imageContextKey;
    return imageContextKey;
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx {
    if (id image = objc_getAssociatedObject(layer, _BPImageViewLayerDelegate.imageContextKey)) {
        NSLog(@"Drawing in thread: %@", NSThread.currentThread);
        
        auto imageRef = static_cast<CGImageRef>(image);
        
        CGAffineTransform transform = CGAffineTransformMake(1.f, 0.f, 0.f, -1.f, 0.f, layer.bounds.size.height);
        CGContextConcatCTM(ctx, transform);
        CGContextDrawImage(ctx, layer.bounds, imageRef);
        
    }
}

@end
