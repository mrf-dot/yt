#!/bin/env pwsh
param (
	$option
)

# Define your google api at the top of C:\Users\<Username>\p.ps1 (in your home directory) like this:
# $env:GoogleApiKey = 'your api key goes here'
# Then add this file to anywhere in your path
$GoogleApiKey = $env:GoogleApiKey
if ([string]::IsNullOrEmpty($GoogleApiKey)) {
	Write-Host 'You have not defined a valid API key. Please define a valid API key by adding the following line to your startup profile (C:\Users\<Username>\p.ps1):

	$env:GoogleApiKey = "your-api-key"

If you do not have an API key, go to https://console.cloud.google.com/apis/credentials and click "Create Credentials". Then click "Show Key" under the "API Keys" section'
	exit
}


# Video and audio arguments
$vArgs = "--restrict-filenames --recode-video mp4 -f 'bestvideo[height<=?1080][fps<=?30][vcodec!=?vp9]+bestaudio'"
$aArgs = "--restrict-filenames --extract-audio --audio-format mp3"

# Form the URLS
$baseUrl = "https://www.googleapis.com/youtube/v3/search?q="
$authUrl = "&key=$googleApiKey"
$videoUrl = "&maxResults=20&part=snippet&type=video"
$playlistUrl = "&maxResults=5&part=snippet&type=playlist"

# Display the results of a query in powershell table form
function Table-Results {
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		$queryResults
	)
	$tbl = New-Object System.Data.DataTable "Search Results"
	$col0 = New-Object System.Data.DataColumn Result
	$col1 = New-Object System.Data.DataColumn Title
	$col2 = New-Object System.Data.DataColumn Channel
	$tbl.columns.add($col0)
	$tbl.columns.add($col1)
	$tbl.columns.add($col2)
	for ( $i = 1; $i -le $queryResults.items.count; $i++ ) {
		$row = $tbl.NewRow()
		$row.Result = $i
		$row.Title = [System.Net.WebUtility]::HtmlDecode($queryResults.items[$i - 1].snippet.title)
		$row.Channel = [System.Net.WebUtility]::HtmlDecode($queryResults.items[$i - 1].snippet.channeltitle)
		$tbl.rows.add($row)
	}
	$tbl | Format-Table | Out-Host
}

function Select-Result {
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		$queryResults
	)
	do {
		try {
			$isNum = $true
			$selection = Read-Host "Selection #"
			if ($selection) {
				[int] $selection = $selection
			}
			else {
				return -1
			}
		}
		catch {
			$isNum = $false
		}
	} until ($selection -ge 1 -and $selection -le $queryResults.items.count -and $isNum)
	return $selection
}


# Search Youtube and return video url
function Search-YoutubeVideo {
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $query
	)
	$query = [uri]::EscapeDataString($query)
	$searchUri = "$baseUrl$query$authUrl$videoUrl"
	$queryResults = Invoke-RestMethod -Uri $searchUri -Method Get
	Table-Results $queryResults
	$video = Select-Result $queryResults
	if ($video -eq -1) {
		return ""
	}
	return "https://youtube.com/watch?v=$($queryResults.items[$video - 1].id.videoId)"
}

# Search Youtube and return playlist url
function Search-YoutubePlaylist {
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $query
	)
	$query = [uri]::EscapeDataString($query)
	$searchUri = "$baseUrl$query$authUrl$playlistUrl"
	$queryResults = Invoke-RestMethod -Uri $searchUri -Method Get
	Table-Results $queryResults
	$playlist = Select-Result $queryResults
	if ($playlist -eq -1) {
		return ""
	}
	return "https://youtube.com/playlist?list=$($queryResults.items[$playlist - 1].id.playlistId)"
}

function Download-YoutubeAudio {
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $query,
		[Parameter(Mandatory = $true, Position = 1)]
		[string] $AudioName
	)
	$url = Search-YoutubeVideo $query
	if ($url) {
		Invoke-Expression "youtube-dl $url $aArgs -o '$HOME/Music/$AudioName.%(ext)s'"
	}
}
function Download-YoutubeVideo {
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $query,
		[Parameter(Mandatory = $true, Position = 1)]
		[string] $VideoName
	)
	$url = Search-YoutubeVideo $query
	if ($url) {
		Invoke-Expression "youtube-dl $url $vArgs -o '$HOME/Videos/$VideoName.%(ext)s'"
	}
}
function Download-YoutubeAudioPlaylist {
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $query,
		[Parameter(Mandatory = $true, Position = 1)]
		[string] $PlaylistName
	)
	$url = Search-YoutubePlaylist $query
	if ($url) {
		Invoke-Expression "youtube-dl $url $aArgs -o '$HOME/Music/$PlaylistName/%(title)s.(ext)s'"
	}
}
function Download-YoutubeVideoPlaylist {
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $query,
		[Parameter(Mandatory = $true, Position = 1)]
		[string] $PlaylistName
	)
	$url = Search-YoutubePlaylist $query
	if ($url) {
		Invoke-Expression "youtube-dl $url $vArgs -o '$HOME/Videos/$PlaylistName/%(title)s.%(ext)s'"
	}
}

# Watch youtube videos over command line
function Watch-Youtube {
	while ($true) {
		$search = Read-Host "Search for a video"
		if ($search) {
			$url = $(Search-YoutubeVideo $search)
		}
		if ($url -and $search) {
			mpv $url --no-terminal 2>$null
		}
	}
}

Switch ($option) {
	"i" { Watch-Youtube; Break }
	"a" { Download-YoutubeAudio; Break }
	"v" { Download-YoutubeVideo; Break }
	"ap" { Download-YoutubeAudioPlaylist; Break }
	"vp" { Download-YoutubeVideoPlaylist; Break }
	Default {
		Write-Output "YT -- Authored by Mitch Feigenbaum
Options:
`ti`t`tRun in interactive search mode
`ta`t`tDownload audio from YouTube
`tv`t`tDownload video from YouTube
`tap`t`tDownload an audio playlist from YouTube
`tvp`t`tDownload a video playlist from YouTube
`th`t`tPrint this help message"
		Break
	}
}
