#import "AppleSignIn.h"
#import <React/RCTLog.h>
#import <React/RCTUtils.h>

@implementation AppleSignIn

-(dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE()

-(NSDictionary *)constantsToExport
{
    NSDictionary* scopes = @{@"FULL_NAME": ASAuthorizationScopeFullName, @"EMAIL": ASAuthorizationScopeEmail};
    NSDictionary* operations = @{
        @"LOGIN": ASAuthorizationOperationLogin,
        @"REFRESH": ASAuthorizationOperationRefresh,
        @"LOGOUT": ASAuthorizationOperationLogout,
        @"IMPLICIT": ASAuthorizationOperationImplicit
    };
    NSDictionary* credentialStates = @{
        @"AUTHORIZED": @(ASAuthorizationAppleIDProviderCredentialAuthorized),
        @"REVOKED": @(ASAuthorizationAppleIDProviderCredentialRevoked),
        @"NOT_FOUND": @(ASAuthorizationAppleIDProviderCredentialNotFound),
    };
    NSDictionary* userDetectionStatuses = @{
        @"LIKELY_REAL": @(ASUserDetectionStatusLikelyReal),
        @"UNKNOWN": @(ASUserDetectionStatusUnknown),
        @"UNSUPPORTED": @(ASUserDetectionStatusUnsupported),
    };
    
    return @{
        @"Scope": scopes,
        @"Operation": operations,
        @"CredentialState": credentialStates,
        @"UserDetectionStatus": userDetectionStatuses
    };
}


+ (BOOL)requiresMainQueueSetup
{
    return YES;
}


RCT_EXPORT_METHOD(requestAsync:(NSDictionary *)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    if (@available(iOS 13.0, *)) {
        _promiseResolve = resolve;
        _promiseReject = reject;
        
        ASAuthorizationAppleIDProvider* appleIDProvider = [[ASAuthorizationAppleIDProvider alloc] init];
        ASAuthorizationAppleIDRequest* request = [appleIDProvider createRequest];
        request.requestedScopes = options[@"requestedScopes"];
        
        if (options[@"requestedOperation"]) {
            request.requestedOperation = options[@"requestedOperation"];
        }
        
        if (options[@"state"]) {
            request.state = options[@"state"];
        }
        
        ASAuthorizationController* ctrl = [[ASAuthorizationController alloc] initWithAuthorizationRequests:@[request]];
        ctrl.presentationContextProvider = self;
        ctrl.delegate = self;
        [ctrl performRequests];
    } else {
      reject(@"ERR_APPLE_AUTHENTICATION_UNAVAILABLE", @"Apple authentication is not supported on this device.", nil);
    }
}

RCT_EXPORT_METHOD(getCredentialStateAsync:(NSString *)userID
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    if (@available(iOS 13.0, *)) {
        ASAuthorizationAppleIDProvider *appleIDProvider = [[ASAuthorizationAppleIDProvider alloc] init];
        [appleIDProvider getCredentialStateForUserID:userID
                                          completion:^(ASAuthorizationAppleIDProviderCredentialState credentialState,
                                                       NSError  *_Nullable error) {
            if (error) {
                return reject(@"ERR_APPLE_AUTHENTICATION_CREDENTIAL", error.localizedDescription, RCTNullIfNil(error));
            }
            resolve([self exportCredentialState:credentialState]);
        }];
    } else {
      reject(@"ERR_APPLE_AUTHENTICATION_UNAVAILABLE", @"Apple authentication is not supported on this device.", nil);
    }
}


- (ASPresentationAnchor)presentationAnchorForAuthorizationController:(ASAuthorizationController *)controller {
    return RCTKeyWindow();
}


- (void)authorizationController:(ASAuthorizationController *)controller
   didCompleteWithAuthorization:(ASAuthorization *)authorization {
    ASAuthorizationAppleIDCredential * credential = authorization.credential;
    
    //    RCTLog(@"APPLE_identityToken: %@", credential.identityToken);
    //    RCTLog(@"APPLE_authorizationCode: %@", credential.authorizationCode);
    //    RCTLog(@"APPLE_state: %@", credential.state);
    //    RCTLog(@"APPLE_user: %@", credential.user);
    //    RCTLog(@"APPLE_authorizedScopes: %@", credential.authorizedScopes);
    //    RCTLog(@"APPLE_fullName: %@", credential.fullName);
    //    RCTLog(@"APPLE_email: %@", credential.email);
    //    RCTLog(@"APPLE_realUserStatus: %ld", (long)credential.realUserStatus);
    
    NSDictionary * result = @{
        @"identityToken": RCTNullIfNil([self exportData:credential.identityToken]),
        @"authorizationCode": RCTNullIfNil([self exportData:credential.authorizationCode]),
        @"state": RCTNullIfNil(credential.state),
        @"user": credential.user,
        //        @"authorizedScopes": credential.authorizedScopes,
        @"fullName": RCTNullIfNil([self exportFullName:credential.fullName]),
        @"email": RCTNullIfNil(credential.email),
        @"realUserStatus": [self exportRealUserStatus:credential.realUserStatus]
    };
    
    _promiseResolve(result);
}


- (void)authorizationController:(ASAuthorizationController *)controller
           didCompleteWithError:(NSError *)error {
    _promiseReject(@"ERR_APPLE_AUTHENTICATION_REQUEST", error.localizedDescription, RCTNullIfNil(error));
}

- (NSString *)exportCredentialState:(ASAuthorizationAppleIDProviderCredentialState)credentialState{
    switch (credentialState) {
        case ASAuthorizationAppleIDProviderCredentialRevoked:
            return @"REVOKED";
        case ASAuthorizationAppleIDProviderCredentialAuthorized:
            return @"AUTHORIZED";
        case ASAuthorizationAppleIDProviderCredentialNotFound:
            return @"NOT_FOUND";
        case ASAuthorizationAppleIDProviderCredentialTransferred:
            return @"TRANSFERRED";
    }
}

- (NSString *)exportRealUserStatus:(ASUserDetectionStatus) detectionStatus {
    switch (detectionStatus) {
        case ASUserDetectionStatusLikelyReal:
            return @"LIKELY_REAL";
        case ASUserDetectionStatusUnknown:
            return @"UNKNOWN";
        case ASUserDetectionStatusUnsupported:
        default:
            return @"UNSUPPORTED";
    }
}

- (NSDictionary *)exportFullName:(NSPersonNameComponents *)fullName {
    if (fullName) {
        return @{
            @"givenName": RCTNullIfNil(fullName.givenName),
            @"middleName": RCTNullIfNil(fullName.middleName),
            @"familyName": RCTNullIfNil(fullName.familyName),
            @"namePrefix": RCTNullIfNil(fullName.namePrefix),
            @"nameSuffix": RCTNullIfNil(fullName.nameSuffix),
            @"nickname": RCTNullIfNil(fullName.nickname),
        };
    }
    
    return nil;
}

// TODO: implement later
- (NSArray<NSString *> *)exportAuthorizedScopes:(NSArray<ASAuthorizationScope> *)authorizedScopes {
    return nil;
}

- (NSString *)exportData:(NSData *)data {
    if (data) {
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    
    return nil;
}

@end
