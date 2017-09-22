<#Powershell Script to automate installation of Smartstream 8
  Author: Dondre Trotman
  Date: 2017-08-28
  Version: 2.2 
  PLEASE RUN AS ADMINISTRATOR OR EXECUTION WILL FAIL!
  There are a few ways to run this script
  1. Run Setup.bat as administrator
  2. Type "set-executionpolicy bypass" Without quotes in powershell to allow script execution. Then run the script
  3. Log in as Administrator, Right click Install-SmartstreamV1.ps1 and select "Run with PowerShell. Type "y" and enter.

  Changelog
  Version 2.2 (2017-09-22)
  * changed file paths from hardcoded to variables
  TODO: Change server aliases and ip addresses from hardcoded to variables

  Version 2.1 (2017-09-20)
  * Small change to install correct bit version of SQL Native Client
  * used \\statserver.gov.bb\FINPROD everywhere since I can't guarrantee that Q: will always be mapped under the particular account
  * Check host file to determine if it has been configured already

  Version 2.0 (2017-09-14)
  * Major code rewrites to fix a lot of errors
  * Corrected registry key creation in Step 6
  * Set PBACC125.DLL to copy automatically
  * Added Write-log function that defaults to current user's directory
  * Prevented powershell window from closing at the end
#>

#set variables
$osbit = 32
$username = [environment]::UserName
$x86 = "HKLM:\Software\Microsoft\MSSQLServer\Client\ConnectTo"
$x64 = "HKLM:\Software\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo"
$log = ""
$path = "statserver.gov.bb"
$share = "FINPROD"
$map = "Q"


#Preliminary checks
#check for 64bit OS
if([environment]::Is64BitOperatingSystem)
{
	$osbit = 64
}
else
{
	$osbit = 32
}
$log = Write-Output "Computer running $osbit bit OS..."
#FUNCTIONS
<# 
.Synopsis 
   Write-Log writes a message to a specified log file with the current time stamp. 
.DESCRIPTION 
   The Write-Log function is designed to add logging capability to other scripts. 
   In addition to writing output and/or verbose you can write to a log file for 
   later debugging. 
.NOTES 
   Created by: Jason Wasser @wasserja 
   Modified: 11/24/2015 09:30:19 AM   
 
   Changelog: 
    * Code simplification and clarification - thanks to @juneb_get_help 
    * Added documentation. 
    * Renamed LogPath parameter to Path to keep it standard - thanks to @JeffHicks 
    * Revised the Force switch to work as it should - thanks to @JeffHicks 
 
   To Do: 
    * Add error handling if trying to create a log file in a inaccessible location. 
    * Add ability to write $Message to $Verbose or $Error pipelines to eliminate 
      duplicates. 
.PARAMETER Message 
   Message is the content that you wish to add to the log file.  
.PARAMETER Path 
   The path to the log file to which you would like to write. By default the function will  
   create the path and file if it does not exist.  
.PARAMETER Level 
   Specify the criticality of the log information being written to the log (i.e. Error, Warning, Informational) 
.PARAMETER NoClobber 
   Use NoClobber if you do not wish to overwrite an existing file. 
.EXAMPLE 
   Write-Log -Message 'Log message'  
   Writes the message to c:\Logs\PowerShellLog.log. 
.EXAMPLE 
   Write-Log -Message 'Restarting Server.' -Path c:\Logs\Scriptoutput.log 
   Writes the content to the specified log file and creates the path and file specified.  
.EXAMPLE 
   Write-Log -Message 'Folder does not exist.' -Path c:\Logs\Script.log -Level Error 
   Writes the message to the specified log file as an error message, and writes the message to the error pipeline. 
.LINK 
   https://gallery.technet.microsoft.com/scriptcenter/Write-Log-PowerShell-999c32d0 
