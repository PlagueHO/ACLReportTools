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
# Create shares used for testing and add files to them
1..$Global:MaxShares | Foreach-Object {
    $ShareName = "Share$($_)"
    $SharePath = Join-Path -Path $Global:TestPath -ChildPath $ShareName
    Write-Verbose -Message "Creating share path '$SharePath'"
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
            Context "Non-inherited permissions only" {
                It 'Should not throw exception' {
                    {
                        $BaselinePathFile1 = New-ACLPathFileReport -Path $Global:SharePaths
                    } | Should Not Throw
                }
            }
            Context "All permissions" {
                It 'Should not throw exception' {
                    {
                        $BaselinePathFile2 = New-ACLPathFileReport -Path $Global:SharePaths -IncludeInherited
                    } | Should Not Throw
                }
            }
        }
        
        Describe "New-ACLShareReport" {
            Context "Non-inherited permissions only" {
                It 'Should not throw exception' {
                    {
                        $BaselinePathFile3 = New-ACLShareReport -ComputerName $ENV:ComputerName
                    } | Should Not Throw
                }
            }
            Context "All permissions" {
                It 'Should not throw exception' {
                    {
                        $BaselinePathFile4 = New-ACLShareReport -ComputerName $ENV:ComputerName -IncludeInherited
                    } | Should Not Throw
                }
            }
        }

        Describe "Export-ACLReport" {
            Context "Path/File report with Non-inherited permissions only" {
                It 'Should not throw exception' {
                    {
                        $BaselinePathFile1 | Export-ACLReport -Path (Join-Path -Path $Global:ArtifactPath -ChildPath 'IntegrationTests.PathFileNonInheritedPermissions.Report.acl') -Force
                    } | Should Not Throw
                }
            }
            Context "Path/File report with All permissions" {
                It 'Should not throw exception' {
                    {
                        $BaselinePathFile2 | Export-ACLReport -Path (Join-Path -Path $Global:ArtifactPath -ChildPath 'IntegrationTests.PathFileAllPermissions.Report.acl') -Force
                    } | Should Not Throw
                }
            }
        }

        Describe "Export-ACLReport" {
            Context "Share report with Non-inherited permissions only" {
                It 'Should not throw exception' {
                    {
                        $BaselinePathFile3 | Export-ACLReport -Path (Join-Path -Path $Global:ArtifactPath -ChildPath 'IntegrationTests.ShareNonInheritedPermissions.Report.acl') -Force
                    } | Should Not Throw
                }
            }
            Context "Share report with All permissions" {
                It 'Should not throw exception' {
                    {
                        $BaselinePathFile4 | Export-ACLReport -Path (Join-Path -Path $Global:ArtifactPath -ChildPath 'IntegrationTests.ShareAllPermissions.Report.acl') -Force
                    } | Should Not Throw
                }
            }
        }

        # Modify the Share information
        1..$Global:MaxShares | Foreach-Object {
            $SharePath = Join-Path -Path $Global:TestPath -ChildPath "Share$($_)"
            Write-Verbose -Message "Adding NTFS Permission to $Global:TestPath AccessRights=FullControl, AppliesTo Filesonly -AccessType Allow -Account $ENV:ComputerName\$env:USERNAME"
            Add-NTFSAccess -Path $Global:TestPath -AccessRights FullControl -AppliesTo FilesOnly -AccessType Allow -Account "$ENV:ComputerName\$ENV:USERNAME" 
            If ( $_ -eq 1 ) {
                Write-Verbose -Message "Setting NTFS Owner to $ENV:ComputerName\$ENV:USERNAME for $SharePath"
                Set-NTFSOwner -Account "$ENV:ComputerName\$env:USERNAME" -Path $SharePath
            }
            If ( $_ -eq 2 ) {
                Write-Verbose -Message "Editing NTFS Permission to $Global:TestPath AccessRights=FullControl, AppliesTo ThisFolderSubfoldersAndFiles -AccessType Allow -Account BUILTIN\Users"
                Get-NTFSAccess -Path $SharePath -Account "BUILTIN\Users" | Remove-NTFSAccess
                Add-NTFSAccess -Path $SharePath -AccessRights FullControl -AppliesTo ThisFolderSubfoldersAndFiles -AccessType Allow -Account "BUILTIN\Users" 
                Write-Verbose -Message "Removing ACL for $ENV:ComputerName\Administrator on $SharePath"
                Get-NTFSAccess -Path $SharePath -Account "$ENV:ComputerName\Administrator" | Remove-NTFSAccess
                Write-Verbose -Message "Revoking Access to Share$($_) for Account BUILTIN\Guests"
                Revoke-SMBShareAccess -Name "Share$($_)" -AccountName "BUILTIN\Guests" -Force | Out-Null
            }
            If ( $_ -eq 3 ) {
                Write-Verbose -Message "Editing NTFS Permission to $Global:TestPath AccessRights=FullControl, AppliesTo ThisFolderSubfoldersAndFiles -AccessType Deny -Account BUILTIN\Guests"
                Get-NTFSAccess -Path $SharePath -Account "BUILTIN\Guests" | Remove-NTFSAccess
                Add-NTFSAccess -Path $SharePath -AccessRights Read -AppliesTo ThisFolderSubfoldersAndFiles -AccessType Deny -Account "BUILTIN\Guests"
                Write-Verbose -Message "Granting Full Access to Share$($_) for Account BUILTIN\Guests"
                Grant-SMBShareAccess -Name "Share$($_)" -AccountName "BUILTIN\Guests" -AccessRight Full -Force | Out-Null
            }
            If ( $_ -eq 4 ) {
                Write-Verbose -Message "Removing Share$($_)"
                Get-SMBShare -Name "Share$($_)" | Remove-SMBShare -Force
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
