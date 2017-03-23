# This script validates a Sitecore instance against the recommended settings from Sitecore's "config enable/disable Excel spreadsheet" file.
# It only validates the instance and does NOT change any configuration files.
#
# Use the correct CSV file according to the installed Sitecore version:
# $csvFile    = The "Config Enable Disable Excel spreadsheet for Sitecore" saved as CSV *;
#
# * A valid CSV file can be created by downloading the "Config Enable Disable Excel spreadsheet for Sitecore"
#   (e.g. 'https://doc.sitecore.net//~/media/CEEBD3BBE80F4E719387E4F73B76AED2.ashx?la=en' for Sitecore 8.2 Update 2)
#   Open the Excel, remove the first (empty) column and save it as CSV.
#   Open the CSV file with a text-editor (notepad), remove the first empty and "GENERAL CONFIGURATION..." rows,
#   change the header to: "ProductName;FilePath;ConfigFileName;Type;SearchProviderUsed;CD;CM;P;CMP;R" and save the file.
#
# Override one of the following variables to skip the installation questions.
# $rootPath   = The path of the Sitecore folder in which the 'Website' folder is located;
# $serverRole = "CD", "CM", "P", "R" or "CMP";
# $searchType = "Lucene", "Solr" or "Azure";

Function Test-SitecoreConfiguration
{
    Clear-Host;
    $csvFile = $PSScriptRoot + "\Sitecore_8.2_Update2.csv";
    If (!(Test-Path -Path $csvFile))
    {
        Write-Host "The CSV file '$csvFile' is invalid or inaccessible." -ForegroundColor Red;
        exit;
    }

    $rootPath = Get-RootPath;
    $serverRole = Get-ServerRole;
    $searchType = Get-SearchProvider;
    Write-Host;

    Import-Csv -Path $csvFile -Delimiter ";" | ForEach-Object {
        $filePath = $_."FilePath".Trim();
        If (!$filePath.EndsWith("\"))
        {
            $filePath += "\";
        }

        # Config file
        $configFile = $_."ConfigFileName".Trim();
        If ($configFile.EndsWith(".example") -or $configFile.EndsWith(".disabled"))
        {
            $configFile = $configFile.Replace(".example", "").Replace(".disabled", "");
        }

        $configFile = (-join($filePath, $configFile));
        $configFileAndRoot = (-join($rootPath, $configFile));

        # File state (enable, disable, n/a)
        $state = "Disable";

        If ($serverRole -eq "CM") 
        { 
            $state = $_."CM"; 
        }
        ElseIf ($serverRole -eq "CD")
        { 
            $state = $_."CD"; 
        }
        ElseIf ($serverRole -eq "P")
        { 
            $state = $_."P"; 
        }
        ElseIf ($serverRole -eq "R")
        { 
            $state = $_."R"; 
        }
        ElseIf ($serverRole -eq "CMP")
        { 
            $state = $_."CMP"; 
        }

        $searchProvider = $_."SearchProviderUsed";
        If ($searchProvider.Length -gt 0 -and
            $searchProvider -ne "Base" -and
            !$searchProvider.StartsWith($searchType, "CurrentCultureIgnoreCase"))
        {
            If ($configFile -match $searchType)
            {
                $state = "n/a";
            }
            Else
            {
                $state = "Disable";
            }
        }

        If ($state -eq "Enable")
        {
            If (Test-Path -Path $configFileAndRoot)
            {
                Write-PaddedText -text "Should be ENABLED and exist: " -file $configFile -color Green;
            }
            Else
            {
                If (Test-Path -Path (-join($configFileAndRoot, ".disabled")))
                {
                    Write-PaddedText -text "Should be ENABLED but DISABLED exist: " -file $configFile -color Red;
                }
                Else
                {
                    If (Test-Path -Path (-join($configFileAndRoot, ".example")))
                    {
                        Write-PaddedText -text "Should be ENABLED but EXAMPLE exist: " -file $configFile -color Red;
                    }
                    Else
                    {
                        Write-PaddedText -text "Should be ENABLED but does not exist: " -file $configFile -color Red;
                    }
                }
            }
        }
        ElseIf ($state -eq "Disable")
        {
            If (Test-Path -Path $configFileAndRoot)
            {
                Write-PaddedText -text "Should be DISABLED but exist: " -file $configFile -color Red;
            }
            Else
            {
                If (Test-Path -Path (-join($configFileAndRoot, ".disabled")))
                {
                    Write-PaddedText -text "Should be DISABLED and DISABLED exist: " -file $configFile -color Green;
                }
                Else
                {
                    If (Test-Path -Path (-join($configFileAndRoot, ".example")))
                    {
                        Write-PaddedText -text "Should be DISABLED and EXAMPLE exist: " -file $configFile -color Green;
                    }
                    Else
                    {
                        Write-PaddedText -text "Should be DISABLED and does not exist: " -file $configFile -color Green;
                    }
                }
            }
        }
        Else
        {
            If (Test-Path -Path $configFileAndRoot)
            {
                Write-PaddedText -text "Should be N/A and exist: " -file $configFile -color Yellow;
            }
            Else
            {
                If (Test-Path -Path (-join($configFileAndRoot, ".disabled")))
                {
                    Write-PaddedText -text "Should be N/A and DISABLED exist: " -file $configFile -color Yellow;
                }
                Else
                {
                    If (Test-Path -Path (-join($configFileAndRoot, ".example")))
                    {
                        Write-PaddedText -text "Should be N/A and EXAMPLE exist: " -file $configFile -color Yellow;
                    }
                    Else
                    {
                        Write-PaddedText -text "Should be N/A and does not exist: " -file $configFile -color Yellow;
                    }
                }
            }
        }
    }
}

# Writes the text and file to the host
Function Write-PaddedText($text, $file, [System.ConsoleColor] $color)
{
    Write-Host $text.PadRight(40, ' ') $file -ForegroundColor $color;
}

# Gets the Sitecore path
Function Get-RootPath
{
    Write-Host "What is the path of the Sitecore folder in which the 'website' folder is located? " -ForegroundColor Cyan;
    
    do
    {
        $isValid = [bool]::TrueString;
        $rootPath = Read-Host -Prompt "Path";

        If(![string]::IsNullOrEmpty($rootPath))
        {
            If ($rootPath.EndsWith("\"))
            {
                $rootPath = $rootPath.TrimEnd("\");
            }

            If (!(Test-Path -Path $rootPath))
            {
                # The root path does not exists
                Write-Host "The selected folder is invalid or inaccessible." -ForegroundColor Red;
                $isValid = [bool]::FalseString;
            }
            ElseIf (!(Test-Path -Path "$($rootPath)\Website"))
            {
                # The root path does not contain a 'Website' folder
                Write-Host "The selected folder does not contain a 'Website' folder." -ForegroundColor Red;
                $isValid = [bool]::FalseString;
            }
            ElseIf (!(Test-Path -Path "$($rootPath)\Website\App_Config"))
            {
                # The root path does not contain the 'Website\App_Config' folder
                Write-Host "The selected folder does not contain a 'Website\App_Config' folder." -ForegroundColor Red;
                $isValid = [bool]::FalseString;
            }
        }
    }
    until ($isValid -eq [bool]::TrueString)

    return $rootPath;
}

# Gets the server role
Function Get-ServerRole
{
    Write-Host;
    Write-Host "What is the server role: Content Management, Content Delivery, Processing, Reporting or Content Management + Processing ?" -ForegroundColor Cyan;
    Write-Host "Enter 'CD', 'CM', 'P', 'R' or 'CMP'." -ForegroundColor Cyan;

    do
    {
        $serverRole = Read-Host -Prompt "Server role"
    }
    until (($serverRole -eq "CM") -or 
           ($serverRole -eq "CD") -or 
           ($serverRole -eq "P") -or 
           ($serverRole -eq "R") -or 
           ($serverRole -eq "CMP"))

    return $serverRole;
}

# Gets the search provider
Function Get-SearchProvider
{
    Write-Host;
    Write-Host "Which search provider is used Lucene, Solr or Azure?" -ForegroundColor Cyan;
    Write-Host "Enter 'L', 'S' or 'A'." -ForegroundColor Cyan;

    do
    {
        $searchType = Read-Host -Prompt "Search provider"
    }
    until (($searchType -eq "L") -or ($searchType -eq "S") -or ($searchType -eq "A"))

    $type = "Lucene"

    If ($searchType -eq "S")
    {
        $type = "Solr";
    }
    ElseIf ($searchType -eq "A")
    {
        $type = "Azure";
    }

    return $type;
}

Test-SitecoreConfiguration;