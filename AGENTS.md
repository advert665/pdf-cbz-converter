# Repository Guidelines

## Project Structure & Module Organization
- `pdf-cbz-converter.ps1`: Primary PowerShell script; handles PDF selection, page colour analysis, conversion, packaging, and cleanup.
- `archive/`: Older tagged versions kept for reference; avoid editing unless backporting fixes.
- `LICENSE`, `README.md`: Legal and usage basics; keep updated when behavior or parameters change.

## Setup, Build, Test, and Development Commands
- Install Ghostscript (required runtime dependency).
- Run default conversion:
  ```powershell
  .\\pdf-cbz-converter.ps1
  ```
- Run with custom settings (overrides DPI/quality/force B&W):
  ```powershell
  .\\pdf-cbz-converter.ps1 -blackres 600 -colourres 600 -quality 90 -forceblackandwhite $True
  ```
- No build pipeline; script should stay portable and side-effect free beyond its working directory.

## Coding Style & Naming Conventions
- Language: PowerShell. Prefer tabs (or 4 spaces) for indentation; keep current layout consistent.
- Functions in PascalCase (`Convert-Grayscale`), parameters and variables in lower camelCase (`$fileAddress`, `$forceblackandwhite`).
- Keep top-level constants near the header; echo user-facing progress via `Write-Output`/`Write-Host`.
- Limit external dependencies; if adding modules, document them in `README.md`.

## Testing Guidelines
- No automated tests yet; rely on manual verification with sample PDFs.
- Smoke test: run the script against a small mixed-colour PDF and confirm output `.cbz`, embedded `readme.txt`, and removal of the temp folder.
- Error paths: verify non-PDF selection and cancelled dialog both report clear errors.
- If adding logic, prefer small helper functions and document manual test steps in PRs.

## Commit & Pull Request Guidelines
- Commits: short, imperative mood (e.g., `Add grayscale fallback`, `Improve dialog error handling`). Group related changes; avoid bundling archive updates with main script edits unless necessary.
- PRs: include summary, parameters or behavior changes, screenshots/log snippets for runs, and manual test notes. Link issues if they exist. Describe any new dependencies or user-visible prompts.

## Security & Configuration Tips
- Script assumes local execution; do not add network calls. Keep Ghostscript invocation explicit and sandbox-friendly (`-dNOSAFER` is present; reassess if adding features that process untrusted input).
- Respect user file locations; avoid destructive operations beyond the temporary working folder created per PDF.
