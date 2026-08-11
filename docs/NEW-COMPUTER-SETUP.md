# New Computer Setup Guide

Use this guide when you need to rebuild this workspace from scratch on a new computer.
It is written so a developer, you, or a VS Code agent can follow it step by step.

## 0. Baseline IDs and versions used by this workspace

Use these as known-good reference values when rebuilding.

- VS Code package ID: `Microsoft.VisualStudioCode`
- VS Code app version currently in this workspace: `1.132.0`
- Git package ID: `Git.Git`
- Git target package version: `2.55.0.3`
- Node.js LTS package ID: `OpenJS.NodeJS.LTS`
- Node.js LTS target package version: `24.19.0`
- Pandoc package ID: `JohnMacFarlane.Pandoc`
- Pandoc target package version: `3.10.1`
- VS Code extensions and baseline versions:
- `davidanson.vscode-markdownlint@0.62.1`
- `redhat.vscode-yaml@1.24.0`
- `esbenp.prettier-vscode@12.4.0`
- `streetsidesoftware.code-spell-checker@4.5.6`

## 0.1 Find latest IDs and versions when needed

Run these commands before installation if you want the newest available packages:

```powershell
winget show --id Microsoft.VisualStudioCode -e
winget show --id Git.Git -e
winget show --id OpenJS.NodeJS.LTS -e
winget show --id JohnMacFarlane.Pandoc -e
```

Find extension details in the VS Code Marketplace:

- [Markdown Lint](https://marketplace.visualstudio.com/items?itemName=davidanson.vscode-markdownlint)
- [YAML](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml)
- [Prettier](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode)
- [Code Spell Checker](https://marketplace.visualstudio.com/items?itemName=streetsidesoftware.code-spell-checker)

## 1. Install the required software

### Install Visual Studio Code

Use this exact pinned install command for the baseline package version:

```powershell
winget install --id Microsoft.VisualStudioCode -e --version 1.130.0
```

If you prefer latest available from winget:

```powershell
winget install --id Microsoft.VisualStudioCode -e
```

After installation, open VS Code and sign in if you want to sync settings.

### Install Git

Pinned example:

```powershell
winget install --id Git.Git -e --version 2.55.0.3
```

Latest available example:

```powershell
winget install --id Git.Git -e
```

### Install Node.js and npm

Pinned example:

```powershell
winget install --id OpenJS.NodeJS.LTS -e --version 24.19.0
```

Latest available LTS example:

```powershell
winget install --id OpenJS.NodeJS.LTS -e
```

Verify it works:

```powershell
node --version
npm --version
```

### Install Pandoc

This repo uses Pandoc for DOCX generation.

Pinned example:

```powershell
winget install --id JohnMacFarlane.Pandoc -e --version 3.10.1
```

Latest available example:

```powershell
winget install --id JohnMacFarlane.Pandoc -e
```

Verify it works:

```powershell
pandoc --version
```

### Install PowerShell (if needed)

Windows usually already has PowerShell installed.
If it is missing, install it with:

```powershell
winget install --id Microsoft.PowerShell -e
```

## 2. Clone the repository

Open a terminal and run:

```powershell
git clone <your-repo-url> taa-syllabi
cd taa-syllabi
```

If you already have the repo locally, use:

```powershell
cd <your-folder>
git pull
```

## 3. Open the workspace

Open the folder in VS Code.
The easiest option is to open the workspace file:

- [taa-syllabi.code-workspace](../taa-syllabi.code-workspace)

If that file is not available, open the repository folder directly.

## 4. Install the recommended VS Code extensions

The repository already contains recommended extensions in [.vscode/extensions.json](../.vscode/extensions.json).

In VS Code, open the Extensions panel and install these:

- Markdown Lint
- YAML
- Prettier
- Code Spell Checker

If the recommendations do not appear automatically, install them manually by name.

Or install by exact extension IDs:

```powershell
code --install-extension davidanson.vscode-markdownlint --force
code --install-extension redhat.vscode-yaml --force
code --install-extension esbenp.prettier-vscode --force
code --install-extension streetsidesoftware.code-spell-checker --force
```

Verify installed extension versions:

```powershell
code --list-extensions --show-versions
```

## 5. Install Node dependencies for linting

From the repository root, run:

```powershell
npm install
```

This installs the markdown and YAML lint tools used by the project.

Exact dependency versions used by this repo are:

- `markdownlint-cli2@^0.14.0`
- `prettier@^3.3.3`

If you need to enforce those exact major/minor values explicitly:

```powershell
npm install --save-dev markdownlint-cli2@0.14.0 prettier@3.3.3
```

## 6. Make PowerShell script execution work for local rendering

The renderer script is PowerShell-based. To avoid execution policy issues in a terminal session, use:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

The project tasks already call the renderer with `-ExecutionPolicy Bypass`, so this is mainly for manual runs.

## 7. Verify the renderer

Run the full generation task from the repository root:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\render-syllabi.ps1 -All
```

Or use the VS Code task named:

- Generate all syllabi

You should see outputs written to:

- [syllabi/output/github-markdown](../syllabi/output/github-markdown)
- [syllabi/output/word-friendly-markdown](../syllabi/output/word-friendly-markdown)
- [syllabi/output/facts-plain-text](../syllabi/output/facts-plain-text)

## 8. Verify linting

Run:

```powershell
npm run lint
```

If you want to auto-format files:

```powershell
npm run format
```

Check tool versions as a final verification step:

```powershell
code --version
git --version
node --version
npm --version
pandoc --version
```

## 9. Confirm the workspace is ready

A fresh setup is considered complete when all of the following are true:

- VS Code opens the repo successfully.
- Recommended extensions are installed.
- `npm install` finishes without errors.
- `pandoc --version` works.
- The renderer completes and writes new syllabi outputs.
- The repository shows generated files in the output folders.

## 10. Common troubleshooting

### PowerShell profile warning

This can happen when your PowerShell profile is blocked by policy.
It does not usually stop rendering. The project tasks already bypass it.

### Pandoc not found

If Pandoc is installed but not found, restart VS Code and the terminal. If needed, add the installation path to your PATH.

### Extension warnings

If the recommended extensions are not loaded, restart VS Code or reinstall them.
