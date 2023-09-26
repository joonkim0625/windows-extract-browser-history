<#

This script is written by Hyunjoon (Joon) Kim

Github: https://github.com/joonkim0625
Personal blog: https://joonkim0625.github.io/

#>

param (
    [int]$NumberOfLastVisits  = 20,
    [string]$Browser = "all",
    [switch]$Help    
    )


# Check if the help flag is provided
if ($Help) {
    # Display the help message and exit the script
    Write-Host "Usage: get-history.ps1 [-NumberOfLastVisits <int>] [-Browser <string>] [-Help]"
    Write-Host "Extract browser history from Chrome, Firefox, and Edge."
    Write-Host "    -NumberOfLastfVisits <int> : Number of visits (if not provided, default is 20)"
    Write-Host "    -Browser <string>     : Specify a browser (if not provided, default is 'all')"
    Write-Host "    -Help                 : Show this help message"
    exit
}

# Check if there are enough command-line arguments
if ($args.Count -gt 0) {
    Write-Host "Too many command-line arguments provided."
    Write-Host "Usage: get-history.ps1 [-NumberOfLastVisits <int>] [-Browser <string>] [-Help]"
    exit 1
}

# Information about the username & the user's APPDATA path
#$UserProfile = (Get-ChildItem Env:\USERPROFILE).value

# Extracting username: https://stackoverflow.com/a/44784598
$UserName = query user | Select-String '^>(\w+)' | ForEach-Object { $_.Matches[0].Groups[1].Value }

# $val = query user; $newVal = $val -replace '\s+', ' '; $newVal.split()[10]

$AppDataPath = (Get-ChildItem Env:\LOCALAPPDATA).value

if (-not (Test-Path -Path $AppDataPath)) {
    Write-Host "Coult not find 'LOCALAPPDATA' directory in $UserProfile"
    exit 1
}

# Hard-coded path to the browser history files
$ChromeBrowserPath = "C:\Users\$UserName\AppData\Local\Google\Chrome\User Data\Default\History"
$EdgeBrowserPath = "C:\Users\$UserName\AppData\Local\Microsoft\Edge\User Data\Default\History"
$FirefoxBrowserPath = "C:\Users\$UserName\AppData\Roaming\Mozilla\Firefox\Profiles\*.default-release\places.sqlite"

# Try to get all http & https addresses without sub-directories (so just the domain names)
$regex = '(http|https)://([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)*?'

# =============== Helper functions =================
function Reverse-StringArray {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string[]]
        $ArrayToReverse
    )

    $Reversed = [array]::CreateInstance([string], $ArrayToReverse.Length)

    for ($i = 0; $i -lt $ArrayToReverse.Length; $i++) {
        $Reversed[$i] = $ArrayToReverse[$ArrayToReverse.Length - $i - 1]
    }

    return $Reversed
}
function Remove-Duplicate {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string[]]
        $IPList
    )

    $ReversedList = Reverse-StringArray $IPList

    $UniqueValues = @{}
    $FilteredValue = @()

    foreach ($item in $ReversedList) {
        # This is to correctly remove the duplicates between http(s)://www.somesite.com and http(s)://somesite.com
        $TrimmedAddr = $item -replace "www\.", ""
        if (-not $UniqueValues.ContainsKey($TrimmedAddr)) {
            $UniqueValues[$TrimmedAddr] = $true
            $FilteredValue += $TrimmedAddr
        }
    }

    return $FilteredValue
}
function Get-Chrome-History {

    $ChromeList = Get-Content -Path "$ChromeBrowserPath"|Select-String -AllMatches $regex |% {($_.Matches).Value}

    $Filtered = Remove-Duplicate $ChromeList

    return $Filtered
}
function Get-Edge-History {

    $EdgeList = Get-Content -Path "$EdgeBrowserPath"|Select-String -AllMatches $regex |% {($_.Matches).Value}
    $Filtered = Remove-Duplicate $EdgeList

    return $Filtered
}
function Get-Firefox-History {

    $FirefoxList = Get-Content -Path "$FirefoxBrowserPath"|Select-String -AllMatches $regex |% {($_.Matches).Value}
    $Filtered = Remove-Duplicate $FirefoxList

    return $Filtered
}
function Print-Result {

    # This prints the last X elements from a given list
    [CmdletBinding()]
    param (
        [Parameter()]
        [string[]]
        $IPList,
        [string]
        $BrowserName,
        [int]
        $NumberOfAddresses
    )

    Write-Host -ForegroundColor Green "`nPrinting the last $NumberofAddresses from $BrowserName history file:`n"

    $IPList[1..$NumberOfAddresses]

    Write-Host "`n================================================================"

}

# =============================================

############# MAIN PART ###############

# If $Browser is "all", do something
if ($Browser -eq "all") {

    Write-Host "Getting histories for all browsers..."

    $Browsers = @("Chrome", "Firefox", "Edge")

    # Can have a loop to do this with a list of browser names...
    foreach ($item in $Browsers) {

        $CommandToRun = "Get-$item-History"
        $Result = (Invoke-Expression $CommandToRun)
        Print-Result $Result "$item" $NumberOfLastVisits
       
    }
   
}
else {
    # Invalid browser specified
    if ( $Browser -ne "chrome" -And $Browser -ne "firefox" -And $Browser -ne "edge") {
        Write-Host $Browser
        Write-Host "Invalid browser specified."
        Write-Host "Don't specify any browsers if you want to scan all three. Otherwise, choose one from 'chrome', 'edge', or 'firefox'."
        exit 1
    }

     $CommandToRun = "Get-$Browser-History"
     $Result = (Invoke-Expression $CommandToRun)
     Print-Result $Result "$item" $NumberOfLastVisits
}
