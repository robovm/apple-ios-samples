Copyright © 2007-2009 by Apple Inc.  All Rights Reserved.

Quartz Composer Plugin

IMStatus					A Quartz Composer plug-in that returns information about 
						the logged in user and his or her buddies on a given 
						instant messaging service.

Sample Requirements				The plugin was created using the Xcode editor running 
						under Mac OS X 10.6.x or later. 

About the sample				A Quartz Composer plug-in that implements a custom 
						provider patch that outputs the user instant messaging 
						status as well as for his or her buddies.

Using the Sample				Open the project using the Xcode editor which can be found 
						in /Developer/Applications. From the main menu, 
						choose "Project", set "Active Configuration" to "Release", 
						and "Active Target" to "Build & Copy".  These settings are
						also available from the top left corner of the 'Overview' 
						pull-down window. Build the project. Once the build has 
						completed successfully, the plug-in can be used as a 
						regular QC patch in the Quartz Composer editor (also 
						installed under /Developer/Applications), by selecting it 
						from the Library - Plugin panel.

						This plug-in provides structures of user and buddies 
						information. For the user information, it can be 
						retrieved from the "User Status" output port using 
						"Structure Key Member" patch to get user information such 
						as user "Image" and "Title". For each of the buddy, to 
						get the information such as "statusImage", "statusTitle", 
						and "screenName", it can be retrieved from the "Buddies 
						Status" output port.

Installation					n/a

Changes from Previous Versions			n/a

Feedback and Bug Reports			Please send all feedback about this sample to:
						http://developer.apple.com/contact/feedback.html

						Please submit any bug reports about this example to 
						http://developer.apple.com/bugreport
