# N8iveNetworking

 ![Platform](https://img.shields.io/badge/Platform-iOS%2C%20macOS-lightgray)  ![Swift Package Manager](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-green)  ![License](https://img.shields.io/badge/License-MIT-green) 

A simple networking Swift pacage for iOS & macOS.

------

## Requirements

- iOS 12+, macOS 10.14+
- Xcode11
- Swift 5

------

## Installation

#### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/n8iveapps/N8iveNetworking.git", from: "0.0.1")
]
```

------

## Usage

#### OAuth2

```swift
let authClient = OAuth2Client(configuration: OAuth2ClientConfiguration(clientId: "137865357678-opatlf959msgha35ra4tfsugg1pa4gvl.apps.googleusercontent.com", authURL: "https://accounts.google.com/o/oauth2/auth", tokenURL: "https://www.googleapis.com/oauth2/v4/token", scope: "https://www.googleapis.com/auth/youtube https://www.googleapis.com/auth/youtube.readonly https://www.googleapis.com/auth/youtubepartner https://www.googleapis.com/auth/youtubepartner-channel-audit https://www.googleapis.com/auth/youtube.upload", redirectURL: "com.googleusercontent.apps.137865357678-opatlf959msgha35ra4tfsugg1pa4gvl:/oauth2Callback", responseType: "code"))
authClient.configuration.parameters = ["access_type":"offline", "hl":"en"]
authClient.clientIsLoadingToken = {
	print("Loading OAuth2 token ...")
}
authClient.clientDidFinishLoadingToken = {
	print("token:\n\(authClient.session?.accessToken ?? "No token !!!")")
}
authClient.clientDidFailLoadingToken = { error in
	print("error:\n\(error.localizedDescription)")
}
authClient.authorize()
```



------

## License

MIT License (MIT)

```
Copyright (c) 2020 MuhammadBassio

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```