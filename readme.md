## MinimumVerticalDistance

Searching segments of scan from file for minimum vertical distance.

### Description

This sample acquires scans and searches a segment of that scan for a minimum
vertical distance assuming the scanner looks downwards vertically.
The minimum distance found is printed to the console and sent via TCP/IP.
The scan viewer will also show the scans to verify the result.

### How To Run

Starting this sample is possible either by running the App (F5) or
debugging (F7+F10). Output is printed to the console and the transformed
point cloud can be seen on the viewer in the web page. The playback stops
after the last scan in the file. To replay, the sample must be restarted.
To run this sample, a device with AppEngine >= 2.5.0 is required.

### Implementation

To run with real device data, the file provider has to be exchanged with the
appropriate scan provider.
To transmit data via TCPIP, the IP address and port have to be adapted-
To disabled view set MAKE_VIEW = false.

### Topics

algorithm, scan, sample, sick-appspace
