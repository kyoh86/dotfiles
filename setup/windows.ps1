Set-ExecutionPolicy RemoteSigned -scope CurrentUser
iwr -useb get.scoop.sh | iex
scoop install sudo
scoop install win32yank

winget install 7zip.7zip
winget install Discord.Discord
winget install Git.Git
winget install Google.Chrome
winget install Microsoft.WindowsTerminal
winget install JannisX11.Blockbench
winget install SlackTechnologies.Slack
winget install Microsoft.PowerShell
winget install Microsoft.PowerToys
winget install Nota.Gyazo
winget install Google.Drive
winget install Microsoft.VisualStudioCode
winget upgrade --all

# Import .config/WindowsTerminal/settings.json
