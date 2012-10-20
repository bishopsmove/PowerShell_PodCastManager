PowerShell_PodcastManager
========================

SYNOPSIS
--------
Retrieves a podcast file based on the RSS URL path provided and saves the podcast files to the destination filepath. Parameters can be provided by the pipeline.

Parameters
----------

# rssURL

The RSS feed URL

# destFilePath

The directory path to save the podcast

# count

The number of most recent podcasts to be downloaded
-1 will include all podcasts

EXAMPLE
--------
GetNewPodcasts -rssURL "http://applebytepodcast.cnettv.com" -destFilePath "c:\podcasts\applebyte" - count -1

EXAMPLE
--------
[array]$feedList =  @("testURL1", "TestFileLoc1", 5),@("testURL2", "TestFileLoc2", -1)

$feedList | %{ GetNewPodcasts -rssURL $_[0] -destFilePath $_[1] -count $_[2] }


License
-------
Standard GPL