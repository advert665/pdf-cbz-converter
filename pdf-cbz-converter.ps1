# pdf-cbz-converter
# Version 0.4
# https://github.com/advert665/pdf-cbz-converter/

#Define parameters (must be first line of script)
param([int]$blackres = 600, [int]$colourres = 400, [int]$quality = 90, [bool]$forceblackandwhite = $False)

# import Windows Forms for file dialogue
Add-Type -AssemblyName System.Windows.Forms

#Constants
$onlyblackandwhite = "0.00000"
$version = "0.4"

#Functions
function Convert-Grayscale {
	# Convert to grayscale png @600dpi, lossless
	gswin64c.exe -q -dUseCropBox -dNOSAFER -dNOPAUSE -sDEVICE=pnggray -r"$blackres" -dFirstPage="$paperpage" -dLastPage="$paperpage" -sOutputFile="$folderPath\$paperpage.png" "$fileAddress" -dBATCH
	Write-Output("Converting page $paperpage`. Colour values: $pagecolour <<<< black and white")
}

function Convert-Colour {
	# Convert to jpeg @400dpi, 90% quality compression
	gswin64c.exe -q -dUseCropBox -dNOSAFER -dNOPAUSE -sDEVICE=jpeg -r"$colourres" -dJPEGQ="$quality" -dFirstPage="$paperpage" -dLastPage="$paperpage" -sOutputFile="$folderPath\$paperpage.jpg" "$fileAddress" -dBATCH
	Write-Output("Converting page $paperpage`. Colour values: $pagecolour <<<< colour")
}

# Create OpenFileDialog to select a file
$fileDialog = New-Object System.Windows.Forms.OpenFileDialog
$fileDialog.Title = "Select PDF files to convert to CBZ"
$fileDialog.Multiselect = $true

# Display file dialog and check if the selection was successful
if ($fileDialog.ShowDialog() -eq 'OK') {
    $selectedFiles = $fileDialog.FileNames

	#Print conversion settings
	Write-Output "Conversion settings: Black and white png = $blackres DPI; Colour jpeg: $colourres DPI; Quality: $quality`%; Force B&W: $forceblackandwhite"

    foreach ($fileAddress in $selectedFiles) {

		# Check if the file address is valid
		if (Test-Path -LiteralPath $fileAddress) {
  
			# Check if the file is a PDF
			$fileExtension = [System.IO.Path]::GetExtension($fileAddress) 
			if ($fileExtension -eq ".pdf") {
				Write-Output "Converting: $fileAddress"

				#Check for arguments
				if ($forceblackandwhite -eq $True){
					Write-Host "Forcing black and white conversion for all pages except cover."
				}

	  			# Get the file name without the extension
	  			$fileName = [System.IO.Path]::GetFileNameWithoutExtension($fileAddress)

	  			# Get the directory path of the file
	  			$dirPath = Split-Path $fileAddress

	  			# Create a temporary folder with the same name as the file
	  			$folder = New-Item -Path $dirPath -Name $fileName -Type Directory

	  			# Get the full path of the new folder
	  			$folderPath = $folder.FullName

				# Get colour info from each of the pages using ghostscript's inkcov
				Write-Output("Analysing page colour data for $filename...")
				$pagescolourinfo = gswin64c.exe  -o - -sDEVICE=inkcov "$fileAddress" | select-string -Pattern "CMYK"
				Write-Host("Colour analysis complete.")

				if ($forceblackandwhite -eq 'bw'){

					# Convert all pages except cover to grayscale
					For($page = 0; $page -le $pagescolourinfo.length-1; $page++) {
						
						# Convert the colour information into a string and store it
						$pagecolour = [string]$pagescolourinfo[$page];

						# Paperpage runs one ahead of pagescolour index
						$paperpage = $page+1; 

						# Cover page
						if($page -eq 0){
							Convert-Colour
						}
						# All other pages
						else{
							Convert-Grayscale
						}
					}
				} else {

					# Run code based on colour data
					For($page = 0; $page -le $pagescolourinfo.length-1; $page++) {

						# Convert the colour information into a string and store it
						$pagecolour = [string]$pagescolourinfo[$page];

						# Paperpage runs one ahead of pagescolour index
						$paperpage = $page+1; 

						# Test the page colour to see if only black and white
						if($pagecolour.contains($onlyblackandwhite)){
							Convert-Grayscale
						}
						# Catch all pages that have colour
						else{
							Convert-Colour
						}
					}
				}

				# Save version information to readme stored in folder
				$readmepath = Join-Path $folderPath -ChildPath "readme.txt"
				Write-Output("Converted from pdf with pdf-cbz-converter $version.`nBlack and white $blackres DPI png; Colour $colourres DPI $quality`% quality jpeg.`nPowershell script created by advert665, conversion powered by Ghostscript.`nhttps://github.com/advert665/pdf-cbz-converter/") | Out-File -Filepath $readmepath 

	  			# Compress the new folder into a zip file
	 			Compress-Archive -Path $folderPath -DestinationPath "$folderPath.zip" -CompressionLevel Optimal -Force

	  			# Change the file extension of the zip file to .cbz
	  			Rename-Item -Path "$folderPath.zip" -NewName "$folderPath.cbz" -Force

	 			#Remove temporary folder
				Write-Output("Removing temporary folder...")
	  			Remove-Item -Path $folderPath -recurse

				#Success message
				Write-Host("Conversion of $filename to .cbz complete!") -ForegroundColor Green
			}
			else {
				# Display an error message
	  			Write-Error "File not PDF. This tool only works with PDF files."
			}
		}
		else {
	 		# Display an error message
	  		Write-Error "Invalid file address."
	  	}
	}
}
else {
	Write-Error "No file selected."
	exit
}
