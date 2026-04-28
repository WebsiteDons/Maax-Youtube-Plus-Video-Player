This is a LUA script to manage OBS browser source and add a URL to play embedded videos from Youtube. The script just makes it simple to insert a single video player, create custom playlists or load a Youtube generated list via a remote URL using OBS browser source, without all the ads and page elements on the Youtube page.

Download: [https://github.com/WebsiteDons/Maax-Youtube-Plus-Video-Player/releases/tag/maax-youtube-player](https://github.com/WebsiteDons/Maax-Youtube-Plus-Video-Player/releases/tag/maax-youtube-player)

## Installation
* Extract the .ZIP archive in the OBS installation scripts folder.\
_obs-studio\data\obs-plugins\frontend-tools\scripts (OBS really needs a script installer)_
* Go to OBS menu bar and Tools > Scripts to open the scripts manager
* Add the script by clicking the button with the plus icon
* Select __maax-youtube.lua__
## Usage
* Open Tools > Scripts > maax-youtube.lua (if not already in view)
* Select the scene then select the source.\
_NOTE: If there are no browser sources in any scene, check the box above the scene select field to list all scenes, then choose a scene and later click the button at the bottom labeled Create New Source_
* Configure the settings as desired and add Youtube video URLS
* Click update button when done
## Features
* Create browser sources from the script window
* Edit an existing browser source
* Add multiple Youtube video URL to create custom playlists
* Add Youtube generated playlist ID to play max 200 videos continuously
* Enable autoplay to start the playback once the source is active
* Enable loop to restart a playlist or a single video for eternity
* Enable shuffle for custom playlist
* Embed videos from other platforms including Vimeo, Daily Motion, Odysee, Rumble, Twitch, Kick
## Benefits
* Play Youtube video in an iFrame
* No intrusive page elements from Youtube site
* No ads (a function of Youtube embed API. Not a hack)


__LUA Script UI__
<img width="1031" height="1272" alt="script-interface" src="https://github.com/user-attachments/assets/fdb09a16-20c9-4c5b-b635-69f4554d5e8f" />

__Browser Source Properties View__
<img width="914" height="959" alt="display" src="https://github.com/user-attachments/assets/0a2d65c3-b526-40f9-a124-613e2110246b" />

__Screen View__
<img width="1085" height="604" alt="2026-04-14 18_52_50" src="https://github.com/user-attachments/assets/d47da783-081f-43cc-b891-88bb2d636682" />
