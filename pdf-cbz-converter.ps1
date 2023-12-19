# pdf-cbz-converter
# Version 0.2
# https://github.com/advert665/pdf-cbz-converter/

# import Windows Forms for file dialogue
Add-Type -AssemblyName System.Windows.Forms

#Constants
$onlyblackandwhite = "0.00000"
$version = "0.2"

# Create OpenFileDialog to select a file
$fileDialog = New-Object System.Windows.Forms.OpenFileDialog
$fileDialog.Title = "Select PDF files to convert to CBZ"
$fileDialog.Multiselect = $true

# Display file dialog and check if the selection was successful
if ($fileDialog.ShowDialog() -eq 'OK') {
    $selectedFiles = $fileDialog.FileNames
    Write-Output "Selected files:"
    foreach ($fileAddress in $selectedFiles) {
        Write-Output $fileAddress

		# Check if the file address is valid
		if (Test-Path -LiteralPath $fileAddress) {
  
			# Check if the file is a PDF
			$fileExtension = [System.IO.Path]::GetExtension($fileAddress) 
			if ($fileExtension -eq ".pdf") {
   
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
				Write-Host("Colour analysis complete.") -ForegroundColor Green

				# Run code based on colour data
				For($page = 0; $page -le $pagescolourinfo.length-1; $page++) {

					# Convert the colour information into a string and store it
					$pagecolour = [string]$pagescolourinfo[$page];

					# Paperpage runs one ahead of pagescolour index
					$paperpage = $page+1; 

					# Test the page colour to see if only black and white
					if($pagecolour.contains($onlyblackandwhite)){

						# Convert to grayscale png @600dpi, lossless
						gswin64c.exe -q -dUseCropBox -dNOSAFER -dNOPAUSE -sDEVICE=pnggray -r600 -dFirstPage="$paperpage" -dLastPage="$paperpage" -sOutputFile="$folderPath\$paperpage.jpg" "$fileAddress" -dBATCH
						Write-Output("Converting page $paperpage`. Colour values: $pagecolour <<<< black and white")
					}
					# Catch all pages that have colour
					else{

						# Convert to jpeg @400dpi, 90% compression
						gswin64c.exe -q -dUseCropBox -dNOSAFER -dNOPAUSE -sDEVICE=jpeg -r400 -dJPEGQ=90 -dFirstPage="$paperpage" -dLastPage="$paperpage" -sOutputFile="$folderPath\$paperpage.jpg" "$fileAddress" -dBATCH
						Write-Output("Converting page $paperpage`. Colour values: $pagecolour <<<< colour")
					}
				}

				# Save version information to readme stored in folder
				$readmepath = Join-Path $folderPath -ChildPath "readme.txt"
				Write-Output("Converted from pdf with pdf-cbz-converter.ps1 $version.`nPowershell script created by advert665, conversion powered by Ghostscript.`nhttps://github.com/advert665/pdf-cbz-converter/") | Out-File -Filepath $readmepath 

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
