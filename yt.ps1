#!/bin/env pwsh
param (
	$option
)
# Define your google api key here
$env:GoogleApiKey = "AIzaSyAr9WbWmgDQ4EkMBS4AsWj9ikkKODNZs78"

# Search Youtube and return video url
function Search-YoutubeVideo {
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $query
	)
	$query = [uri]::EscapeDataString($query)
	$searchUri = "https://www.googleapis.com/youtube/v3/search?q=$query&key=$env:GoogleApiKey&maxResults=20&part=snippet&type=video"
	$response = Invoke-RestMethod -Uri $searchUri -Method Get
	# Creates table of result number, video title, and channel
	$tbl = New-Object System.Data.DataTable "Search Results"
	$col0 = New-Object System.Data.DataColumn Result
	$col1 = New-Object System.Data.DataColumn Title
	$col2 = New-Object System.Data.DataColumn Channel
	$tbl.columns.add($col0)
	$tbl.columns.add($col1)
	$tbl.columns.add($col2)
	for ( $i = 1; $i -le $response.items.count; $i++ ) {
		$row = $tbl.NewRow()
		$row.Result = $i
		$row.Title = [System.Net.WebUtility]::HtmlDecode($response.items[$i - 1].snippet.title)
		$row.Channel = [System.Net.WebUtility]::HtmlDecode($response.items[$i - 1].snippet.channeltitle)
		$tbl.rows.add($row)
	}
	$tbl | Format-Table | Out-Host
	# Loops through number until input is correct
	do {
		try {
			$isNum = $true
			$Selection = Read-Host "Selection #"
			if ($Selection) {
				[int]$Selection = $Selection
			}
			else {
				return ""
			}
		}
		catch {
			$isNum = $false
		}
	} until ($Selection -ge 1 -and $Selection -le $response.items.count -and $isNum)
	return "https://youtube.com/watch?v=$($response.items[$selection - 1].id.videoId)"
}

function Search-YoutubePlaylist {
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $query
	)
	$query = [uri]::EscapeDataString($query)
	$searchUri = "https://www.googleapis.com/youtube/v3/search?q=$query&key=$env:GoogleApiKey&maxResults=5&part=snippet&type=playlist"
	$response = Invoke-RestMethod -Uri $searchUri -Method Get
	# Creates table of result number, video title, and channel
	$tbl = New-Object System.Data.DataTable "Search Results"
	$col0 = New-Object System.Data.DataColumn Result
	$col1 = New-Object System.Data.DataColumn Title
	$tbl.columns.add($col0)
	$tbl.columns.add($col1)
	for ( $i = 1; $i -le $response.items.count; $i++ ) {
		$row = $tbl.NewRow()
		$row.Result = $i
		$row.Title = [System.Net.WebUtility]::HtmlDecode($response.items[$i - 1].snippet.title)
		$tbl.rows.add($row)
	}
	$tbl | Format-Table | Out-Host
	# Loops through number until input is correct
	do {
		try {
			$isNum = $true
			$Selection = Read-Host "Selection #"
			if ($Selection) {
				[int]$Selection = $Selection
			}
			else {
				return ""
			}
		}
		catch {
			$isNum = $false
		}
	} until ($Selection -ge 1 -and $Selection -le $response.items.count -and $isNum)
	return "https://youtube.com/playlist?list=$($response.items[$selection - 1].id.playlistId)"
}

function Download-YoutubeAudio {
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $query
	)
	youtube-dl $(Search-YoutubeVideo $query) --restrict-filenames -x --audio-format mp3 -o "$HOME/Music/%(title)s.(ext)s"
}
function Download-YoutubeVideo {
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $query
	)
	youtube-dl $(Search-YoutubeVideo $query) --restrict-filenames -f "bestvideo[ext=mp4][height<=?1080][fps<=?30]+bestaudio[ext=m4a]/best[ext=mp4]/best" -o "$HOME/Videos/%(title)s.%(ext)s"

}
function Download-YoutubeAudioPlaylist {
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $query,
		[Parameter(Mandatory = $true, Position = 1)]
		[string] $PlaylistName
	)
	youtube-dl $(Search-YoutubePlaylist $query) --restrict-filenames -x --audio-format mp3 -o "$HOME/Music/$PlaylistName/%(title)s.(ext)s"
}
function Download-YoutubeVideoPlaylist {
	param (
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $query,
		[Parameter(Mandatory = $true, Position = 1)]
		[string] $PlaylistName
	)
	youtube-dl $(Search-YoutubePlaylist $query) --restrict-filenames -f "bv[ext=mp4][height<=?1080][fps<=?30]+bestaudio[ext=m4a]/best[ext=mp4]/best" -o "$HOME/Videos/$PlaylistName/%(title)s.%(ext)s"
}

# Watch youtube videos over command line
function Watch-Youtube {
	while ($true) {
		$search = Read-Host "Search for a video"
		if ($search) {
			$url = $(Search-YoutubeVideo $search)
		}
		if ($url) {
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
		echo "YT -- Authored by Mitch Feigenbaum
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
