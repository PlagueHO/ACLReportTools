#region HEADER
[String] $Global:ModuleRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))

# Import Module
Import-Module -Name (Join-Path -Path $Global:ModuleRoot -ChildPath 'ACLReportTools.psm1') -Force

# Create the artifact path
[String] $Global:ArtifactPath = Join-Path -Path $moduleRoot -ChildPath 'Artifacts'
$null = New-Item `
    -Path $Global:ArtifactPath `
    -ItemType Directory `
    -Force `
    -ErrorAction SilentlyContinue

Write-Verbose -Message "Preparing for integration test run"

[String] $Global:TestPath = Join-Path -Path $env:Temp -ChildPath ([System.IO.Path]::GetRandomFileName()) 
[Int] $Global:MaxShares = 4 # Must be 4 or greater
[String] $Global:FileSourceFolder = Join-Path -Path $env:SystemRoot -ChildPath 'System32\Sysprep'
If (-not (Test-Path -Path $Global:TestPath -PathType Container)) {
    Write-Verbose -Message "Creating test path '$($Global:TestPath)'"
    $null = New-Item `
        -Path $Global:TestPath `
        -ItemType Directory
}

[String[]] $Global:SharePaths = @()
[String[]] $Global:ShareNames = @()
# Create shares used for testing and add files to them
1..$Global:MaxShares | Foreach-Object {
    $ShareName = "Share$($_)"
    $SharePath = Join-Path -Path $Global:TestPath -ChildPath $ShareName
    Write-Verbose -Message "Creating share path '$SharePath'"
    $Global:ShareNames += $ShareName
    $Global:SharePaths += $SharePath
    If (-not (Test-Path $SharePath -PathType Container)) {
        $null = New-Item `
            -Path $SharePath `
            -ItemType Directory
    }
    
    # Create the share
    Write-Verbose -Message "Creating share $ShareName"
    $null = New-SMBShare `
        -Path $SharePath `
        -Name $ShareName
    
    # Copy some random files to the share
    Write-Verbose -Message "Copying content to $ShareName"
    $null = Copy-Item `
        -Path $Global:FileSourceFolder `
        -Destination $SharePath `
        -Recurse `
        -Force

    # Set the permissions on the file/folders in the share
    Write-Verbose -Message "Setting file/folder permissions on $ShareName"
    If ( $_ -eq 2 ) {
        Add-NTFSAccess `
            -Path $SharePath `
            -AccessRights FullControl `
            -AppliesTo ThisFolderSubfoldersAndFiles `
            -AccessType Allow `
            -Account "$ENV:ComputerName\$env:USERNAME" 
        Add-NTFSAccess `
            -Path $SharePath `
            -AccessRights Write `
            -AppliesTo ThisFolderSubfoldersAndFiles `
            -AccessType Allow `
            -Account "$ENV:ComputerName\Administrator" 
        Add-NTFSAccess `
            -Path $SharePath `
            -AccessRights Read `
            -AppliesTo ThisFolderSubfoldersAndFiles `
            -AccessType Allow `
            -Account "BUILTIN\Users" 
        Disable-NTFSAccessInheritance `
            -Path $SharePath `
            -RemoveInheritedAccessRules
        $null = Grant-SMBShareAccess `
            -Name $ShareName `
            -AccountName "BUILTIN\Guests" `
            -AccessRight Full -Force
    }
    If ( $_ -eq 3 ) {
        Add-NTFSAccess `
            -Path $SharePath `
            -AccessRights FullControl `
            -AppliesTo ThisFolderSubfoldersAndFiles `
            -AccessType Allow `
            -Account "BUILTIN\Guests" 
    }
}
#endregion

# Using try/finally to always cleanup even if something awful happens.
try
{
    InModuleScope ACLReportTools {
        #region Integration Tests
        Describe "New-ACLPathFileReport" {
            Context "Create using Non-inherited permissions only" {
                It 'Should not throw exception' {
                    {
                        $Global:NonInheritedPathFileReport = New-ACLPathFileReport -Path $Global:SharePaths
                    } | Should Not Throw
                }
            }
            Context "Create using All permissions" {
                It 'Should not throw exception' {
                    {
                        $Global:AllPathFileReport = New-ACLPathFileReport -Path $Global:SharePaths -IncludeInherited
                    } | Should Not Throw
                }
            }
        }
        
        Describe "New-ACLShareReport" {
            Context "Create using Non-inherited permissions only" {
                It 'Should not throw exception' {
                    {
                        $Global:NonInheritedShareReport = New-ACLShareReport -ComputerName $ENV:ComputerName -Include $ShareNames
                    } | Should Not Throw
                }
            }
            Context "Create using All permissions" {
                It 'Should not throw exception' {
                    {
                        $Global:AllShareReport = New-ACLShareReport -ComputerName $ENV:ComputerName -Include $ShareNames -IncludeInherited
                    } | Should Not Throw
                }
            }
        }

        Describe "Export-ACLReport" {
            Context "Export Path/File report with Non-inherited permissions only" {
                It 'Should not throw exception' {
                    {
                        $Global:NonInheritedPathFileReport | Export-ACLReport `
                            -Path (Join-Path -Path $Global:ArtifactPath -ChildPath 'IntegrationTests.PathFileNonInheritedPermissions.Report.acl') -Force
                    } | Should Not Throw
                }
            }
            Context "Export Path/File report with All permissions" {
                It 'Should not throw exception' {
                    {
                        $Global:AllPathFileReport | Export-ACLReport `
                            -Path (Join-Path -Path $Global:ArtifactPath -ChildPath 'IntegrationTests.PathFileAllPermissions.Report.acl') -Force
                    } | Should Not Throw
                }
            }
            Context "Export Share report with Non-inherited permissions only" {
                It 'Should not throw exception' {
                    {
                        $Global:NonInheritedShareReport | Export-ACLReport `
                            -Path (Join-Path -Path $Global:ArtifactPath -ChildPath 'IntegrationTests.ShareNonInheritedPermissions.Report.acl') -Force
                    } | Should Not Throw
                }
            }
            Context "Export Share report with All permissions" {
                It 'Should not throw exception' {
                    {
                        $Global:AllShareReport | Export-ACLReport `
                            -Path (Join-Path -Path $Global:ArtifactPath -ChildPath 'IntegrationTests.ShareAllPermissions.Report.acl') -Force
                    } | Should Not Throw
                }
            }
        }

        Describe "Import-ACLReport" {
            Context "Import Path/File report with Non-inherited permissions only" {
                It 'Should not throw exception' {
                    {
                        $Global:NonInheritedPathFileReportImported = Import-ACLReport -Path (Join-Path -Path $Global:ArtifactPath -ChildPath 'IntegrationTests.PathFileNonInheritedPermissions.Report.acl')
                    } | Should Not Throw
                }
            }
            Context "Import Path/File report with All permissions" {
                It 'Should not throw exception' {
                    {
                        $Global:AllPathFileReportImported = Import-ACLReport -Path (Join-Path -Path $Global:ArtifactPath -ChildPath 'IntegrationTests.PathFileAllPermissions.Report.acl')
                    } | Should Not Throw
                }
            }
            Context "Import Share report with Non-inherited permissions only" {
                It 'Should not throw exception' {
                    {
                        $Global:NonInheritedShareReportImported = Import-ACLReport -Path (Join-Path -Path $Global:ArtifactPath -ChildPath 'IntegrationTests.ShareNonInheritedPermissions.Report.acl')
                    } | Should Not Throw
                }
            }
            Context "Import Share report with All permissions" {
                It 'Should not throw exception' {
                    {
                        $Global:AllShareReportImported = Import-ACLReport -Path (Join-Path -Path $Global:ArtifactPath -ChildPath 'IntegrationTests.ShareAllPermissions.Report.acl')
                    } | Should Not Throw
                }
            }
        }

        Describe "Compare-ACLReports" {
            Context "Compare Imported Path/File report with Non-inherited permissions only" {
                It 'Should not throw exception' {
                    {
                        $Global:NonInheritedPathFileDiffReport = Compare-ACLReports `
                            -Baseline $Global:NonInheritedPathFileReportImported `
                            -Path $Global:SharePaths
                    } | Should Not Throw
                }
                It 'Should return no differences' {
                    $Global:NonInheritedPathFileDiffReport | Should be $null    
                }
            }
            Context "Compare Imported Path/File report with All permissions" {
                It 'Should not throw exception' {
                    {
                        $Global:AllPathFileDiffReport = Compare-ACLReports `
                            -Baseline $Global:AllPathFileReportImported `
                            -Path $Global:SharePaths `
                            -IncludeInherited
                    } | Should Not Throw
                }
                It 'Should return no differences' {
                    $Global:AllPathFileDiffReport | Should be $null    
                }
            }
            Context "Compare Imported Path/File report with Non-inherited permissions only with All permissions" {
                It 'Should not throw exception' {
                    {
                        $Global:NonInheritedvsAllPathFileDiffReport = Compare-ACLReports `
                            -Baseline $Global:NonInheritedPathFileReportImported `
                            -Path $Global:SharePaths `
                            -IncludeInherited
                    } | Should Not Throw
                }
                It 'Should return some differences' {
                    $Global:NonInheritedvsAllPathFileDiffReport | Should not be $null    
                }
            }
            Context "Compare Imported Share report with Non-inherited permissions only" {
                It 'Should not throw exception' {
                    {
                        $Global:NonInheritedShareDiffReport = Compare-ACLReports `
                            -Baseline $Global:NonInheritedShareReportImported `
                            -Include $Global:ShareNames
                    } | Should Not Throw
                }
                It 'Should return no differences' {
                    $Global:NonInheritedShareDiffReport | Should be $null    
                }
            }
            Context "Compare Imported Share report with All permissions" {
                It 'Should not throw exception' {
                    {
                        $Global:AllShareDiffReport = Compare-ACLReports `
                            -Baseline $Global:AllShareReportImported `
                            -Include $Global:ShareNames `
                            -IncludeInherited
                    } | Should Not Throw
                }
                It 'Should return no differences' {
                    $Global:AllShareDiffReport | Should be $null    
                }
            }
            Context "Compare Imported Share report with Non-inherited permissions only with All permissions" {
                It 'Should not throw exception' {
                    {
                        $Global:AllvsNonInheritedPathFileDiffReport = Compare-ACLReports `
                            -Baseline $Global:NonInheritedShareReportImported `
                            -Include $Global:ShareNames `
                            -IncludeInherited
                    } | Should Not Throw
                }
                It 'Should return some differences' {
                    $Global:AllvsNonInheritedPathFileDiffReport | Should not be $null
                }
            }

            # Modify the Permission information
            1..$Global:MaxShares | Foreach-Object {
                $ShareName = "Share$($_)"
                $SharePath = Join-Path -Path $Global:TestPath -ChildPath $ShareName
                Write-Verbose -Message "Adding NTFS Permission to '$SharePath' AccessRights=FullControl, AppliesTo Filesonly -AccessType Allow -Account $ENV:COMPUTERNAME\$ENV:USERNAME"
                Add-NTFSAccess -Path $Global:TestPath -AccessRights FullControl -AppliesTo FilesOnly -AccessType Allow -Account "$ENV:COMPUTERNAME\$ENV:USERNAME" 
                If ( $_ -eq 1 ) {
                    Write-Verbose -Message "Setting NTFS Owner to $ENV:COMPUTERNAME\$ENV:USERNAME for $SharePath"
                    Set-NTFSOwner -Account "$ENV:COMPUTERNAME\$ENV:USERNAME" -Path $SharePath
                }
                If ( $_ -eq 2 ) {
                    Write-Verbose -Message "Editing NTFS Permission to '$SharePath' AccessRights=FullControl, AppliesTo ThisFolderSubfoldersAndFiles -AccessType Allow -Account BUILTIN\Users"
                    Get-NTFSAccess -Path $SharePath -Account "BUILTIN\Users" | Remove-NTFSAccess
                    Add-NTFSAccess -Path $SharePath -AccessRights FullControl -AppliesTo ThisFolderSubfoldersAndFiles -AccessType Allow -Account "BUILTIN\Users" 
                    Write-Verbose -Message "Removing ACL for $ENV:ComputerName\Administrator on $SharePath"
                    Get-NTFSAccess -Path $SharePath -Account "$ENV:ComputerName\Administrator" | Remove-NTFSAccess
                    Write-Verbose -Message "Revoking Access to $ShareName for Account BUILTIN\Guests"
                    $null = Revoke-SMBShareAccess -Name $ShareName -AccountName "BUILTIN\Guests" -Force
                }
                If ( $_ -eq 3 ) {
                    Write-Verbose -Message "Editing NTFS Permission to '$SharePath' AccessRights=FullControl, AppliesTo ThisFolderSubfoldersAndFiles -AccessType Deny -Account BUILTIN\Guests"
                    Get-NTFSAccess -Path $SharePath -Account "BUILTIN\Guests" | Remove-NTFSAccess
                    Add-NTFSAccess -Path $SharePath -AccessRights Read -AppliesTo ThisFolderSubfoldersAndFiles -AccessType Deny -Account "BUILTIN\Guests"
                    Write-Verbose -Message "Granting Full Access to $ShareName for Account BUILTIN\Guests"
                    $null = Grant-SMBShareAccess -Name $ShareName -AccountName "BUILTIN\Guests" -AccessRight Full -Force
                }
                If ( $_ -eq 4 ) {
                    Write-Verbose -Message "Removing $ShareName"
                    Get-SMBShare -Name $ShareName | Remove-SMBShare -Force
                }
            }

            Context "Compare Imported Path/File report with Non-inherited permissions only after permissions modified" {
                It 'Should not throw exception' {
                    {
                        $Global:NonInheritedPathFileModifiedDiffReport = Compare-ACLReports `
                            -Baseline $Global:NonInheritedPathFileReportImported `
                            -Path $Global:SharePaths
                    } | Should Not Throw
                }
                It 'Should return some differences' {
                    $Global:NonInheritedPathFileModifiedDiffReport | Should not be $null
                }
            }
            Context "Compare Imported Path/File report with All permissions after permissions modified" {
                It 'Should not throw exception' {
                    {
                        $Global:AllPathFileModifiedDiffReport = Compare-ACLReports `
                            -Baseline $Global:AllPathFileReportImported `
                            -Path $Global:SharePaths
                    } | Should Not Throw
                }
                It 'Should return some differences' {
                    $Global:AllPathFileModifiedDiffReport | Should not be $null
                }
            }
            Context "Compare Imported Share report with Non-inherited permissions only after permissions modified" {
                It 'Should not throw exception' {
                    {
                        $Global:NonInheritedShareModifiedDiffReport = Compare-ACLReports `
                            -Baseline $Global:NonInheritedShareReportImported `
                            -Include $Global:ShareNames
                    } | Should Not Throw
                }
                It 'Should return some differences' {
                    $Global:NonInheritedShareModifiedDiffReport | Should not be $null
                }
            }
            Context "Compare Imported Share report with All permissions after permissions modified" {
                It 'Should not throw exception' {
                    {
                        $Global:AllShareModifiedDiffReport = Compare-ACLReports `
                            -Baseline $Global:AllShareReportImported `
                            -Include $Global:ShareNames
                    } | Should Not Throw
                }
                It 'Should return some differences' {
                    $Global:AllShareModifiedDiffReport | Should not be $null
                }
            }
        }

        Describe "Export-ACLPermissionDiff" {
            Context "Export Path/File Different report with Non-inherited permissions only after permissions modified" {
                It 'Should not throw exception' {
                    {
                        $Global:NonInheritedPathFileModifiedDiffReport | Export-ACLPermissionDiff `
                            -Path (Join-Path -Path $Global:ArtifactPath -ChildPath 'IntegrationTests.PathFileNonInheritedModifiedPermissionsDiff.Report.acr') -Force
                    } | Should Not Throw
                }
            }
            Context "Export Path/File Different report with All permissions after permissions modified" {
                It 'Should not throw exception' {
                    {
                        $Global:AllPathFileModifiedDiffReport | Export-ACLPermissionDiff `
                            -Path (Join-Path -Path $Global:ArtifactPath -ChildPath 'IntegrationTests.PathFileAllModifiedPermissionsDiff.Report.acr') -Force
                    } | Should Not Throw
                }
            }
            Context "Export Path/File Different report with Non-inherited permissions only after permissions modified" {
                It 'Should not throw exception' {
                    {
                        $Global:NonInheritedShareModifiedDiffReport | Export-ACLPermissionDiff `
                            -Path (Join-Path -Path $Global:ArtifactPath -ChildPath 'IntegrationTests.ShareNonInheritedModifiedPermissionsDiff.Report.acr') -Force
                    } | Should Not Throw
                }
            }
            Context "Export Path/File Different report with All permissions after permissions modified" {
                It 'Should not throw exception' {
                    {
                        $Global:AllShareModifiedDiffReport | Export-ACLPermissionDiff `
                            -Path (Join-Path -Path $Global:ArtifactPath -ChildPath 'IntegrationTests.ShareAllModifiedPermissionsDiff.Report.acr') -Force                        
                    } | Should Not Throw
                }
            }
        }

        #endregion
    }
}
finally
{
    # Clean up
    Write-Verbose -Message "Removing test shares"
    Get-SMBShare -Name "Share*" | Remove-SMBShare -Force
    Remove-Item $Global:TestPath -Recurse -Force
}
