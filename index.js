import React from 'react'
import { NativeModules, requireNativeComponent, Platform , Platform } from 'react-native'

const { AppleSignIn } = NativeModules

export const RNSignInWithAppleButton = requireNativeComponent('RNCSignInWithAppleButton')

const majorVersionIOS = parseInt(Platform.Version, 10);

export const SignInWithAppleButton = (buttonStyle, callBack) => {
  if (Platform.OS === 'ios' && majorVersionIOS >= 13) {
    return <RNSignInWithAppleButton style={ buttonStyle } onPress={ async () => {
      await AppleSignIn.requestAsync({
        requestedScopes: [AppleSignIn.Scope.FULL_NAME, AppleSignIn.Scope.EMAIL],
      }).then((response) => {
        callBack(response) //Display response
      }, (error) => {
        callBack(error) //Display error
      })
    } }/>
  } else {
    return null
  }
}

export default AppleSignIn
