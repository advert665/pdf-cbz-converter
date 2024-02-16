# Pdf-Cbz-Converter 0.2
This is a simple PowerShell script that batch converts .pdf files to .cbz using Ghostscript. 

It was created to remedy the Humble Bundle tendency to release graphic novel and comic bundles as .pdf files only. It is written as simply as possible so that anyone can easily check the file and see that it is safe to use. 

By default the script analyses the colour data of each page and coverts grayscale pages to a 600dpi lossless png and colour pages to 400dpi jpegs. **Version 0.3** of the script adds the ability to force a grayscale conversion for all pages except the cover. To do this pass `bw` as an argument to the script. Previous versions of the script are available in the archive.

## Running the Script

1) You will need to install [Ghostscript](https://ghostscript.com/releases/gsdnld.html) to process the files.

2) Download the `pdf-cbz-converter.ps1` script to a folder on your computer.

3) You will need to 'unblock' the script as it is unsigned. To do this, right click on the file, click properties, and then check 'unblock' at the bottom of the menu.

4) Run one of the following in PowerShell:

```powershell
# Default conversion
./PATH_TO_SCRIPT/pdf-cbz-converter.ps1

# Force grayscale (excluding cover)
./PATH_TO_SCRIPT/pdf-cbz-converter.ps1 bw
```
5) A file selection window will appear. Select multiple files using shift.

## Altering the script

If you want to change the quality settings you can change these lines of the script:
```PowerShell
# Black and White
gswin64c.exe -q -dUseCropBox -dNOSAFER -dNOPAUSE -sDEVICE=pnggray -r600 [...]

# Colour
gswin64c.exe -q -dUseCropBox -dNOSAFER -dNOPAUSE -sDEVICE=jpeg -r400 -dJPEGQ=90 [...]
```
- `-r600` sets the DPI for the pdf-image conversion to 600, `-r400` sets it to 400. The higher the number the better the quality, but the larger the file size.
- `-dJPEG=90` sets the jpeg compression to 90%. A lower number reduces file size but reduces quality.
- png files are lossless, so there is no compression option for the black and white images, but they are much smaller anyway.

I found these settings optimal for my use case, but the file sizes are often as large/larger than the pdf. YMMV.

If there is sufficient interest I can create a Bash/MacOS version too.
