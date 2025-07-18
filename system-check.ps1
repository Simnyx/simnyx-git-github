# System Check Script - Git and VS Code Verification
# Author: Simnyx
# Description: Checks if Git and VS Code are installed and adds Git to PATH if needed
# Note: Requires Administrator privileges to modify system PATH

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "   Simnyx System Check for Git & VScode Script v1.1" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "⚠ Warning: Not running as Administrator" -ForegroundColor Yellow
    Write-Host "  Some features may not work (like adding Git to PATH)" -ForegroundColor Yellow
}

Write-Host ""

# Function to check if a command exists in PATH
function Test-CommandExists {
    param($CommandName)
    try {
        $command = Get-Command $CommandName -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

# Function to check VS Code installation
function Test-VSCodeInstalled {
    # Check common installation paths
    $vscodePaths = @(
        "${env:LOCALAPPDATA}\Programs\Microsoft VS Code\Code.exe",
        "${env:ProgramFiles}\Microsoft VS Code\Code.exe",
        "${env:ProgramFiles(x86)}\Microsoft VS Code\Code.exe"
    )
    
    foreach ($path in $vscodePaths) {
        if (Test-Path $path) {
            return $path
        }
    }
    
    # Check if 'code' command is available in PATH
    if (Test-CommandExists "code") {
        return "Available in PATH"
    }
    
    return $false
}

# Function to get Git version
function Get-GitVersion {
    try {
        $gitVersion = git --version 2>$null
        return $gitVersion
    }
    catch {
        return $null
    }
}

# Initialize results
$results = @{
    GitInstalled = $false
    GitInPath = $false
    GitVersion = ""
    VSCodeInstalled = $false
    VSCodePath = ""
}

Write-Host "Checking Git installation..." -ForegroundColor Yellow

# Check if Git is installed and in PATH
if (Test-CommandExists "git") {
    $results.GitInstalled = $true
    $results.GitInPath = $true
    $results.GitVersion = Get-GitVersion
    Write-Host "✓ Git is installed and available in PATH" -ForegroundColor Green
    Write-Host "  Version: $($results.GitVersion)" -ForegroundColor Gray
} else {
    Write-Host "✗ Git is not found in PATH" -ForegroundColor Red
    
    # Check if Git is installed but not in PATH
    $gitPaths = @(
        "${env:ProgramFiles}\Git\bin",
        "${env:ProgramFiles(x86)}\Git\bin",
        "${env:LOCALAPPDATA}\Programs\Git\bin"
    )
    
    $foundGitPath = $null
    foreach ($path in $gitPaths) {
        $gitExePath = Join-Path $path "git.exe"
        if (Test-Path $gitExePath) {
            $results.GitInstalled = $true
            $foundGitPath = $path
            Write-Host "  Git found at: $gitExePath" -ForegroundColor Yellow
            Write-Host "  Git is installed but not in PATH" -ForegroundColor Yellow
            break
        }
    }
    
    if ($foundGitPath) {
        Write-Host ""
        Write-Host "Attempting to add Git to system PATH..." -ForegroundColor Yellow
        
        try {
            # Get current system PATH
            $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
            
            # Check if Git path is already in system PATH (case-insensitive)
            if ($currentPath -split ";" | Where-Object { $_.Trim() -eq $foundGitPath }) {
                Write-Host "  Git path already exists in system PATH" -ForegroundColor Yellow
                Write-Host "  You may need to restart your PowerShell session" -ForegroundColor Yellow
            } else {
                # Add Git to system PATH
                $newPath = $currentPath + ";" + $foundGitPath
                [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
                
                # Also update current session PATH
                $env:Path += ";" + $foundGitPath
                
                # Verify the addition worked
                if (Test-CommandExists "git") {
                    $results.GitInPath = $true
                    $results.GitVersion = Get-GitVersion
                    Write-Host "  ✓ Successfully added Git to system PATH" -ForegroundColor Green
                    Write-Host "  Git is now available in current session" -ForegroundColor Green
                    Write-Host "  Version: $($results.GitVersion)" -ForegroundColor Gray
                    Write-Host "  Note: New PATH will be available in new PowerShell sessions" -ForegroundColor Cyan
                } else {
                    Write-Host "  ⚠ Added to PATH but verification failed" -ForegroundColor Yellow
                    Write-Host "  Please restart PowerShell to use Git" -ForegroundColor Yellow
                }
            }
        }
        catch {
            Write-Host "  ✗ Failed to add Git to PATH: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "  This operation requires Administrator privileges" -ForegroundColor Red
            Write-Host "  Please run PowerShell as Administrator and try again" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  Git does not appear to be installed" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Checking VS Code installation..." -ForegroundColor Yellow

# Check VS Code installation
$vscodeResult = Test-VSCodeInstalled
if ($vscodeResult) {
    $results.VSCodeInstalled = $true
    $results.VSCodePath = $vscodeResult
    Write-Host "✓ VS Code is installed" -ForegroundColor Green
    Write-Host "  Location: $($results.VSCodePath)" -ForegroundColor Gray
} else {
    Write-Host "✗ VS Code is not installed" -ForegroundColor Red
}

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "           SUMMARY" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan

# Display summary
Write-Host "Git Status:" -ForegroundColor White
if ($results.GitInstalled -and $results.GitInPath) {
    Write-Host "  ✓ Installed and in PATH" -ForegroundColor Green
} elseif ($results.GitInstalled) {
    Write-Host "  ⚠ Installed but not in PATH" -ForegroundColor Yellow
} else {
    Write-Host "  ✗ Not installed" -ForegroundColor Red
}

Write-Host "VS Code Status:" -ForegroundColor White
if ($results.VSCodeInstalled) {
    Write-Host "  ✓ Installed" -ForegroundColor Green
} else {
    Write-Host "  ✗ Not installed" -ForegroundColor Red
}

Write-Host ""

# Provide recommendations if needed
$needsAction = $false

if (-not $results.GitInstalled) {
    Write-Host "RECOMMENDATION: Install Git from https://git-scm.com/download/win" -ForegroundColor Magenta
    $needsAction = $true
} elseif (-not $results.GitInPath) {
    Write-Host "RECOMMENDATION: Restart PowerShell as Administrator and run this script again to add Git to PATH" -ForegroundColor Magenta
    $needsAction = $true
}

if (-not $results.VSCodeInstalled) {
    Write-Host "RECOMMENDATION: Install VS Code from https://code.visualstudio.com/download" -ForegroundColor Magenta
    $needsAction = $true
}

if (-not $needsAction) {
    Write-Host "🎉 All checks passed! Your system is ready for development." -ForegroundColor Green
}

Write-Host ""
Write-Host "Script completed. Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")