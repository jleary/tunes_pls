README
======

Usage
-----

Presently the following flags are valid

+ `--in`: The directory in which the iTunes Music Library.xml file and iTunes Music directory live.
+ `--out`: The directory to which the playlist files/music will be exported to.
+ `--action`: Either `list` to get a listing of playlists and their corresponding persistent ids or `export` to export to the `out` directory.
+ `--playlist`: A comma delimited list of playlist persistent ids to be exported.
+ `--type`: The playlist format to be exported (ether PLS or M3U).
+ `--export_protected`: Either "Yes" or "True" to export FairPlay DRM encrypted files or anything else to not export them
+ `--config`:  Path to config file
An example usage would be as follows:
```
./tunes_pls.pl --in ~/Music/iTunes/ --action list #To List 
./tunes_pls.pl --in ~/Music/iTunes/ --action export --type pls --out /tmp/ --playlists 6D65D1901B5A9E3B,A212534145F9BE30 #To Export
./tunes_pls.pl --action conf --conf ~/.config/tunes_pls.cfg #To use a config file
```

Config File
-----------

An example config file could be in the ini format as follows:
```
library   = /home/user/Music/iTunes/
format    = m3u
export_to = /tmp/export/
export_protected = true

[playlists_by_name]
playlist_0 = 'Playlist Zero' ;Each playlist's name must be encased in single quotes
playlist_1 = 'Playlist One'  ;Each playlist must use a unique key value

[playlists_by_id]
playlist_0 = 6D65D1901B5A9E3B
```

Todo List / Roadmap
-------------------

+ Json Export Functionality
+ ~~Config file/daemon mode~~ Done
+ Systemd unit files
+ Deb Package
+ GUI
