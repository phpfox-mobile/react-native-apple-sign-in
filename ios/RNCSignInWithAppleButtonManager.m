#import <React/RCTViewManager.h>
#import <React/RCTUtils.h>
#import "RNCSignInWithAppleButton.h"
@import AuthenticationServices;

@interface RNCSignInWithAppleButtonManager : RCTViewManager
@end

@implementation RNCSignInWithAppleButtonManager

RCT_EXPORT_MODULE(RNCSignInWithAppleButtonManager)

- (UIView *)view
{
    if (@available(iOS 13.0, *)) {
        return [[RNCSignInWithAppleButton alloc] initWithAuthorizationButtonType:ASAuthorizationAppleIDButtonTypeDefault authorizationButtonStyle:ASAuthorizationAppleIDButtonStyleBlack];
    }
    return nil;
}

RCT_EXPORT_VIEW_PROPERTY(onPress, RCTBubblingEventBlock)

@end