#> 
function Write-Log 
{ 
    [CmdletBinding()] 
    Param 
    ( 
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true)] 
        [ValidateNotNullOrEmpty()] 
        [Alias("LogContent")] 
        [string]$Message, 
 
        [Parameter(Mandatory=$false)] 
        [Alias('LogPath')] 
        [string]$Path="C:\Logs\SmartstreamInstall\SmartsreamLog.log", 
         
        [Parameter(Mandatory=$false)] 
        [ValidateSet("Error","Warn","Info")] 
        [string]$Level="Info", 
         
        [Parameter(Mandatory=$false)] 
        [switch]$NoClobber 
    ) 
 
    Begin 
    { 
        # Set VerbosePreference to Continue so that verbose messages are displayed. 
        $VerbosePreference = 'Continue' 
    } 
    Process 
    { 
         
        # If the file already exists and NoClobber was specified, do not write to the log. 
        if ((Test-Path $Path) -AND $NoClobber) { 
            Write-Error "Log file $Path already exists, and you specified NoClobber. Either delete the file or specify a different name." 
            Return 
            } 
 
        # If attempting to write to a log file in a folder/path that doesn't exist create the file including the path. 
        elseif (!(Test-Path $Path)) { 
            Write-Verbose "Creating $Path." 
            $NewLogFile = New-Item $Path -Force -ItemType File 
            } 
 
        else { 
            # Nothing to see here yet. 
            } 
 
        # Format Date for our Log File 
        $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss" 
 
        # Write message to error, warning, or verbose pipeline and specify $LevelText 
        switch ($Level) { 
            'Error' { 
                Write-Error $Message 
                $LevelText = 'ERROR:' 
                } 
            'Warn' { 
                Write-Warning $Message 
                $LevelText = 'WARNING:' 
                } 
            'Info' { 
                Write-Verbose $Message 
                $LevelText = 'INFO:' 
                } 
            } 
         
        # Write log entry to $Path 
        "$FormattedDate $LevelText $Message" | Out-File -FilePath $Path -Append 
    } 
    End 
    { 
    } 
}
Write-Log -Message "Start script"
Write-Log -Message $log

Write-Output "***Step 1: Map \\$domain\$share to $map***" | Write-Log
#If Q: already exists (as it should) then we can skip this
if(!(Test-Path Q:))
{
	New-PSDrive -Name "$map" -PSProvider FileSystem -Root "\\$domain\$share" -Persist
	Write-Output "Drive $map mapped successfully..." | Write-Log
}
Else
{
	Write-Output "Drive already mapped..." | Write-Log
}

Write-Output "***Step 2: Install  SQL Native Client 2008***" | Write-Log
if($osbit -eq 32)
{
	msiexec /qb /i "\\$domain\$share\SQL Native Client for 2008\sqlncli_X32.msi" /log C:\Logs\SmartstreamInstall\sqlnclog.txt IACCEPTSQLNCLILICENSETERMS=YES
	Write-Output "32bit SQL Native Client installed..." | Write-Log
}
if($osbit -eq 64)
{	
	msiexec /qb /i "\\$domain\$share\SQL Native Client for 2008\sqlncli_X64.msi" /log C:\Logs\SmartstreamInstall\sqlnclog.txt IACCEPTSQLNCLILICENSETERMS=YES
	Write-Output "64bit SQL Native Client installed..." | Write-Log
}

Write-Output "***Step 3: Edit Host file***" | Write-Log
$config = Get-Content "C:\Windows\System32\drivers\etc\hosts"
$search = $config | Select-String "gob0003"
$result = "*gob0003*"
if($search -like $result)
{
    Write-Output "Host file already configured" | Write-Log -Level Warn 
} 
else 
{
    Add-Content C:\windows\system32\drivers\etc\hosts "`r`n192.168.200.238`tgob0003 `r`n192.168.200.34`tgob0004"
    Write-Output "Host file edited successfully..." | Write-Log
}

Write-Output "***Step 4: add route***" | Write-Log
route add -p 192.168.200.0 mask 255.255.255.0 192.168.187.110
Write-Output "Route added successfully..." | Write-Log

