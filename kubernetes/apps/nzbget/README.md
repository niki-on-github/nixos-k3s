# [NZBGet](https://github.com/nzbgetcom/nzbget)

NZBGet is a binary downloader, which downloads files from Usenet based on information given in nzb-files.

## Setup

1. Change the default login in Settings -> Security -> ControlUsername and ControlPassword.
2. Then change the umask setting in Settings -> Security -> UMask to `000` and save all changes
3. Apply all changes Reload the configuration with Settings -> System -> Reload

## Embedded Password Extension Script Setup

1. Change Script path in Settings -> Paths -> ScriptDir to `/scripts` and save + reload nzbget
2. Select Script in Settings -> Extension Scripts -> Extensions -> Choose -> `GetPw.py`
