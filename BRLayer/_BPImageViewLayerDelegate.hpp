//
//  _BPImageViewLayerDelegate.hpp
//  BRLayer
//
//  Created by Jinwoo Kim on 2/13/24.
//

#import <QuartzCore/QuartzCore.h>

NS_ASSUME_NONNULL_BEGIN

__attribute__((objc_direct_members))
@interface _BPImageViewLayerDelegate : NSObject <CALayerDelegate>
@property (class, readonly, nonatomic) void *imageContextKey;
@end

NS_ASSUME_NONNULL_END
