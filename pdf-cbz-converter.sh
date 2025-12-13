#!/usr/bin/env bash
set -euo pipefail

version="0.5"
only_black_and_white="0.00000"
blackres=600
colourres=400
quality=90
force_black_and_white=0
test_mode=0

usage() {
	cat <<'EOF'
Usage: ./pdf-cbz-converter.sh [options] file1.pdf [file2.pdf ...]

Options:
  -b, --blackres INT           DPI for grayscale pages (default 600)
  -c, --colourres INT          DPI for colour pages (default 400)
  -q, --quality INT            JPEG quality for colour pages (default 90)
  -f, --forceblackandwhite     Force B&W for all pages except the cover
  -t, --test                   Skip CBZ packaging; leave image folder for inspection
  -h, --help                   Show this help message
EOF
}

# Parse CLI arguments for settings and gather file list
while [[ $# -gt 0 ]]; do
	case "$1" in
		-b|--blackres)
			[[ $# -ge 2 ]] || { echo "Missing value for $1" >&2; usage; exit 1; }
			blackres="$2"
			shift 2
			;;
		-c|--colourres|--colorres)
			[[ $# -ge 2 ]] || { echo "Missing value for $1" >&2; usage; exit 1; }
			colourres="$2"
			shift 2
			;;
		-q|--quality)
			[[ $# -ge 2 ]] || { echo "Missing value for $1" >&2; usage; exit 1; }
			quality="$2"
			shift 2
			;;
		-f|--forceblackandwhite)
			force_black_and_white=1
			shift
			;;
		-t|--test)
			test_mode=1
			shift
			;;
		-h|--help)
			usage
			exit 0
			;;
		--)
			shift
			break
			;;
		-*)
			echo "Unknown option: $1" >&2
			usage
			exit 1
			;;
		*)
			break
			;;
	esac
done

# Require at least one PDF argument
if [[ $# -lt 1 ]]; then
	usage
	exit 1
fi

# Verify required tools are available
command -v gs >/dev/null 2>&1 || { echo "Ghostscript (gs) is required but not installed." >&2; exit 1; }
command -v zip >/dev/null 2>&1 || { echo "zip is required to package the CBZ output." >&2; exit 1; }

# Convert a single page to grayscale PNG
convert_grayscale() {
	local file="$1"
	local page="$2"
	local output_dir="$3"
	local page_colour="$4"

	gs -q -dUseCropBox -dNOSAFER -dNOPAUSE -dBATCH -sDEVICE=pnggray -r"$blackres" -dFirstPage="$page" -dLastPage="$page" -sOutputFile="$output_dir/${page}.png" "$file"
	echo "Page $page -> grayscale (${blackres} DPI). Colour values: ${page_colour} <<<< black and white"
}

# Convert a single page to colour JPEG
convert_colour() {
	local file="$1"
	local page="$2"
	local output_dir="$3"
	local page_colour="$4"

	gs -q -dUseCropBox -dNOSAFER -dNOPAUSE -dBATCH -sDEVICE=jpeg -r"$colourres" -dJPEGQ="$quality" -dFirstPage="$page" -dLastPage="$page" -sOutputFile="$output_dir/${page}.jpg" "$file"
	echo "Page $page -> colour (${colourres} DPI, quality ${quality}%). Colour values: ${page_colour} <<<< colour"
}

# Convert an entire PDF to CBZ
convert_pdf() {
	local file="$1"

	if [[ ! -f "$file" ]]; then
		echo "Skipping: $file (file not found)" >&2
		return 1
	fi

	local ext="${file##*.}"
	local lower_ext
	lower_ext=$(printf '%s' "$ext" | tr '[:upper:]' '[:lower:]')
	if [[ "$lower_ext" != "pdf" ]]; then
		echo "Skipping: $file (not a PDF)" >&2
		return 1
	fi

	local dir base name output_dir
	dir=$(dirname "$file")
	base=$(basename "$file")
	name="${base%.*}"
	output_dir="$dir/$name"

	if [[ -e "$output_dir" ]]; then
		echo "Skipping: $file (output folder already exists: $output_dir)" >&2
		return 1
	fi
	mkdir -p "$output_dir"

	echo "Conversion settings: Black and white png = ${blackres} DPI; Colour jpeg: ${colourres} DPI; Quality: ${quality}%; Force B&W: ${force_black_and_white}"
	echo "Analysing page colour data for $file..."

	local -a pages_colour_info=()
	mapfile -t pages_colour_info < <(gs -q -o - -sDEVICE=inkcov "$file" | grep "CMYK" || true)
	local total_pages=${#pages_colour_info[@]}

	if (( total_pages == 0 )); then
		echo "Failed to read page colour data for $file" >&2
		rmdir "$output_dir"
		return 1
	fi

	echo "Colour analysis complete."

	# Process pages based on colour data (or forced mode)
	local idx page page_colour
	for (( idx=0; idx<total_pages; idx++ )); do
		page=$((idx + 1))
		page_colour="${pages_colour_info[$idx]}"

		if (( force_black_and_white )); then
			if (( page == 1 )); then
				convert_colour "$file" "$page" "$output_dir" "$page_colour"
			else
				convert_grayscale "$file" "$page" "$output_dir" "$page_colour"
			fi
		else
			if [[ "$page_colour" == *"$only_black_and_white"* ]]; then
				convert_grayscale "$file" "$page" "$output_dir" "$page_colour"
			else
				convert_colour "$file" "$page" "$output_dir" "$page_colour"
			fi
		fi
	done

	# Record conversion details for reference
	cat > "$output_dir/readme.txt" <<EOF
Converted from pdf with pdf-cbz-converter ${version}.
Grayscale ${blackres} DPI png; Colour ${colourres} DPI ${quality}% jpeg.
Bash script created by advert665, conversion powered by Ghostscript.
https://github.com/advert665/pdf-cbz-converter/
EOF

	# Package folder as CBZ and clean up temp files (unless in test mode)
	if (( test_mode )); then
		echo "Test mode enabled: leaving images in $output_dir (no CBZ created)."
	else
		(
			cd "$dir"
			zip -qr "$name.zip" "$name"
			mv -f "$name.zip" "$name.cbz"
		)

		echo "Removing temporary folder..."
		rm -rf "$output_dir"
		echo "Conversion of $file to .cbz complete!"
	fi
}

status=0
for file in "$@"; do
	if ! convert_pdf "$file"; then
		status=1
	fi
done

exit "$status"
