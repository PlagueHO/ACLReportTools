ACLReportTools
==============
This module contains functions for creating reports on file, folder and share ACL's, storing the reports and comparing them with earlier reports.

Requirements
------------
> PowerShell 2.0

Overview
--------
The intended purpose of this module is to allow an Admininstrator to report on how ACL's for a set of path or shares have changed since a baseline was last created.

Basically it allows administrators to easily see what ACL changes are being made so they keep an eye on any security issues arising.
The process of creating/updating the baseline and producing the ACL Difference report could be easily automated.
If performing SMB share comparisons, the report generation can be performed remotely (from a desktop PC for example).

The process that is normally followed using this module is:

1. Produce a baseline ACL Report from a set of Folders or Shares (even on multiple computers).
2. Export the baseline ACL Report as a file.
3. ... Sometime later ...
4. Import the baseline ACL Report from a stored file.
5. Produce a ACL Difference report comparing the imported baseline ACL Report with the current ACL state of the Folders or Shares.
6. Optionally export the ACL Difference report as HTML.
7. Repeat from step 1.

The above process could be easily automated in many ways (Task Scheduler is suggested).

The comparison is always performed recursively scanning a specified set of folders or SMB shares.
All files and folders within these locations will be scanned, but only non-inherited ACLs will be added to the ACL Reports.

Definitions
-----------
### ACL Report
An **ACL report** is a list of the current ACLs for a set of Shares or Folders.
It is stored as a serialized array of [ACLReportTools.Permission] objects that are returned by the New-ACLShareReport, New-ACLPathFileReport and Import-ACLReport cmdlets.

ACL Reports produced for Shares rather than folders differ in that the Share name is provided in each [ACLReportTools.Permission] object and that the SMB Share ACL is also provided in the [ACLReportTools.Permission] array.

### ACL Difference Report
An **ACL Difference report** is a list of all ACL differences between two ACL reports.
It is stored as serialized array of [ACLReportTools.PermissionDiff] objects that are produced by the Compare-ACLReports cmdlet.


Important Notes
---------------
When performing a comparison, make sure the baseline report used covers the same set of folders/shares you want to compare now.
E.g. Don't try and compare ACLs for c:\windows and c:\wwwroot - that would make no sense.

