#!/usr/bin/env python3

import os
import sys
import argparse
import csv
import datetime
import subprocess
from mutagen import File
from mutagen.id3 import ID3, ID3NoHeaderError, TXXX
from mutagen.mp3 import MP3

# Function to check and install pip3
def ensure_pip_installed():
    try:
        # Check if pip is available
        subprocess.check_call([sys.executable, "-m", "pip", "--version"])
    except subprocess.CalledProcessError:
        print("pip is not installed.")
        install_pip = input("Do you want to install pip now? [Y/n] ")
        if install_pip.lower() in ('', 'y', 'yes'):
            try:
                # Attempt to install pip
                if sys.platform.startswith('linux'):
                    # Use package manager to install pip
                    if os.system("which apt-get") == 0:  # Ubuntu/Debian
                        subprocess.check_call(["sudo", "apt", "update"])
                        subprocess.check_call(["sudo", "apt", "install", "-y", "python3-pip"])
                    elif os.system("which yum") == 0:  # CentOS/RedHat
                        subprocess.check_call(["sudo", "yum", "install", "-y", "python3-pip"])
                    elif os.system("which dnf") == 0:  # Fedora
                        subprocess.check_call(["sudo", "dnf", "install", "-y", "python3-pip"])
                    else:
                        print("Unknown package manager. Please install pip manually.")
                        sys.exit(1)
                else:
                    print("Unsupported OS. Please install pip manually.")
                    sys.exit(1)
            except Exception as e:
                print(f"Failed to install pip: {e}")
                sys.exit(1)
        else:
            print("Cannot proceed without pip.")
            sys.exit(1)

# Function to ensure mutagen is installed
def ensure_mutagen_installed():
    try:
        from mutagen.id3 import ID3, TXXX, ID3NoHeaderError
        from mutagen.mp3 import MP3
    except ImportError:
        print("The 'mutagen' module is not installed.")
        install = input("Do you want to install it now? [Y/n] ")
        if install.lower() in ('', 'y', 'yes'):
            try:
                subprocess.check_call([sys.executable, "-m", "pip", "install", "mutagen"])
                from mutagen.id3 import ID3, TXXX, ID3NoHeaderError
                from mutagen.mp3 import MP3
            except Exception as e:
                print(f"Failed to install 'mutagen': {e}")
                sys.exit(1)
        else:
            print("Cannot proceed without 'mutagen'.")
            sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description='Remove certain meta tags from audio files.')
    parser.add_argument('-p', '--path', required=True, help='Path to directory with audio files')
    parser.add_argument('-e', '--extensions', default='mp3,flac,ogg,opus,ape,m4a', help='File extension pattern (comma-separated, default: mp3)')
    parser.add_argument('-r', '--remove-replaygain', action='store_true', help='Remove "replaygain_" tags')
    parser.add_argument('-b', '--backup-metadata', action='store_true', help='Backup metadata to CSV file')
    parser.add_argument('-d', '--dry-run', action='store_true', help='Dry run, just showing what files and tags would be affected')
    args = parser.parse_args()

    extensions = args.extensions.lower().split(',')
    if args.backup_metadata:
        backup_file = 'metadata_backup_{}.csv'.format(datetime.datetime.now().strftime('%Y%m%d%H%M%S'))
        backup_csv = open(backup_file, 'w', newline='', encoding='utf-8')
        csv_writer = csv.writer(backup_csv)
        csv_writer.writerow(['Filename', 'TagID', 'Description', 'Value'])

    for root, dirs, files in os.walk(args.path):
        for file in files:
            if file.lower().endswith(tuple(extensions)):
                filepath = os.path.join(root, file)
                try:
                    # Load the audio file
                    audio = File(filepath, easy=False)
                    if audio is None:
                        print(f"Failed to load audio file: {filepath}. Skipping.")
                        continue

                    tags_to_remove = []
                    # Process tags differently based on file format
                    if file.lower().endswith('.mp3'):
                        # Handle ID3 tags in MP3 files
                        for tag in audio.keys():
                            frame = audio[tag]
                            if isinstance(frame, TXXX):  # Check for ID3v2 TXXX tags
                                desc = frame.desc
                                if desc.startswith('liq_') or (args.remove_replaygain and desc.startswith('replaygain_')):
                                    tags_to_remove.append(tag)
                                    if args.backup_metadata:
                                        csv_writer.writerow([filepath, tag, desc, frame.text[0]])
                            else:
                                if tag.startswith('liq_') or (args.remove_replaygain and tag.startswith('replaygain_')):
                                    tags_to_remove.append(tag)
                                    if args.backup_metadata:
                                        csv_writer.writerow([filepath, tag, '', str(frame)])
                    elif file.lower().endswith(('.flac', '.ogg', '.opus', '.ape')):
                        # Handle Vorbis Comments and APEv2 metadata
                        for tag in audio.keys():
                            if tag.startswith('liq_') or (args.remove_replaygain and tag.startswith('replaygain_')):
                                tags_to_remove.append(tag)
                                if args.backup_metadata:
                                    csv_writer.writerow([filepath, tag, '', str(audio[tag])])
                    elif file.lower().endswith('.m4a'):
                        # Handle MP4 metadata
                        for atom in audio.keys():
                            if atom.startswith('com.liq_') or (args.remove_replaygain and atom.startswith('com.replaygain_')):
                                tags_to_remove.append(atom)
                                if args.backup_metadata:
                                    csv_writer.writerow([filepath, atom, '', str(audio[atom])])
                    else:
                        print(f"Unsupported file format: {file}. Skipping.")
                        continue  # Skip to the next file

                    # Remove tags if any were found
                    if tags_to_remove:
                        print(f"Found tags to remove in {file}: {tags_to_remove}")
                        if args.dry_run:
                            print("Dry run: would remove tags.")
                        else:
                            for tag in tags_to_remove:
                                del audio[tag]
                            audio.save()
                            print(f"Removed tags from {file}")
                    else:
                        print(f"No tags to be removed in {file}")

                except Exception as e:
                    print(f"Error processing {file}: {e}")
                    continue

    if args.backup_metadata:
        backup_csv.close()
        print(f"Metadata backup saved to {backup_file}")


if __name__ == "__main__":
    ensure_pip_installed()
    ensure_mutagen_installed()
    main()
