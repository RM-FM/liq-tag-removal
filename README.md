# liq-tag-removal

>[!CAUTION]
>Backup your system / audio files first!

> [!IMPORTANT]
> Please also ensure that you have cleared the Extra Metadata in Azuracast's Media File Manager, as older versions of Azuracast may have stored these values there as well:
>
>`Media > Music Files > set search to show ALL > select ALL > More > Clear Extra Metadata`

### Install script
```
cd /var/azuracast
wget https://raw.githubusercontent.com/RM-FM/liq-tag-removal/main/liq_tag_removal.sh
chmod +x liq_tag_removal.sh
``` 
   
### Start a dry run

Check whether your files have related meta tags set. Replace `{my_station_short_name}` by your station short name (URL Stub).
```
/var/azuracast/liq_tag_removal.sh --dry-run --path /var/lib/docker/volumes/azuracast_station_data/_data/{my_station_short_name}/media`
```

### Parameters

Get a description of all available parameters:
```
/var/azuracast/liq_tag_removal.sh --help
```

```
usage: liq_tag_removal.sh [-h] -p PATH [-e EXTENSIONS] [-r] [-b] [-d]

Remove certain meta tags from audio files.

options:
  -h, --help            show this help message and exit
  -p PATH, --path PATH  Path to directory with audio files
  -e EXTENSIONS, --extensions EXTENSIONS
                        File extension pattern (comma-separated, default: mp3,flac,ogg,opus,m4a,wav,aiff,ape)
  -r, --remove-replaygain
                        Remove "replaygain_" tags
  -b, --backup-metadata
                        Backup metadata to CSV file
  -d, --dry-run         Dry run, just showing what files and tags would be affected
```