Write-Output "***Step 5: cliconfig***" | Write-Log
if ((test-path -path $x86) -ne $True)
{
	New-Item -Path $x86
	Write-Output "x86 registry path created" | Write-Log
}
if ((test-path -path $x86) -eq $True)
{
	New-ItemProperty -Path $x86 -Name FINPROD -PropertyType string -Value "DBMSSOCN,GOB0003,1433"
	New-ItemProperty -Path $x86 -Name GOB0003 -PropertyType string -Value "DBMSSOCN,GOB0003,1433"
	New-ItemProperty -Path $x86 -Name GOB0004 -PropertyType string -Value "DBMSSOCN,GOB0004,1433"
	New-ItemProperty -Path $x86 -Name HRPROD -PropertyType string -Value "DBMSSOCN,GOB0004,1433"
	Write-Output "Created Cliconfig for x86" | Write-Log
}
if ((test-path -path $x64) -ne $True)
{
    
	New-Item -Path $x64
	Write-Output "x64 registry path created" | Write-Log
}
if ((test-path -path $x64) -eq $True)
{
	New-ItemProperty -Path $x64 -Name FINPROD -PropertyType string -Value "DBMSSOCN,GOB0003,1433"
	New-ItemProperty -Path $x64 -Name GOB0003 -PropertyType string -Value "DBMSSOCN,GOB0003,1433"
	New-ItemProperty -Path $x64 -Name GOB0004 -PropertyType string -Value "DBMSSOCN,GOB0004,1433"
	New-ItemProperty -Path $x64 -Name HRPROD -PropertyType string -Value "DBMSSOCN,GOB0004,1433"
	Write-Output "Created Cliconfig for x64" | Write-Log
}

Write-Output "Aliases added successfully..." | Write-Log

Write-Output "***Step 6: ODBC***" | Write-Log
Add-OdbcDsn -Name "DBSzcrd" -DriverName "SQL Server" -Platform 32-bit -DsnType System -SetPropertyValue @("Server=gob0003", "Trusted_Connection=Yes", "Database=gob0003")
Add-OdbcDsn -Name "FINPROD" -DriverName "SQL Server" -Platform 32-bit -DsnType System -SetPropertyValue @("Server=gob0003", "Trusted_Connection=Yes", "Database=gob0003")
Add-OdbcDsn -Name "GOB0003" -DriverName "SQL Server" -Platform 32-bit -DsnType System -SetPropertyValue @("Server=gob0003", "Trusted_Connection=Yes", "Database=gob0003")
Add-OdbcDsn -Name "GOB0004" -DriverName "SQL Server" -Platform 32-bit -DsnType System -SetPropertyValue @("Server=gob0004", "Trusted_Connection=Yes", "Database=gob0003")
Add-OdbcDsn -Name "HRPROD" -DriverName "SQL Server" -Platform 32-bit -DsnType System -SetPropertyValue @("Server=gob0004", "Trusted_Connection=Yes", "Database=gob0003")
Write-Output "ODBC creation successfull..." | Write-Log
Write-Output "IMPORTANT! open ODBC, enable SQL server authentication and enter a valid Smartstream username and password. Also add DBSctlg as the default database." | Write-Log -Level Warn

c:\Windows\SysWOW64\odbcad32.exe

write-output "Please install smartstream"
Write-Log -Message "running smartstream installer" -Level Info
cd "\\$domain\$share"
.\SS\setup.exe

Write-Output "Cleanup" | Write-Log
if(Test-Path C:\sstrm80\)
{
    Copy-Item -Path "\\$domain\$share\SS\PBACC125.DLL" -Destination C:\sstrm80\PBACC125.DLL
    Write-Output "PBACC125.DLL copied successfully" | Write-Log
}
else
{
    MD C:\sstrm80
    Copy-Item -Path "\\$domain\$share\SS\PBACC125.DLL" -Destination C:\sstrm80\PBACC125.DLL
    Write-Output "PBACC125.DLL copied successfully. You may need to run the smartstream installer manually" | Write-Log
}
Write-Output "Script executed successfully!"  | Write-Log

#Prevent powershell window from exiting
Read-Host -Prompt "Press Enter to exit"
