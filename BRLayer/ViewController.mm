//
//  ViewController.mm
//  BRLayer
//
//  Created by Jinwoo Kim on 2/13/24.
//

#import "ViewController.hpp"
#import "BPImageView.hpp"

@implementation ViewController

- (void)loadView {
    NSURL *url = [NSBundle.mainBundle URLForResource:@"image" withExtension:@"png"];
    BPImageView *imageView = [[BPImageView alloc] initWithFrame:CGRectNull contentsOfURL:url];
    self.view = imageView;
    [imageView release];
}


@end
