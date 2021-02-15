# NASA's APoD

A simple Flutter App showing [NASA's Astronomy Picture of the Day](https://apod.nasa.gov/apod/) (APOD).

## Features
- Daily Wallpaper Feature (Home and/or Lock Screen)
- Favorites
- Browse Recent APODs
- Seek specific date
- Manual Set Wallpaper

## Known Issues
- Manual Set Wallpaper sometimes not working after enabling the Daily Wallpaper feature
  - Temporary Fix: Restart App
- Daily Wallpaper sets the stretched on landscape mode
  - Possible Fix: Switch width and height if width > height (since most mobile phone's screen is portrait)
  - Possible Problem: If screen is naturally landscape, then the issue will persist (in reverse)
