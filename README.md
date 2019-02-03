README
======

Usage
-----

Presently the following flags are valid

+ `--in`: The directory in which the iTunes Music Library.xml file and iTunes Music directory live.
+ `--out`: The directory to which the playlist files/music will be exported to.
+ `--action`: Either `list` to get a listing of playlists and their corresponding persistent ids, `export` to export to the `out` directory, or `config` to use a config file.
+ `--playlist`: A comma delimited list of playlist persistent ids to be exported.
+ `--type`: The playlist format to be exported (ether PLS or M3U).
+ `--export-protected`: - Export FairPlay DRM encrypted files.
+ `--playlists-only`:   - Generate playlist files without copying music files.
+ `--config`:  Path to config file.
An example usage would be as follows:
```
./tunes_pls.pl --in ~/Music/iTunes/ --action list #To List 
./tunes_pls.pl --in ~/Music/iTunes/ --action export --type pls --out /tmp/ --playlists 6D65D1901B5A9E3B,A212534145F9BE30 #To Export
./tunes_pls.pl --action conf --conf ~/.config/tunes_pls.cfg #To use a config file
```

Config File
-----------

An example config file could be in the ini format as follows:

```cfg
library   = /home/user/Music/iTunes/
format    = m3u
export_to = /tmp/export/
export_protected = true
playlists_only = false

[playlists_by_name]
;Each playlist's name must be encased in single quotes.
;Each playlist must use a unique key value.

playlist_0 = 'Playlist Zero'
playlist_1 = 'Playlist One'  

[playlists_by_id]
;Each playlist must use a unique key and have a valid persistent id.

playlist_0 = 6D65D1901B5A9E3B
```

Todo List / Roadmap
-------------------

+ Json Export Functionality
+ ~~Config file/daemon mode~~ Done
+ Systemd unit files
+ Deb Package
+ GUI
