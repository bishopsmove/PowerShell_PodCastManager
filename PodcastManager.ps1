

<#

.SYNOPSIS

Retrieves a podcast file based on the RSS URL path provided and saves the podcast files to the destination filepath. Parameters can be provided by the pipeline.

.PARAMETER rssURL

The RSS feed URL

.PARAMETER destFilePath

The directory path to save the podcast

.PARAMETER count

The number of most recent podcasts to be downloaded
-1 will include all podcasts

.EXAMPLE

GetNewPodcasts -rssURL "http://applebytepodcast.cnettv.com" -destFilePath "c:\podcasts\applebyte" - count -1

.EXAMPLE
[array]$feedList =  @("testURL1", "TestFileLoc1", 5),@("testURL2", "TestFileLoc2", -1)

$feedList | %{ GetNewPodcasts -rssURL $_[0] -destFilePath $_[1] -count $_[2] }

#>


function GetNewPodcasts(){
[CmdletBinding()]
param(
        [Parameter(Mandatory=$True,Position=0,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [string]$rssURL,
        [Parameter(Mandatory=$True,Position=1,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [string]$destFilePath,
        [Parameter(Mandatory=$True,Position=2,ValueFromPipeline=$True,ValueFromPipelinebyPropertyName=$True)]
        [int]$count
)

import-module bitstransfer
[int]$fileCount = 0
$podcast_nodes = $null
$path = $destFilePath
$rssPath = $rssURL
$wc = New-Object System.Net.WebClient
$rss = [xml]$wc.DownloadString($rssPath)
if($count -ne -1){
if($count -gt 0){
[int]$num = $count - 1
<#
Unfortunately, XpathNodelLists and XMLNodeLists are a pain in the butt when it comes to indexes. The clean up is in the next section.
#>
0..$num | % { $podcast_nodes += ,$rss.rss.SelectNodes("//item//enclosure").Item($_)}
}}
else{
$podcast_nodes = $rss.rss.SelectNodes("//item//enclosure")
$count = $podcast_nodes.Count
}

$podcast_nodes | %{$_}|?{
[string]$url = ""
<#
We need to clean up the gap between what a nodelist returns and what the item array object returns (see lines 57 & 60)
Instead of just working with the ForEach iterator return, we will pass it to a string variable and insulate the rest
of the function.
Also, thanks to the examples provided by CNET, I've accounted for their lack of a url attribute in the link node
#>
if($_.GetType().Name -eq "XmlElement"){
    
    $url = $_.GetAttribute("url")
}
else{
$url = $_
}
$filename = $url.Split('`/')[-1]
$downloadfile = $url
$localFilename = [string]::Concat($path,"\",$filename)
if(((Test-Path $localFilename) -eq $false) -and ($fileCount -lt $count)) 
{
 Start-BitsTransfer $downloadfile $localFilename -async
 $fileCount += 1
 write-host "${filename} now downloading."
 } }
 $jobs = Get-BitsTransfer
 if($jobs -eq $null){write-host "No new file found"} 
 
 return $fileCount

}

# @("http://revision3.com/destructoid/feed/MP4-hd30", "c:\podcasts\destructoid", 5)

[array]$feedList = ,@("http://podcast.cnbc.com/mmpodcast/lightninground.xml", "C:\Users\Bishops.Move\Music\iTunes\iTunes Media\Podcasts\MAD MONEY W_ JIM CRAMER - Full Episode", -1)
[int]$fileCount = 0
$feedList | %{ GetNewPodcasts -rssURL $_[0] -destFilePath $_[1] -count $_[2] } | %{ $fileCount += $_}

#

do{
Get-BITSTransfer |  format-table -property JobId, @{Label="File"; Expression={$_.FileList[0].LocalName.Split('`\')[-1]}},`
 JobState, @{Label="BytesTransferred (MB)"; Expression={([string]::format("{0:N2}", ($_.BytesTransferred / 1MB)))}},`
  @{Label="BytesTotal (MB)"; Expression={([string]::format("{0:N2}", ($_.BytesTotal / 1MB)))}},`
  @{Label="Percent Complete"; Expression={([string]::format("{0:P}", ($_.BytesTransferred/$_.BytesTotal )))}} | out-default
  
  start-Sleep -Seconds 10
  }while(($fileCount -gt 0) -AND (Get-BitsTransfer | ?{ $_.JobState -ne "Transferred"}))
  
Get-BitsTransfer | ?{ if($_.JobState -eq "Transferred"){

Complete-BitsTransfer -BitsJob $_.JobId} }

$feedList = $null




