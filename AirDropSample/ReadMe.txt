# AirDropSample


AirDropSample demonstrates three use cases for incorporating AirDrop into an app.

1) Sending/receiving a URL with a custom scheme via AirDrop

URLs can be used as a simple way to transfer information between devices. Apps can easily parse a received URL to determine what action to take. After an app registers a URL scheme (including custom schemes), the system will know to launch that app when a URL of that type is received.


2) Sending/receiving an instance of a custom class as data via AirDrop

Often times an app will want to send some data it has, for instance a serialized object, to another device. Apps can easily do this by attaching a UTI to that data, and then registering to accept that UTI on the receiving side.


3) Asynchronously preprocessing content after the user decides to send via AirDrop

There are certain circumstances when a piece of content needs to be preprocessed before a send. The APIs allow for this preprocessing to happen asynchronously.


## App Usage

AirDrop only operates on certain iOS devices. As of the time of this writing the currently supported devices are: iPhone 5, iPhone 5c, iPhone 5s, iPad (4th generation), iPad mini, and iPod touch (5th generation). For the most up to date list see www.apple.com.

AirDrop only operates on iOS devices (not iOS Simulator). To properly use this app at least two iOS devices are required.

This app registers a custom URL scheme, and a custom file UTI. For the device to accept the registration, the app must be installed onto the device using Product->Install.


## API Usage

### General:

To send content using AirDropSample you must use the UIActivityViewController. The UIActivityViewController handles displaying the whole share sheet which includes: sharing with AirDrop, sharing with other apps/services, and system functions. When a UIActivityViewController instance is created, it is passed the objects it will be sending. Each object should either be of type UIActivityItemProvider, or conform to the UIActivityItemSource protocol. By passing in objects of this type, the app is able to set metadata to send along with the shared content. This is especially important if another instance of the app plans on receiving the content on the other side.


### Use Case 1: Sending/Receiving URLs with custom schemes

To send a URL the app can simply pass the URL to a UIActivityViewController when the view controller is being initiated. If the app has metadata to send with the URL, it should create a class that encompasses the URL and conforms to the UIActivityItemSource protocol.

To receive a URL with a custom scheme the app must register itself as being able to accept that scheme. The registration is done using the URL Types field in the Info section of the project target.


### Use Case 2: Sending/Receiving an instance of a custom class as data

When sending/receiving content from an instance of a custom class as data the app should create its own custom Universal Type Identifier (UTI). This is done using the Info section of the project target. Following are the two fields that need to be added:

1) Document types: This field registers the app to accept the custom UTI. This field can be used to accept standard file type UTIs as well.
2) Exported Type UTIs: This field registers the custom UTI with the system.


To send an instance of a custom class as data the app has two options:

1) Write the object out to a file that conforms to the custom UTI. Then pass an NSURL fileURL object that contains that file path to the UIActivityViewController.
2) Serialize the object into an NSData object, and pass that data object to the UIActivityViewController. The UIActivityViewController will then call the UIActivityItemSource protocol method activityViewController:dataTypeIdentifierForActivityType: to determine the custom UTI.


When the AirDropSample receives a file with a custom UTI it looks for the apps that have registered with that UTI. If there are multiple apps that have registered for that UTI a list will appear. When a given app is chosen it will launch, and the application:openURL:sourceApplication:annotation: App Delegate method will be called. Inside that method the received file will be processed.



### Use Case 3: Asynchronously preprocessing content after the user decides to send via AirDrop

The app may not want to perform an action (e.g. downloading content, filtering an image, etc.) until the user selects their sending method from the share sheet. By subclassing UIActivityItemProvider the app can override the item method which will execute on a separate thread. This allows the app to asynchronously execute additional actions before sending. UIActivityItemProvider conforms to the UIActivityItemSource protocol allowing the subclass to send metadata.



## Implementation Details

### General:

As mentioned in the description this sample app exemplifies three different use cases for AirDrop. Below are listed the relevant classes for each use case.


### Use Case 1: Sending/Receiving URLs with custom schemes


APLCustomURLContainer.{h/m}

The APLCustomURLContainer class is a model class that stores the URL with the custom scheme and handles the UIActivityItemSource protocol methods. It implements one of the optional protocol methods, activityViewController:thumbnailImageForActivityType:suggestedSize:. This method provides an image to the receiver of the custom URL.


APLCustomURLViewController.{h/m}

The APLCustomURLViewController allows the user to edit the custom URL.


APLAppDelegate.{h/m}

The APLAppDelegate's method application:openURL:sourceApplication:annotation: is called when the app receives content. In this case, a URL with a custom scheme that is defined in the Info section of the project target is received.



### Use Case 2: Sending/Receiving an instance of a custom class as data


APLProfile.{h/m}

The APLProfile class is a model class that stores the profile information (name and image) and handles the UIActivityItemSource protocol methods. When sharing a profile all the information in the object instance is being shared. This class sends an instance of itself by serializing its information as NSData, and then sending the NSData. To tell the receiving side what kind of information the NSData stores the class implements the activityViewController:dataTypeIdentifierForActivityType: method from the UIActivityItemSource protocol. This method returns the custom UTI defined by the app.


APLProfileViewController.{h/m}

This view controller handles displaying all the profile information, and presenting the share sheet. It also allows editing of the profile information. One important piece the user can edit is the content mode of the image displayed. The content mode determines whether the image will fill or fit the provided frame. This decision affects how the preview image will look in the alert on the receiver.


APLProfileTableViewController.{h/m}

This view controller displays all the profile's the app has stored in its file system. When a new profile is received through an AirDrop transfer this view controller's view is automatically pushed onto the stack. It allows for both adding/deleting of profiles.


APLAppDelegate.{h/m}

Just like with receiving a URL with a custom scheme the APLAppDelegate method application:openURL:sourceApplication:annotation: is called when a profile is received. When a profile is received the user will be shown a APLProfileViewController with the profile information, and asked if they want to save it. Because another profile could arrive while the user is deciding if they want to keep the currently displayed profile, there must be a queueing system. When the first profile is received the APLAppDelegate adds it to a queue and presents a new UINavigationController. If another profile is received it will be enqueued. When a decision about the first profile is made by the user the navigation controller will push the next enqueued profile onto the stack. This presenting all happens in its own window to prevent the underlying views from being disrupted.



### Use Case 3: Asynchronously preprocessing content after the user decides to send via AirDrop


APLAsyncImageActivityItemProvider.{h/m}

The APLAsyncImageActivityItemProvider class is a subclass of UIActivityItemProvider. The reason it subclasses UIActivityItemProvider is to override the item method which executes on a separate thread. This allows content to be asynchronously prepared before it is sent. This class uses the item method to load an image and apply two filters to it before it is sent.


APLAsyncImageViewController.{h/m}

This view controller handles presenting the share sheet to share the image that will be filtered. It also registers as the AsyncImageActivityItemProvider's delegate to monitor the loading and filtering progress. An alert is shown when the loading and filtering is in process.



===========================================================================

Copyright (C) 2013 Apple Inc. All rights reserved.
