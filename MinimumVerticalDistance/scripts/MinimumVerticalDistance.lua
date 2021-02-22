--[[----------------------------------------------------------------------------

  Application Name:  
  MinimumVerticalDistance                                                                                                                       
                                                                                      
  Summary:
  Searching segments of scan from file for minimum vertical distance.  
  
  Description:
  This sample acquires scans and searches a segment of that scan for a minimum 
  vertical distance assuming the scanner looks downwards vertically.
  The minimum distance found is printed to the console and sent via TCP/IP.
  The scan viewer will also show the scans to verify the result.
  
  How to run:
  Starting this sample is possible either by running the app (F5) or 
  debugging (F7+F10). Output is printed to the console and the transformed 
  point cloud can be seen on the viewer in the web page. The playback stops 
  after the last scan in the file. To replay, the sample must be restarted.
  To run this sample, a device with AppEngine >= 2.5.0 is required.
  
  Implementation: 
  To run with real device data, the file provider has to be exchanged with the 
  appropriate scan provider.
  To transmit data via TCPIP, the IP address and port have to be adapted- 
  To disabled view set MAKE_VIEW = false.                               
  
------------------------------------------------------------------------------]]

--Start of Global Scope--------------------------------------------------------- 

MAKE_VIEW = true

OPENING_ANGLE_RAD     = math.rad(270) -- What the device "sees", please look at the scan viewer for the correct values of the actual device
EVALUATION_ANGLE_RAD  = math.rad(120) -- The segment want to evaluate, must be <= OPENING_ANGLE_RAD, a value > 180° makes no sense (only beams downward are of concern)
INVALID_DIST          = 20000         -- A value not recognizable by the device (20 meters)

CLIENT_ADDR           = "192.168.0.71"
CLIENT_PORT           = 4711

SCAN_FILE_PATH        = "resources/TestScenario.xml"
print("Input File: ", SCAN_FILE_PATH)

-- Check device capabilities
assert(Scan,"Scan not available, check capability of connected device")
assert(Scan.MedianFilter,"MedianFilter not available, check capability of connected device")

-- A filter to make the scans more smooth (optional)
medianFilter = Scan.MedianFilter.create()
assert(medianFilter,"Median filter could not be created")
Scan.MedianFilter.setWidth(medianFilter, 7)

-- Where to send the result to
client = TCPIPClient.create()
assert(client, "TCPIPClient could not be created")

TCPIPClient.setIPAddress(client, CLIENT_ADDR)
TCPIPClient.setPort(client, CLIENT_PORT)
TCPIPClient.connect(client)

if true == MAKE_VIEW then
  -- Check capabilities
  assert(View,"View not available, check capability of connected device")
  assert(Scan.Transform,"Transform not available, check capability of connected device")
  
  transform = Scan.Transform.create()
  assert(transform, "Transform could not be created")
  viewer = View.create()
  assert(viewer, "View could not be created")
  viewer:setID("viewer3D")
end

-- Create provider. Providing starts automatically with the register call
-- which is found below the callback function
provider = Scan.Provider.File.create()
Scan.Provider.File.setFile(provider, SCAN_FILE_PATH)
Scan.Provider.File.setDataSetID(provider, 1)

--End of Global Scope-----------------------------------------------------------

--Start of Function and Event Scope---------------------------------------------

-- Called on each received scan
function handleNewScan(scan)
  local filteredScan = Scan.MedianFilter.filter(medianFilter, scan)
  local numOfBeams   = Scan.getBeamCount(scan)
  local anglePerBeam = OPENING_ANGLE_RAD / numOfBeams
  -- starting angle of evaluation
  local startAngle   = -EVALUATION_ANGLE_RAD/2
  -- starting index in scan of evaluation
  local startIndex   = math.ceil(((OPENING_ANGLE_RAD - EVALUATION_ANGLE_RAD) / 2) / anglePerBeam)
  -- ending index in evaluation
  local endIndex     = math.floor(startIndex + (EVALUATION_ANGLE_RAD / anglePerBeam))

  local smallestVerticalDist = INVALID_DIST

  -- Iterate over the points of the interesting segment, find minimum vertical distance
  for i=startIndex,(endIndex-1) do
    local dist, angleDevice = Scan.getPoint(filteredScan, i) -- Evaluate every point of the specified segment
    local angle = angleDevice - math.rad(114.5) -- conversion from device angle to angle in world coordinate system
    if dist > 0 then -- A normal point which is evaluable (See documentation of Scan.getPoint())
      local verticalDist = math.cos(angle) * dist
      if verticalDist < smallestVerticalDist then
        smallestVerticalDist = verticalDist -- the new minimum
      end
    end
  end

  if smallestVerticalDist ~= INVALID_DIST then
    smallestVerticalDist = math.floor(smallestVerticalDist) -- only full mm values are interesting
    print("The smallest vertical distance is " .. smallestVerticalDist .. " mm.")
    if TCPIPClient.isConnected(client) then
      TCPIPClient.transmit(client, "dist=" .. smallestVerticalDist)
    end
  end

  if MAKE_VIEW then
    local pointCloud = Scan.Transform.transformToPointCloud(transform, filteredScan)
    View.add(viewer, pointCloud)
    View.present(viewer)
  end
end
-- Register callback function to "OnNewScan" event. 
-- This call also starts the playback of scans
Scan.Provider.File.register(provider,"OnNewScan", handleNewScan)

--End of Function and Event Scope------------------------------------------------