# Install-Smartstream
Powershell Script to automate installation of Smartstream 8
Date: 2017-08-28
Version: 2.1 
PLEASE RUN AS ADMINISTRATOR OR EXECUTION WILL FAIL!
There are a few ways to run this script
1. Run Setup.bat as administrator
2. Type "set-executionpolicy bypass" Without quotes in powershell to allow script execution. Then run the script
3. Log in as Administrator, Right click Install-SmartstreamV1.ps1 and select "Run with PowerShell. Type "y" and enter.

Changelog
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
