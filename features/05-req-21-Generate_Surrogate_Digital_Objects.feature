@req-21 @done
Feature: Generate Surrogate Digital Objects

DELETEME: REQ-21
DELETEME: 
DELETEME: The system shall generate surrogate formats from primary digital object as required.
DELETEME: 
DELETEME: 1.1 It shall display derived assets (digital objects) as required (e.g. high resolution tiff to low resolution thumbnail in jpeg).


Possible list of tasks by object type:

audio:
* VirusScan
* VerifyAudio - Check that it is a valid audio file
* CreateMP3 - make an MP3 version of the file for delivery to the user
* CreateOgg - make an ogg version of the file for delivery to the user, Note: pick a html5 supported format as fall back - need wp6 input

pdfdoc:
* VirusScan
* VerifyPdf - Check that it is a valid pdf file
* FullTextIndex - could/should this happen as a background task??

Image:
* VirusScan
* VerifyImage - Check that it is a valid image file
* CreateThumbnail - make one or more thumbnail images for various display modes
* CreateLowRes - make a lower resolution version for delivery to the user. Note: ResizeImage is probably better, might be able to get rid of the above
* CreateZoomified - make zoomified tiles (needs to be decided) -- might be messy - need wp6 input
* CreateSeadragon - make seadragon tiles (needs to be decided) -- might be messy - need wp6 input

Generic:
* checksum of assets which allows sha256, rmd160 and md5. This is so we can store this information for later verification of the object.

Note that there must be something in the object datastreams to record
each of these events, that it was run and when. Publishing an object
will be blocked until all required background jobs have been run once.

  Note could the above be done with audit logs ?

Current implementation:
When an asset is uploaded the FilesController create function creates a BackgroundTasks::QueueManager object and calls the appropriate process method depending on the object type.
QueueManager uses resque to enqueue the appropriate background tasks for that object type (as configured in config/settings.yml)
Some dummy workers are available, they only print output to indicate that they have run, but do not yet do any real work

The workers might be better tested via rspec than cucumber.

This feature will introduce a number of runtime dependancies, the
following list is just an example

* clamav
* ffmpeg
* imagemagick
* openssl

Scenario Outline: Running background jobs and creating surrogates for different object types
  Given I am logged in as "user1" in the group "cm"
  And I have created a <type> object
  Then the asset should be virus checked
  And the asset type should be verified
  And the asset should have <surrogates> created

  Examples:
    | type   | surrogates |
    | audio  | mp3, clip  |
    | pdfdoc | extract    |

## note for the above checksum and virus check are actions against any
## object, "virus checked" and "checksum" should be the actions
##
## e.g. Then the asset should be "virus checked"
## e.g. Then the asset should be "checksummed"
## e.g. Then the asset should be "compressed"
