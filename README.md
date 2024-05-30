# Pdf-Cbz-Converter 0.4
This is a simple PowerShell script that batch converts .pdf files to .cbz using Ghostscript. 

It was created to remedy the Humble Bundle tendency to release graphic novel and comic bundles as .pdf files only. It is written as simply as possible so that anyone can easily check the file and see that it is safe to use.

## Settings

By default the script converts grayscale pages to 600dpi lossless pngs and colour pages to 400dpi jpegs with 90% compression quality. 

Version 0.4 allows users to pass parameters to the script to override the default quality settings.

The parameters are:

- `-blackres` = sets the DPI for black and white pages (default 600);
- `-colourres` = sets the DPI for colour pages (default 400);
- `-quality` = sets the jpeg compression quality for colour pages (default 90);
- `-forceblackandwhite` = Forces black and white conversion for all but the cover page (default $False).

## Running the Script

1) You will need to install [Ghostscript](https://ghostscript.com/releases/gsdnld.html) to process the files.

2) Download the `pdf-cbz-converter.ps1` script to a folder on your computer.

3) You will need to 'unblock' the script as it is unsigned. To do this, right click on the file, click properties, and then check 'unblock' at the bottom of the menu.

4) Run one of the following in PowerShell:

```powershell
# Default conversion
C:\PATH_TO_SCRIPT\pdf-cbz-converter.ps1

# Choose custom settings
C:\PATH_TO_SCRIPT\pdf-cbz-converter.ps1 -blackres 600 -colourres 600 -quality 90 -forceblackandwhite $False
```
5) A file selection window will appear. Select multiple files using shift or ctrl.

If there is sufficient interest I can create a Bash/MacOS version. Earlier versions of the script are available in the archive folder.