If shares or folders that are being compared have large numbers of non-inherited ACLs (perhaps because some junior admin doesn't understand inheritance) then a comparison can take a LONG time (hours) and really hog your CPU. If this is the case, run on another machine using Share mode or run after hours - or better yet, teach junior admins about inheritance! :)

This Module uses the awesome NTFS Security Module available here:

https://gallery.technet.microsoft.com/scriptcenter/1abd77a5-9c0b-4a2b-acef-90dbb2b84e85

Ensure that you unblock all files in the NTFSSecurity module before attempting to Import Module ACLReportTools.
Module ACLReportTools automatically looks for and Imports NTFSSecuriy if present.
If it is missing an error will be reported stating that it is missing.
If you recieve any other errors loading ACL Report tools, it is usually because some of the NTFSSecurity module files are blocked and need to be unblocked manually or with Unblock-File.
You can confirm this by calling Import-Module NTFSSecurity - if any errors appear then it is most likely the cause. After unblocking the module files you may need to restart PowerShell.

You should also ensure that the account that is being used to generate the reports has read access to all paths (recursively) you are reporting on and can access also read the ACLs.
If it can't access them then you may get access denied errors.

Installation
------------
* Installation if WMF5.0 is Installed:
1. In PowerShell execute:
```powershell
Install-Module ACLReportTools
```

* Installation if WMF5.0 is Not Installed:
1. Unzip the archive containing the ACLReportTools module into the one of the PowerShell Modules folders.
   E.g. c:\program files\windowspowershell\modules
2. This will create a folder called ACLReportTools containing all the files required for this module.
3. In PowerShell execute:
```powershell
Import-Module ACLReportTools
```

Example Usage
-------------
### Example Usage: Creating a Baseline ACL Report file from non-inherited permissions only from files and folders
This example creates a baseline ACL Report on the folders e:\work and d:\profiles and stores it in the Baseline.acl file in the current users Documents folder. It will include only non-inherited permissions.
```powershell
Import-Module ACLReportTools
New-ACLPathFileReport -Path "e:\Work","d:\Profiles" | Export-ACLReport -Path "$HOME\Documents\Baseline.acl" -Force
```


### Example Usage: Comparing a Baseline ACL Report file with the current non-inherited permissions only from current file and folder ACLs
This example compares the previously created baseline ACL Report stored in the users Documents folder and compares it with the current ACLs for the folders e:\Work and d:\Profiles. It will include only non-inherited permissions.
```powershell
Import-Module ACLReportTools
Compare-ACLReports -Baseline (Import-ACLReport -Path "$HOME\Documents\Baseline.acl") -Path "e:\Work","d:\Profiles"
```


### Example Usage: Creating a Baseline ACL Report file from inherited and non-inherited permissions only from files and folders
This example creates a baseline ACL Report on the folders e:\work and d:\profiles and stores it in the Baseline.acl file in the current users Documents folder. It will include inherited and non-inherited permissions.
```powershell
Import-Module ACLReportTools
New-ACLPathFileReport -Path "e:\Work","d:\Profiles" -IncudeInherited | Export-ACLReport -Path "$HOME\Documents\Baseline.acl" -Force
```


### Example Usage: Comparing a Baseline ACL Report file with the current inherited and non-inherited permissions only from current file and folder ACLs
This example compares the previously created baseline ACL Report stored in the users Documents folder and compares it with the current ACLs for the folders e:\Work and d:\Profiles. It will include inherited and non-inherited permissions.
```powershell
Import-Module ACLReportTools
Compare-ACLReports -Baseline (Import-ACLReport -Path "$HOME\Documents\Baseline.acl") -Path "e:\Work","d:\Profiles" -IncudeInherited
```


### Example Usage: Creating a Baseline ACL Report file from non-inherited permissions only from shares
This example creates a baseline ACL Report on the shares \\client\Share1\ and \\client\Share2\ and stores it in the Baseline.acl file in the current users Documents folder. It will include only non-inherited permissions.
```powershell
Import-Module ACLReportTools
New-ACLShareReport -ComputerName Client -Include Share1,Share2 | Export-ACLReport -Path "$HOME\Documents\Baseline.acl" -Force
```


### Example Usage: Comparing a Baseline ACL Report file with the current non-inherited permissions only from current shares ACLs
This example compares the previously created baseline ACL Report stored in the users Documents folder and compares it with the current ACLs for the shares \\client\Share1\ and \\client\Share2\. It will include only non-inherited permissions.
```powershell
Import-Module ACLReportTools
Compare-ACLReports -Baseline (Import-ACLReport -Path "$HOME\Documents\Baseline.acl") -ComputerName Client -Include Share1,Share2
```


### Example Usage: Creating a Baseline ACL Report file from inherited and non-inherited permissions only from shares
This example creates a baseline ACL Report on the shares \\client\Share1\ and \\client\Share2\ and stores it in the Baseline.acl file in the current users Documents folder. It will include inherited and non-inherited permissions.
```powershell
Import-Module ACLReportTools
New-ACLShareReport -ComputerName Client -Include Share1,Share2 | Export-ACLReport -Path "$HOME\Documents\Baseline.acl" -Force -IncudeInherited
```


### Example Usage: Comparing a Baseline ACL Report file with the current inherited and non-inherited permissions only from current shares ACLs
This example compares the previously created baseline ACL Report stored in the users Documents folder and compares it with the current ACLs for the shares \\client\Share1\ and \\client\Share2\. It will include inherited and non-inherited permissions.
```powershell
Import-Module ACLReportTools
Compare-ACLReports -Baseline (Import-ACLReport -Path "$HOME\Documents\Baseline.acl") -ComputerName Client -Include Share1,Share2 -IncudeInherited
```


### Example Usage: Exporting a Difference Report as an HTML File
This example takes the output of the Compare-ACLReports cmdlet and formats it as HTML and saves it for easier review and storage.
```powershell
Import-Module ACLReportTools
Compare-ACLReports -Baseline (Import-ACLReport -Path "$HOME\Documents\Baseline.acl") -ComputerName Client -Include Share1,Share2 | Export-ACLPermissionDiffHTML -Path "$HOME\Documents\Difference.htm"
```


CmdLets
-------
### New-ACLShareReport
#### SYNOPSIS
Creates a list of Share, File and Folder ACLs for the specified shares/computers.

#### DESCRIPTION 
Produces an array of [ACLReportTools.Permission] objects for the computers provided. Specific shares can be specified or excluded using the Include/Exclude parameters.

The report can be stored for use as a comparison in either a variable or as a file using the Export-ACLReport cmdlet (found in this module). For example:

```powershell
New-ACLShareReport -ComputerName CLIENT01 -Include MyShare,OtherShare | Export-ACLReport -path c:\ACLReports\CLIENT01_2014_11_14.acl
```
     
#### PARAMETER ComputerName
This is the computer(s) to create the ACL Share report for. The Computer names can also be passed in via the pipeline.

#### PARAMETER Include
This is a list of shares to include from the report. If this parameter is not set it will default to including all shares. This parameter can't be set if the Exclude parameter is set.

#### PARAMETER Exclude
This is a list of shares to exclude from the report. If this parameter is not set it will default to excluding no shares. This parameter can't be set if the Include parameter is set.

#### PARAMETER IncludeInherited
Setting this switch will cause the non inherited file/folder ACLs to be pulled recursively.

#### EXAMPLE 
```powershell
New-ACLShareReport -ComputerName CLIENT01
```
Creates a report of all the Share and file/folder ACLs on the CLIENT01 machine.

#### EXAMPLE 
```powershell
New-ACLShareReport -ComputerName CLIENT01 -Include MyShare,OtherShare
```
Creates a report of all the Share and file/folder ACLs on the CLIENT01 machine that are in shares named either MyShare or OtherShare.

#### EXAMPLE 
```powershell
New-ACLShareReport -ComputerName CLIENT01 -Exclude SysVol
```
Creates a report of all the Share and file/folder ACLs on the CLIENT01 machine that are in shares not named SysVol.


### New-ACLPathFileReport
#### SYNOPSIS
Creates a list of File and Folder ACLs for the provided path(s).

#### DESCRIPTION 
Produces an array of [ACLReportTools.Permission] objects for the list of paths provided.

The report can be stored for use as a comparison in either a variable or as a file using the Export-ACLReport cmdlet (found in this module). For example:

```powershell
New-ACLPathFileReport -Path e:\public | Export-ACLReport -path c:\ACLReports\Public_2015-04-04.acl
```
     
#### PARAMETER Path
This is the path(s) to create the ACL PathFile report for.

#### PARAMETER IncludeInherited
Setting this switch will cause the non inherited file/folder ACLs to be pulled recursively.

#### EXAMPLE 
```powershell
New-ACLPathFileReport -Path e:\public
```
Creates a report of all the file/folder ACLs in the e:\public folder on this machine.

    
### Export-ACLReport
#### SYNOPSIS
Export an ACL Report as a file.

#### DESCRIPTION 
This Cmdlet will save whatever ACL Report that is in the pipeline to a file.

This cmdlet just calls Export-ACLPermission although at some point will add additional functionality.
     
#### PARAMETER Path
This is the path to the ACL Permission Report output file. This parameter is required.

#### PARAMETER InputObject
Specifies the Permissions objects to export to the file. Enter a variable that contains the objects or type a command or expression that gets the objects. You can also pipe ACLReportTools.Permission objects to this cmdlet.

#### PARAMETER Force
Causes the file to be overwritten if it exists.

#### EXAMPLE 
```powershell
New-ACLShareReport -ComputerName CLIENT01 -Include MyShare,OtherShare | Export-ACLReport -path c:\ACLReports\CLIENT01_2014_11_14.acl
```
Creates a new ACL Share Report for Computer Client01 for the MyShare and OtherShares and exports it to the file C:\ACLReports\CLIENT01_2014_11_14.acl.

#### EXAMPLE 
```powershell
Export-ACLReport -Path C:\ACLReports\server01.acl -InputObject $ShareReport
```
Saves the ACLs in the $ShareReport variable to the file C:\ACLReports\server01.acl.

#### EXAMPLE 
```powershell
Export-ACLReport -Path C:\ACLReports\server01.acl -InputObject (New-ACLShareReport -ComputerName SERVER01) -Force
```
Saves the file ACLs for all shares on the compuer SERVER01 to the file C:\ACLReports\server01.acl. If the file exists it will be overwritten.

#### EXAMPLE 
```powershell
New-ACLShareReport -ComputerName SERVER01 | Export-ACLReport -Path C:\ACLReports\server01.acl -Force
```
Saves the file ACLs for all shares on the compuer SERVER01 to the file C:\ACLReports\server01.acl. If the file exists it will be overwritten.
    

### Import-ACLReport
#### SYNOPSIS
Import the ACL Report that is in a file.

#### DESCRIPTION 
This Cmdlet will import all the ACL Report (ACLReportTools.Permission) objects from a specified file into the pipeline.

This cmdlet just calls Import-ACLPermission although at some point will add additional functionality.
     
#### PARAMETER Path
This is the path to the ACL Permission Report file to import. This parameter is required.

#### EXAMPLE 
```powershell
Import-ACLReport -Path C:\ACLReports\server01.acl
```
Imports the ACL Share Report from the file C:\ACLReports\server01.acl and puts it into the pipeline


### Export-ACLDiffReport
#### SYNOPSIS
Export an ACL Permission Diff Report as a file.

#### DESCRIPTION 
This Cmdlet will save whatever ACL Permission Diff Report that is in the pipeline to a file.

This cmdlet just calls Export-ACLPermissionDiff although at some point will add additional functionality.
     
#### PARAMETER Path
This is the path to the ACL Permission Diff Report output file. This parameter is required.

#### PARAMETER InputObject
Specifies the Permissions objects to export to the file. Enter a variable that contains the objects or type a command or expression that gets the objects. You can also pipe ACLReportTools.PermissionDiff objects to Export-ACLReport.

#### PARAMETER Force
Causes the file to be overwritten if it exists.

#### EXAMPLE 
```powershell
Compare-ACLReports -Baseline (Import-ACLReports -Path c:\ACLReports\CLIENT01_2014_11_14.acl) -With (Get-ACLReport -ComputerName CLIENT01) | Export-ACLDiffReport -Path "$HOME\Documents\Compare.acr"
```
This will perform a comparison of the current share ACL report from computer CLIENT01 with the stored share ACL report in file c:\ACLReports\CLIENT01_2014_11_14.acl and then export the report file
to $HOME\Documents\Compare.acr


### Import-ACLDiffReport
#### SYNOPSIS
Import the ACL Difference Report that is in a file.

#### DESCRIPTION 
This Cmdlet will import all the ACL Difference Report (ACLReportTools.PermissionDiff) objects from a specified file into the pipeline.

This cmdlet just calls Import-ACLPermissionDiff although at some point will add additional functionality.
     
#### PARAMETER Path
This is the path to the ACL Permission Report file to import. This parameter is required.

#### EXAMPLE 
```powershell
Import-ACLDiffReport -Path C:\ACLReports\server01.acr
```
Imports the ACL Share Report from the file C:\ACLReports\server01Permission and puts it into the pipeline


### Compare-ACLReports
#### SYNOPSIS
Compares two ACL reports and produces an ACL Difference report.

#### DESCRIPTION 
This cmdlets compares two ACL Share reports and produces a difference list in the pipeline that can then be reported on.

A baseline report (usually from importing a previous ACL Share Report) must be provided. The second ACL Share report (called the current ACL Share report) will be compared against the baseline report.
The current ACL report will be either generated by the New-ACLShareReport or New-ACLPathFileReport cmdlets (depending on parameters) or it can be passed in via the With variable.
   
#### PARAMETER Baseline
This is the baseline report data the comparison will focus on. It will usually be pulled in from a previously saved Share ACL report via the Import-ACLReports 

#### PARAMETER ComputerName
This is the computer(s) to generate the current list of Share ACLs for to perform the comparison with the baseline. The Computer names can also be passed in via the pipeline.

This parameter should not be used if the With Parameter is provided.

#### PARAMETER Include
This is a list of shares to include from the comparison. If this parameter is not set it will default to including all shares. This parameter can't be set if the Exclude parameter is set.

This parameter should not be used if the With Parameter is provided.

#### PARAMETER Exclude
This is a list of shares to exclude from the comparison. If this parameter is not set it will default to excluding no shares. This parameter can't be set if the Include parameter is set.

This parameter should not be used if the With Parameter is provided.

#### PARAMETER With
This parameter provides an ACL Share report to compare with the Baseline ACL Share report.

This parameter should not be used if the ComputerName Parameter is provided.

#### PARAMETER ReportNoChange
Setting this switch will cause a 'No Change' report item to be shown when a share is identical in both the baseline and current reports.

#### PARAMETER IncludeInherited
Setting this switch will cause the non inherited file/folder ACLs to be pulled recursively.

#### EXAMPLE
```powershell
Compare-ACLReports -Baseline (Import-ACLReports -Path c:\ACLReports\CLIENT01_2014_11_14.acl) -With (Get-ACLReport -ComputerName CLIENT01)
```
This will perform a comparison of the current share ACL report from computer CLIENT01 with the stored share ACL report in file c:\ACLReports\CLIENT01_2014_11_14.acl

#### EXAMPLE
```powershell
Compare-ACLReports -Baseline (Import-ACLReports -Path c:\ACLReports\CLIENT01_2014_11_14.acl) -ComputerName CLIENT01
```
This will perform a comparison of the current share ACL report from computer CLIENT01 with the stored share ACL report in file c:\ACLReports\CLIENT01_2014_11_14.acl

#### EXAMPLE
```powershell
Compare-ACLReports -Baseline (Import-ACLReports -Path c:\ACLReports\CLIENT01_2014_11_14_SHARE01_ONLY.acl) -ComputerName CLIENT01 -Include SHARE01
```
This will perform a comparison of the current share ACL report from computer CLIENT01 for only SHARE01 with the stored share ACL report in file c:\ACLReports\CLIENT01_2014_11_14_SHARE01_ONLY.acl

#### EXAMPLE
```powershell
"CLIENT01" | Compare-ACLReports -Baseline (Import-ACLReports -Path c:\ACLReports\CLIENT01_2014_11_14.acl)
```
This will perform a comparison of the current share ACL report from computer CLIENT01 with the stored share ACL report in file c:\ACLReports\CLIENT01_2014_11_14.acl

#### EXAMPLE
```powershell
Compare-ACLReports -Baseline (Import-ACLReports -Path c:\ACLReports\CLIENT01_2014_11_14.acl) -With (Import-ACLReports -Path c:\ACLReports\CLIENT01_2014_06_01.acl)
```
This will perform a comparison of the share ACL report in file c:\ACLReports\CLIENT01_2014_06_01.acl with the stored share ACL report in file c:\ACLReports\CLIENT01_2014_11_14.acl


### Export-ACLPermission
#### SYNOPSIS
Export the ACL Permissions objects that are provided as a file.

#### DESCRIPTION 
This Cmdlet will save what ever ACLs (ACLReportTools.Permission) to a file.
     
#### PARAMETER Path
This is the path to the ACL Permissions file output file. This parameter is required.

#### PARAMETER InputObject
Specifies the ACL Permissions objects to export to the file. Enter a variable that contains the objects or type a command or expression that gets the objects. You can also pipe ACLReportTools.Permission objects to cmdlet.

#### PARAMETER Force
Causes the file to be overwritten if it exists.

#### EXAMPLE 
```powershell
New-ACLPathFileReport -Path e:\Shares | Export-ACLPermission -Path C:\ACLReports\server01.acl
```
Creates a new ACL Permission report for e:\Shares and saves it to the file C:\ACLReports\server01.acl.

#### EXAMPLE 
```powershell
Export-ACLPermission -Path C:\ACLReports\server01.acl -InputObject $Acls
```
Saves the ACL Permissions in the $Acls variable to the file C:\ACLReports\server01.acl.

#### EXAMPLE 
```powershell
Export-ACLPermission -Path C:\ACLReports\server01.acl -InputObject (Get-ACLShare -ComputerName SERVER01 | Get-ACLShareFileACL -Recurse)
```
Saves the file ACLs for all shares on the compuer SERVER01 to the file C:\ACLReports\server01.acl.


### Import-ACLPermission
#### SYNOPSIS
Import the a File containing serialized ACL Permission objects that are in a file back into the pipeline.

#### DESCRIPTION
This Cmdlet will load all the ACLs (ACLReportTools.Permission) records from a specified file.
     
#### PARAMETER Path
This is the path to the file containing ACL Permission objects. This parameter is required.

#### EXAMPLE 
```powershell
Import-ACLPermission -Path C:\ACLReports\server01.acl
```
Loads the ACLs in the file C:\ACLReports\server01.acl.


### Export-ACLPermissionDiff
#### SYNOPSIS
Export the ACL Difference Objects that are provided as a file.

#### DESCRIPTION 
This Cmdlet will export an array of provided Permission Difference [ACLReportTools.PermissionDiff] records to a file.
     
#### PARAMETER Path
This is the path to the ACL Permission Diff file. This parameter is required.

#### PARAMETER InputObject
Specifies the Permissions objects to export to th file. Enter a variable that contains the objects or type a command or expression that gets the objects. You can also pipe ACLReportTools.PermissionDiff objects to this cmdlet.

#### PARAMETER Force
Causes the file to be overwritten if it exists.

#### EXAMPLE 
```powershell
Export-ACLPermissionDiff -Path C:\ACLReports\server01.acr -InputObject $DiffReport
```
Saves the ACL Difference objects in the $DiffReport variable to the file C:\ACLReports\server01.acr.  If the file exists it will be overwritten if the Force switch is set.


### Import-ACLPermissionDiff
#### SYNOPSIS
Import the a File containing serialized ACL Permission Diff objects that are in a file back into the pipeline.

#### DESCRIPTION
This Cmdlet will load all the ACLs (ACLReportTools.PermissionDiff) records from a specified file.
     
#### PARAMETER Path
This is the path to the file containing ACL Permission Diff objects. This parameter is required.

#### EXAMPLE 
```powershell
Import-ACLPermissionDiff -Path C:\ACLReports\server01.acr
```
Loads the ACL Permission Diff objects in the file C:\ACLReports\server01.acr.


### Export-ACLPermissionDiffHTML
#### SYNOPSIS
Export the ACL Difference Objects that are provided as an HTML file.

#### DESCRIPTION 
This Cmdlet will export an array of provided Permission Difference [ACLReportTools.PermissionDiff] records to an HTML file for easy viewing and reporting.
     
#### PARAMETER Path
This is the path to the HTML output file. This parameter is required.

#### PARAMETER InputObject
Specifies the Permissions DIff objects to export to the as HTML. Enter a variable that contains the objects or type a command or expression that gets the objects. You can also pipe ACLReportTools.PermissionDiff objects to this cmdlet.

#### PARAMETER Force
Causes the file to be overwritten if it exists.

#### PARAMETER Title
Optional Title text to write into the report.

#### EXAMPLE 
```powershell
Compare-ACLReports -Baseline (Import-ACLReports -Path c:\ACLReports\server01.acl) -With (Get-ACLReport -ComputerName Server01) | Export-ACLPermissionDiffHTML -Path C:\ACLReports\server01.htm
```
Performs a comparison using the Baseline file c:\ACLReports\Server01.acl and the shares on Server01 and outputs ACL Difference Report as an HTML file.


### Get-ACLShare
#### SYNOPSIS
Gets a list of the Shares on a specified computer(s) with specified inclusions or exclusions.

#### DESCRIPTION 
This function will pull a list of shares that are set up on the specified computer. Shares can also be included or excluded from the share list by setting the Include or Exclude properties.

The Cmdlet returns an array of ACLReportTools.Share objects.
     
#### PARAMETER ComputerName
This is the computer to get the shares from. If this parameter is not set it will default to the current machine.

#### PARAMETER Include
This is a list of shares to include from the computer. If this parameter is not set it will default to including all shares. This parameter can't be set if the Exclude parameter is set.

#### PARAMETER Exclude
This is a list of shares to exclude from the computer. If this parameter is not set it will default to excluding no shares. This parameter can't be set if the Include parameter is set.

#### EXAMPLE 
```powershell
Get-ACLShare -ComputerName CLIENT01
```
Returns a list of all shares set up on the CLIENT01 machine.

#### EXAMPLE 
```powershell
Get-ACLShare -ComputerName CLIENT01 -Include MyShare,OtherShare
```
Returns a list of shares that are set up on the CLIENT01 machine that are named either MyShare or OtherShare.

#### EXAMPLE 
```powershell
Get-ACLShare -ComputerName CLIENT01 -Exclude SysVol
```
Returns a list of shares that are set up on the CLIENT01 machine that are not called SysVol.

#### EXAMPLE 
```powershell
Get-ACLShare -ComputerName CLIENT01,CLIENT02
```
Returns a list of shares that are set up on the CLIENT01 and CLIENT02 machines.

#### EXAMPLE 
```powershell
Get-ACLShare -ComputerName CLIENT01,CLIENT02 -Exclude SysVol
```
Returns a list of shares that are set up on the CLIENT01 and CLIENT02 machines that are not called SysVol.


### Get-ACLShareACL
#### SYNOPSIS
Gets the ACLs for a specified Share.

#### DESCRIPTION 
This function will return the share ACLs for the specified share.
     
#### PARAMETER ComputerName
This is the computer to get the share ACLs from. If this parameter is not set it will default to the current machine.

#### PARAMETER ShareName
This is the share name to pull the share ACLs for.

#### PARAMETER Shares
This is a pipeline parameter that should be used for passing in a list of shares and computers to pull ACLs for. This parameter expects an array of [ACLReportTools.Share] objects.

This parameter is usually used with the Get-ACLShare CmdLet.

For example:

```powershell
Get-ACLShare -ComputerName CLIENT01,CLIENT02 -Exclude SYSVOL | Get-ACLShareACL 
```

#### EXAMPLE 
```powershell
Get-ACLShareACL -ComputerName CLIENT01 -ShareName MyShre
```
Returns the share ACLs for the MyShare Share on the CLIENT01 machine.


### Get-ACLShareFileACL
#### SYNOPSIS
Gets all the file/folder ACLs definited within a specified Share.

#### DESCRIPTION 
This function will return a list of file/folder ACLs for the specified share. If the Recurse switch is used then files/folder ACLs will be scanned recursively. If the IncludeInherited switch is set then inherited file/folder permissions will also be returned, otherwise only non-inherited permissions will be returned. 
     
#### PARAMETER ComputerName
This is the computer to get the share ACLs from. If this parameter is not set it will default to the current machine.

#### PARAMETER ShareName
This is the share name to pull the file/folder ACLs for.

#### PARAMETER Recurse
Setting this switch will cause the file/folder ACLs to be pulled recursively.

#### PARAMETER IncludeInherited
Setting this switch will cause the non inherited file/folder ACLs to be pulled recursively.

#### EXAMPLE 
```powershell
Get-ACLShareFileACL -ComputerName CLIENT01 -ShareName MyShare
```
Returns the file/folder ACLs for the root of MyShare Share on the CLIENT01 machine.

#### EXAMPLE 
```powershell
Get-ACLShareFileACL -ComputerName CLIENT01 -ShareName MyShare -Recurse
```
Returns the file/folder ACLs for all files/folders recursively inside the MyShare Share on the CLIENT01 machine.


### Get-ACLPathFileACL
#### SYNOPSIS
Gets all the file/folder ACLs defined within a specified Path.

#### DESCRIPTION 
This function will return a list of file/folder ACLs for the specified share. If the Recurse switch is used then files/folder ACLs will be scanned recursively. If the IncludeInherited switch is set then inherited file/folder permissions will also be returned, otherwise only non-inherited permissions will be returned. 
     
#### PARAMETER Path
This is the path to pull the file/folder ACLs for.

#### PARAMETER Recurse
Setting this switch will cause the file/folder ACLs to be pulled recursively.

#### PARAMETER IncludeInherited
Setting this switch will cause the non inherited file/folder ACLs to be pulled recursively.

#### EXAMPLE 
```powershell
Get-ACLPathFileACL -Path C:\Users
```
Returns the file/folder ACLs for the root of C:\Users folder.

#### EXAMPLE 
```powershell
Get-ACLPathFileACL -Path C:\Users -Recurse
```
Returns the file/folder ACLs for all files/folders recursively inside the C:\Users folder.

   
Versions
--------
### 1.30.1.0
* 2016-05-21: Changed module init to check NTFSSecurity module version is v4.0.0 or above.

### 1.30.0.0
* 2016-02-09: Moved to new repo.
* 2016-02-09: Updated to support NTFSSecurity 4.0.0.0 module and above.
* 2016-02-09: Added IncludeInherited switch to some cmdlets.
* 2016-02-09: Documentation updated.

### 1.21.0.0
* 2015-05-13: Added Cmdlet for Exporting Diff Report as HTML

### 1.2.0.0
* 2015-05-13: Added Cmdlets for Importing/Exporting Permission Difference reports.

### 1.1.0.0
* 2015-05-12: Updated to use NTFSSecurity Module Updated CmdLet names to follow standards

### 1.0.0.0
* 2015-05-09: Initial Version

Links
-----
* **[GitHub Repo](https://github.com/PlagueHO/ACLReportTools)**: Raise any issues, requests or PRs here.
* **[My Blog](https://dscottraynsford.wordpress.com)**: See my PowerShell and Programming Blog.