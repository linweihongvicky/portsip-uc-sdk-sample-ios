# Welcome to PortSIP free UC SDK for iOS

PortSIP UC SDK is a **free SIP SDK** which allows you to create your SIP-based application for multiple platforms (iOS, Android, Windows, macOS and Linux) base on it.
**PortSIP UC SDK is free, but it was limited only work with** [PortSIP PBX](https://www.portsip.com/portsip-pbx)

**If you are looking for a SIP SDK working with 3rd PBX or SIP server, please check our** [PortSIP VoIP SDK](https://github.com/portsip/portsip-voip-sdk-sample-for-ios)

The PortSIP UC SDK is a powerful and versatile set of tools that dramatically accelerate SIP application development. It includes a suite of stacks, SDKs, and some Sample projects, each of which enables developers to combine all the necessary components to create an ideal development environment for every application's specific needs.

The PortSIP UC SDK complies with IETF and 3GPP standards, and is IMS-compliant (3GPP/3GPP2, TISPAN and PacketCable 2.0).
These high performance SDKs provide unified API layers for full user control and flexibility.


## Getting Started

You can checkout our UC SDK with SIPsample project source code by performing below command:<br><br>
```git clone https://github.com/portsip/portsip-uc-sdk-sample-ios.git```

## Contents

 The downloaded sample package contains almost all of materials for PortSIP SDK: documentation,
Dynamic/Static libraries, sources, headers, datasheet, and everything else a SDK user might need!


## SDK User Manual

To be started with, it is recommended to read the documentation of PortSIP UC SDK, [SDK User Manual page](https://www.portsip.com/voip-sdk-user-manual/), which gives a brief description of each API function.


## Website

Some general interest or often changing PortSIP UC SDK information will be posted on the [PortSIP website](https://www.portsip.com) in real time. The release contains links to the site, so while browsing you may see occasional broken links  if you are not connected to the Internet. To be sure everything needed for using the PortSIP UC SDK has been contained within the release.

## Support

Please send email to our <a href="mailto:support@portsip.com">Support team</a> if you need any help.

## Installation Prerequisites

Development using the PortSIP UC SDK for iOS requires an Intel-based Macintosh running Snow Leopard (OS X 10.8 or higher)

## Apple's iOS SDK

If you are not yet a registered Apple developer, to be able to develop applications for the iOS, you do need to become a registered Apple developer. After registered, Apple grants you free access to a select set of technical resources, tools, and information for developing with iOS, Mac OS X, and Safari. You can open <a href="http://developer.apple.com/programs/register/">registration page</a> and enroll.
Once registered, you can then go to the <a
href="http://developer.apple.com/devcenter/ios/index.action">iOS Dev Center</a>, login and download the iOS SDK. The SDK contains documentation, frameworks, tools, and a simulator to help develop iOS applications. XCode (the developer toolset for iOS application development) is included in the downloaded package as well, so you do not need to purchase any developer tools to build iOS applications - that is included in the enrollment fee.
You will need to use a minimum of iOS SDK 10 for developing iPhone and iPod Touch applications. At the time of writing this document, iOS SDK 13 is the latest available and supported version.

## Note:

Beta and GM seed versions of the iOS SDK are generally not supported unless noted otherwise.
Regardless of the iOS SDK you're using for development, you can still target your application for devices running on an older iOS version by configuring your Xcode project's iOS Deployment Target build settings. Be sure to add runtime checks where appropriate to ensure that you use only those iOS features available on the target platform/device. If your application attempts to use iOS features that are not available on the device, your application may crash.

## Device Requirements

Applications built with PortSIP UC SDK for iOS can be run on iPhone 4S or higher, iPod touch 4 or higher, and iPad 2 or higher. These devices must be running iOS 9 or higher. We strongly recommend you to test your applications on actual devices to ensure that they work as expected and perform well. Testing on the simulators does not provide a good measure of how the application will perform on the physical device.


## Frequently Asked Questions
### 1. Is PortSIP UC SDK free of charge?

Yes, the PortSIP UC SDK is totally free, but it was limited to work with <a href="https://www.portsip.com/portsip-pbx/" target="_blank">PortSIP PBX</a> only.

### 2. What is the difference between PortSIP UC SDK and PortSIP VoIP SDK?
The <a href="https://www.portsip.com/portsip-uc-sdk/" target="_blank">PortSIP UC SDK</a> is free of charge, but is limited to work with <a href="https://www.portsip.com/portsip-pbx/" target="_blank">PortSIP PBX</a> only; the <a href="https://www.portsip.com/portsip-pbx/" target="_blank">PortSIP VoIP SDK</a> is not free of charge and can work with any 3rd SIP based PBX. The UC SDK also provides a lot of unique features than the VoIP SDK which are provided by <a href="https://www.portsip.com/portsip-pbx/" target="_blank">PortSIP PBX</a>.

### 3. Where can I download the PortSIP UC SDK for test?
All sample projects of the **free PortSIP UC SDK** can be found and downloaded at github:
  <br>
```git clone https://github.com/portsip/portsip-uc-sdk-sample-ios.git
   git clone https://github.com/portsip/portsip-uc-sdk-sample-android.git
   git clone https://github.com/portsip/portsip-uc-sdk-sample-mac.git
   git clone https://github.com/portsip/portsip-uc-sdk-sample-win.git
   git clone https://github.com/portsip/portsip-uc-sdk-sample-for-xamarin.git
```


### 4. How can I compile the sample project?

  1. Checkout the UC SDK and sample project from github.
  2. Open the project by your IDE.
  3. Compile the sample project directly.


### 5. How can I create a new project with PortSIP VoIP SDK?

  1. Checkout the Sample project from github to a local directory.
  2. Run the XCode or other IDE and create a new iOS Project.
  3. Drag and drop PortSIPUCSDK.framework from Finder to XCode->Frameworks.
  4. Add dependant Frameworks:
      Build Phases->Link Binary With Libraries, add libc++.tbd, libresolv.tbd, VideoToolbox.framework, GLKit.framework, MetalKit.framework.
  5. Add "-ObjC" to "Build Settings"-> "Other Linker Flags"
  6. Add the code in .h file to import the SDK. For example:
```
   #import <PortSIPUCSDK/PortSIPUCSDK.h>
```
  7. Inherit the interface PortSIPEventDelegate to process the callback events. For example:
```
      @interface AppDelegate : UIResponder <UIApplicationDelegate,PortSIPEventDelegate>{
              PortSIPSDK* mPortSIPSDK;
      }
      @end
```
  8. Initialize sdk. For example:
```
      mPortSIPSDK = [[PortSIPSDK alloc] init];
      mPortSIPSDK.delegate = self;
```
  9. For more details, please read the Sample project source code.


### 6. Is the SDK thread safe?
Yes, the SDK is thread safe. You can call any of the API functions without the need to consider the multiple threads.
Note: the SDK allows to call API functions in callback events directly - except for the "onAudioRawCallback", "onVideoRawCallback", "onReceivedRtpPacket", "onSendingRtpPacket" callbacks.

### 7. Does the SDK support native 64-bit?
Yes, both 32-bit and 64-bit are supported for SDK.

### 8. Does the SDK support VoIP PUSH?
Yes, please refer to <a href="https://www.portsip.com/knowledge-base/" target="_blank">https://www.portsip.com/knowledge-base/</a> for more details.
