//
//  BPImageView.mm
//  BRLayer
//
//  Created by Jinwoo Kim on 2/13/24.
//

#import "BPImageView.hpp"
#import "_BPImageViewLayerDelegate.hpp"
#import <CoreFoundation/CoreFoundation.h>
#import <os/lock.h>
#import <objc/runtime.h>

namespace ns_BPImageView {
    void performCallout(void *info) {
        NSThread *renderThread = NSThread.currentThread;
        NSMutableDictionary *threadDictionary = renderThread.threadDictionary;
        os_unfair_lock *lock = reinterpret_cast<os_unfair_lock *>(static_cast<NSValue *>(threadDictionary[@"lock"]).pointerValue);
        
        os_unfair_lock_lock(lock);
        
        auto blocks = static_cast<NSMutableArray *>(threadDictionary[@"blocks"]);
        
        [blocks enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            ((void (^)())(obj))();
        }];
        [blocks removeAllObjects];
        
        os_unfair_lock_unlock(lock);
    }
}

__attribute__((objc_direct_members))
@interface BPImageView ()
@property (class, retain, readonly, nonatomic) NSThread *renderThread;
@property (copy, readonly, nonatomic) NSURL *url;
@property (retain, readonly, nonatomic) CALayer *sublayer;
@property (retain, readonly, nonatomic) _BPImageViewLayerDelegate *delegate;
@property (retain, readonly, nonatomic) id<UITraitChangeRegistration> displayScaleReg;
@end

@implementation BPImageView

@synthesize sublayer = _sublayer;
@synthesize delegate = _delegate;

+ (NSThread *)renderThread {
    static dispatch_once_t onceToken;
    static NSThread *renderThread;
    static os_unfair_lock lock;
    
    dispatch_once(&onceToken, ^{
        lock = OS_UNFAIR_LOCK_INIT;
        
        renderThread = [[NSThread alloc] initWithBlock:^{
            NSAutoreleasePool *pool = [NSAutoreleasePool new];
            
            CFRunLoopSourceContext context = {
                0,
                nil, // TODO: threadDictionary를 대체할 수 있을듯
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                NULL,
                ns_BPImageView::performCallout
            };
            
            CFRunLoopSourceRef source = CFRunLoopSourceCreate(kCFAllocatorDefault,
                                                              0,
                                                              &context);
            
            CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopDefaultMode);
            
            os_unfair_lock_lock(&lock);
            
            NSMutableDictionary *threadDictionary = NSThread.currentThread.threadDictionary;
            threadDictionary[@"runLoop"] = static_cast<id>(CFRunLoopGetCurrent());
            threadDictionary[@"source"] = static_cast<id>(source);
            
            if (NSMutableArray *blocks = threadDictionary[@"blocks"]) {
                [blocks enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    ((void (^)())(obj))();
                }];
                [blocks removeAllObjects];
            } else {
                threadDictionary[@"blocks"] = [NSMutableArray array];
            }
            
            os_unfair_lock_unlock(&lock);
            
            CFRelease(source);
            
            [pool release];
            
            CFRunLoopRun();
        }];
        
        renderThread.name = @"RenderThread";
        renderThread.threadDictionary[@"lock"] = [NSValue valueWithPointer:&lock];
        
        [renderThread start];
    });
    
    return renderThread;
}

+ (void)runRenderBlock:(void (^)())block __attribute__((objc_direct)) {
    NSThread *renderThread = self.renderThread;
    NSMutableDictionary *threadDictionary = renderThread.threadDictionary;
    os_unfair_lock *lock = reinterpret_cast<os_unfair_lock *>(static_cast<NSValue *>(threadDictionary[@"lock"]).pointerValue);
    
    os_unfair_lock_lock(lock);
    
    auto runLoop = reinterpret_cast<CFRunLoopRef _Nullable>(threadDictionary[@"runLoop"]);
    auto source = reinterpret_cast<CFRunLoopSourceRef _Nullable>(threadDictionary[@"source"]);
    
    NSMutableArray *blocks;
    if (NSMutableArray *_blocks = threadDictionary[@"blocks"]) {
        blocks = _blocks;
    } else {
        blocks = [NSMutableArray array];
        threadDictionary[@"blocks"] = blocks;
    }
    
    id copiedBlock = [block copy];
    [blocks addObject:copiedBlock];
    [copiedBlock release];
    
    os_unfair_lock_unlock(lock);
    
    if (source) {
        CFRunLoopSourceSignal(source);
    }
    
    if (runLoop) {
        CFRunLoopWakeUp(runLoop);
    }
}

- (instancetype)initWithFrame:(CGRect)frame contentsOfURL:(NSURL *)url {
    if (self = [super initWithFrame:frame]) {
        _url = [url copy];
        
        CALayer *layer = self.layer;
        CALayer *sublayer = self.sublayer;
        
        sublayer.drawsAsynchronously = NO;
        sublayer.delegate = self.delegate;
        
        [layer addSublayer:sublayer];
        
        sublayer.contentsScale = self.traitCollection.displayScale;
        _displayScaleReg = [[self registerForTraitChanges:@[UITraitDisplayScale.class] withHandler:^(BPImageView * _Nonnull traitEnvironment, UITraitCollection * _Nonnull previousCollection) {
            sublayer.contentsScale = traitEnvironment.traitCollection.displayScale;
        }] retain];
    }
    
    return self;
}

- (void)dealloc {
    [_url release];
    [_sublayer release];
    [_delegate release];
    [_displayScaleReg release];
    [super dealloc];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    self.sublayer.frame = rect;
    
    [BPImageView runRenderBlock:^{
        CGImageRef image = [UIImage imageWithContentsOfFile:self.url.path].CGImage;
        
        objc_setAssociatedObject(self.sublayer,
                                 _BPImageViewLayerDelegate.imageContextKey,
                                 (id)image,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        [self.sublayer setNeedsDisplay];
    }];
}

- (CALayer *)sublayer {
    if (auto sublayer = _sublayer) return [[sublayer retain] autorelease];
    
    CALayer *sublayer = [[CALayer alloc] initWithLayer:self.layer];
    _sublayer = [sublayer retain];
    return [sublayer autorelease];
}

- (_BPImageViewLayerDelegate *)delegate {
    if (auto delegate = _delegate) return [[delegate retain] autorelease];
    
    _BPImageViewLayerDelegate *delegate = [_BPImageViewLayerDelegate new];
    _delegate = [delegate retain];
    return [delegate autorelease];
}

@end
