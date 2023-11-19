# Pdf-Cbz-Converter
This is a simple PowerShell script that batch converts .pdf files to .cbz using Ghostscript. 

It was created to remedy the Humble Bundle tendency to release graphic novel and comic bundles as .pdf files only. It is written as simply as possible so that anyone can easily check the file and see that it is safe to use. There are no options other than selecting the files you wish to convert.

## Running the Script

1) You will need to install [Ghostscript](https://ghostscript.com/releases/gsdnld.html) to process the files.

2) Download the `pdf-cbz-converter.ps1` script to a folder on your computer. You will need to 'unblock' it as it is unsigned. To do this, right click on the file, click properties, and then check 'unblock' at the bottom of the menu.

3) Run the following in PowerShell:

```powershell
./PATH_TO_SCRIPT/pdf-cbz-converter.ps1
```
4) A file selection window will appear. Select multiple files using shift.

## Altering the script

If you want to change the quality settings you can alter this line of the script:
```PowerShell
gswin64c.exe -dNOSAFER -dNOPAUSE -sDEVICE=jpeg -r300 -dJPEGQ=90 -sOutputFile="$folderPath\%02d.jpg" "$fileAddress" -dBATCH
```
- `-r300` sets the DPI for the pdf-jpeg conversion to 300. The higher the number the better the quality, but the larger the file size.
- `-dJPEG=90` sets the jpeg compression to 90%. A lower number reduces file size but reduces quality.
I found these settings optimal for my use case, but the file sizes are often as large/larger than the pdf. YMMV.

If there is sufficient interest I can create a Bash/MacOS version too.
