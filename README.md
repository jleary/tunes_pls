# README

Presently the following flags are valid

+ `--in`: The directory in which the iTunes Music Library.xml file and iTunes Music directory live.
+ `--out`: The directory to which the playlist files/music will be exported to.
+ `--action`: Either `list` to get a listing of playlists and their corresponding persistent ids or `export` to export to the `out` directory.
+ `--playlist`: A comma delimited list of playlist persistent ids to be exported.
+ `--type`: The playlist format to be exported (ether PLS or M3U).
+ `--export_protected`: Either "Yes" or "True" to export FairPlay DRM encrypted files or anything else to not export them

An example usage would be as follows:
```
./tunes_pls.pl --in ~/Music/iTunes/ --action list #To List 
./tunes_pls.pl --in ~/Music/iTunes/ --action export --type pls --out /tmp/ --playlists 6D65D1901B5A9E3B,A212534145F9BE30 #To Export
```


