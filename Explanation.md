# Bash Script Walkthrough

## High-Level Flow
1) Parse CLI flags and PDF paths.  
2) Ensure `gs` (Ghostscript) and `zip` are available.  
3) For each PDF: validate, prepare an output folder, read per-page colour data, render each page (grayscale or colour), write a README, and optionally package to `.cbz`.  
4) Exit non-zero if any conversion fails.

## Bash Mechanics
- **Shebang**: `#!/usr/bin/env bash` picks Bash from `PATH`, making the script portable.
- **Strict mode**: `set -euo pipefail`
  - `-e`: exit on any command error (helps fail fast).
  - `-u`: error on undefined variables (avoids silent typos).
  - `-o pipefail`: in `cmd1 | cmd2`, fail if either side fails, not just the last command.
- **Variables**: `name=value`; referenced as `$name`. Double quotes (`"$name"`) prevent accidental word splitting and globbing.
- **Parameter expansion** (string slicing):
  - `${var##*.}` gets the extension after the last dot.
  - `${var%.*}` removes the extension.
  - `${var,,}` would lowercase a string (we use `tr` instead for POSIX compatibility).
- **Arrays**: `mapfile -t arr < <(command ...)` reads lines into `arr`; `${#arr[@]}` is length; `${arr[i]}` is element `i`.
- **Functions**: `func() { ...; }`. `local var=value` keeps variables scoped to the function.
- **Conditionals**:
  - Strings/patterns: `[[ "$ext" != "pdf" ]]`, `[[ "$line" == *"CMYK"* ]]`.
  - Integers: `(( idx < total ))`.
  - Files: `[[ -f path ]]` (is a file), `[[ -e path ]]` (exists).
- **Loops**: `for (( i=0; i<n; i++ )); do ...; done` for numeric loops.
- **Exit codes**: `0` means success; non-zero means failure. The script tracks failures per file and exits with the last status.

## CLI Argument Parsing
The loop `while [[ $# -gt 0 ]]; do case "$1" in ... esac; done` walks through arguments:
- `shift` drops the current arg; `shift 2` drops current + its value.
- Flags with values: `-b 600`, `--blackres 600`, `--colourres 400`, `--quality 90`.
- Boolean flags: `-f|--forceblackandwhite`, `-t|--test` toggle integers `1`/`0`.
- `usage()` prints help when `-h|--help` or when no PDFs are given (`$# -lt 1`).

## Dependency Checks
- `command -v gs` and `command -v zip` verify prerequisites before any work starts. If either is missing, the script exits with a clear message.

## Paths and Names
- `dirname "$file"` gives the folder; `basename "$file"` gives the filename.
- `${base%.*}` strips `.pdf` to form the output folder and final archive name.
- Lowercasing an extension: `tr '[:upper:]' '[:lower:]'` makes `.PDF` match `.pdf`.
- `mkdir -p "$output_dir"` creates the temp folder; the script refuses to proceed if it already exists to avoid overwriting work.

## Ghostscript (gs) Calls
Ghostscript does the heavy lifting for both analysis and rendering.
- **Colour analysis**:  
  `gs -q -o - -sDEVICE=inkcov "$file"`  
  - `-q` quiet.  
  - `-o -` writes output to stdout.  
  - `-sDEVICE=inkcov` reports CMYK coverage per page.  
  The script pipes this through `grep "CMYK"` and captures lines into an array with `mapfile`.
- **Rendering pages**: One page at a time to keep memory low. Common flags:  
  - `-dUseCropBox` honors the PDF’s crop box.  
  - `-dNOSAFER` matches the PowerShell script’s security posture.  
  - `-dNOPAUSE -dBATCH` run non-interactively.  
  - `-dFirstPage=N -dLastPage=N` renders a single page.  
  - `-sOutputFile=".../N.png"` or `.../N.jpg` sets the output path.
- **Devices and quality**:
  - Grayscale: `-sDEVICE=pnggray -r"$blackres"` yields lossless grayscale PNG at the chosen DPI.
  - Colour: `-sDEVICE=jpeg -r"$colourres" -dJPEGQ="$quality"` yields JPEGs at the chosen DPI/quality.

## Deciding Colour vs Grayscale
- `only_black_and_white="0.00000"` matches the inkcov string for pure black pages.
- For each page’s inkcov line:
  - If `--forceblackandwhite` is set, page 1 is colour (cover), the rest grayscale.
  - Otherwise, if the line contains `0.00000`, treat as grayscale; else render colour.
- Logs mirror the PowerShell script: they include the raw inkcov line so you can see the coverage values per page.

## Packaging vs Test Mode
- A small README is written into the output folder summarizing settings.
- Normal mode: from the PDF directory, `zip -qr name.zip name` then `mv` to `name.cbz`, and the temp folder is deleted.
- Test mode (`-t|--test`): skips zipping and cleanup so you can open the generated images directly.

## Exit Behaviour
- Each PDF conversion returns success/failure; the overall script exits with a non-zero code if any file fails, which is helpful for automation or CI.

## Reading the Script Top-to-Bottom
1) Constants and defaults (`blackres`, `colourres`, `quality`, `force_black_and_white`, `test_mode`).  
2) `usage()` help text.  
3) Argument parsing sets those variables.  
4) Dependency checks for `gs` and `zip`.  
5) Helper functions: `convert_grayscale`, `convert_colour`.  
6) `convert_pdf` orchestrates per-file work:
   - Validate file and extension.  
   - Derive names and create temp folder.  
   - Run inkcov and stash per-page lines.  
   - Loop pages, choose grayscale vs colour, and render each page.  
   - Write README.  
   - Package (or skip in test mode) and clean up.  
7) Final loop calls `convert_pdf` for each CLI-supplied file and exits with the combined status.

## Quick Usage Examples
```bash
# Default conversion
./pdf-cbz-converter.sh ./book.pdf

# Custom settings with forced B&W interior, and test mode to inspect images
./pdf-cbz-converter.sh -b 600 -c 600 -q 85 -f -t ./book.pdf ./comic.pdf
```
