# YT

A YouTube watching script for PowerShell

## Installation

### Prerequisites

Before the installation of the script, there are two required dependencies that need to be installed:

* PowerShell
* YT-DLP

```sh
# Install PowerShell
sudo apt-get update
sudo apt-get install -y wget apt-transport-https software-properties-common
source /etc/os-release
wget -q https://packages.microsoft.com/config/ubuntu/$VERSION_ID/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb
sudo apt-get update
sudo apt-get install -y powershell
# Install yt-dlp
python3 -m pip install -U yt-dlp
```

You will also need a valid [YouTube API key](https://console.developers.google.com/).

### System Install

To install YT to your system, first clone the repository and change into it.

```sh
git clone https://github.com/mrf-dot/yt
cd yt
```

Then, write your YouTube API key into a file called `ytapikey`.

```sh
echo '<Your API key here>' > ytapikey
```

Make the YT program executable.

```sh
cp yt.ps1 yt
chmod +x yt
```

Finally, move all the necessary files into the local bin directory.

```sh
sudo cp youtube-dl yt ytapikey /usr/local/bin/
```

Now, call the program.

```sh
yt
```

## Usage

Listed below are the options for using the program.

```
yt i		Run in interactive search mode
yt a		Download audio from YouTube
yt v		Download video from YouTube
yt ap		Download an audio playlist from YouTube
yt vp		Download a video playlist from YouTube
yt h		Print a help message
```
