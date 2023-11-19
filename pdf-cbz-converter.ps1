# pdf-cbz-converter
# https://github.com/advert665/pdf-cbz-converter/

Add-Type -AssemblyName System.Windows.Forms

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

	  			# Run the code with the input and output parameters
	  			gswin64c.exe -dNOSAFER -dNOPAUSE -sDEVICE=jpeg -r300 -dJPEGQ=90 -sOutputFile="$folderPath\%02d.jpg" "$fileAddress" -dBATCH

	  			# Compress the new folder into a zip file
	 			Compress-Archive -Path $folderPath -DestinationPath "$folderPath.zip" -CompressionLevel Optimal -Force

	  			# Change the file extension of the zip file to .cbz
	  			Rename-Item -Path "$folderPath.zip" -NewName "$folderPath.cbz" -Force

	 			#Remove temporary folder
	  			Remove-Item -Path $folderPath -recurse
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
