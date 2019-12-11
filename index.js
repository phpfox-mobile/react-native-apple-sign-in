import React from 'react'
import { NativeModules, requireNativeComponent, Platform } from 'react-native'

const { AppleSignIn } = NativeModules

export const RNSignInWithAppleButton = requireNativeComponent('RNCSignInWithAppleButton')

const majorVersionIOS = parseInt(Platform.Version, 10)

const IS_SUPPORTED = Platform.OS === 'ios' && majorVersionIOS >= 13

export const SignInWithAppleButton = (buttonStyle, callBack) => {
  if (IS_SUPPORTED) {
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

export const Scope = {
  FULL_NAME: IS_SUPPORTED ? AppleSignIn.Scope.FULL_NAME : null,
  EMAIL: IS_SUPPORTED ? AppleSignIn.Scope.EMAIL : null
}

export default {
  request: IS_SUPPORTED ? AppleSignIn.requestAsync : null,
  getCredentialState: IS_SUPPORTED ? AppleSignIn.getCredentialStateAsync : null,
}
