[CmdletBinding()]
param(
)
$M365DSCTestFolder = Join-Path -Path $PSScriptRoot `
                        -ChildPath "..\..\Unit" `
                        -Resolve
$CmdletModule = (Join-Path -Path $M365DSCTestFolder `
            -ChildPath "\Stubs\Microsoft365.psm1" `
            -Resolve)
$GenericStubPath = (Join-Path -Path $M365DSCTestFolder `
    -ChildPath "\Stubs\Generic.psm1" `
    -Resolve)
Import-Module -Name (Join-Path -Path $M365DSCTestFolder `
        -ChildPath "\UnitTestHelper.psm1" `
        -Resolve)

$Global:DscHelper = New-M365DscUnitTestHelper -StubModule $CmdletModule `
    -DscResource "SCCaseHoldRule" -GenericStubModule $GenericStubPath
Describe -Name $Global:DscHelper.DescribeHeader -Fixture {
    InModuleScope -ModuleName $Global:DscHelper.ModuleName -ScriptBlock {
        Invoke-Command -ScriptBlock $Global:DscHelper.InitializeScript -NoNewScope

        BeforeAll {
            $secpasswd = ConvertTo-SecureString "test@password1" -AsPlainText -Force
            $Credential = New-Object System.Management.Automation.PSCredential ("tenantadmin", $secpasswd)


            Mock -CommandName Update-M365DSCExportAuthenticationResults -MockWith {
                return @{}
            }

            Mock -CommandName Get-M365DSCExportContentForResource -MockWith {

            }

            Mock -CommandName Confirm-M365DSCDependencies -MockWith {

            }

            Mock -CommandName New-M365DSCConnection -MockWith {
                return "Credential"
            }

            Mock -CommandName Import-PSSession -MockWith {

            }

            Mock -CommandName New-PSSession -MockWith {

            }

            Mock -CommandName Remove-CaseHoldRule -MockWith {
                return @{

                }
            }

            Mock -CommandName New-CaseHoldRule -MockWith {
                return @{

                }
            }

            Mock -CommandName Set-CaseHoldRule -MockWith {
                return @{

                }
            }
        }

        # Test contexts
        Context -Name "Rule doesn't already exists and should" -Fixture {
            BeforeAll {
                $testParams = @{
                    Name               = "TestRule"
                    Policy             = "TestPolicy"
                    Comment            = "This is a test Rule"
                    Disabled           = $false
                    ContentMatchQuery  = "filename:2016 budget filetype:xlsx"
                    Credential = $Credential
                    Ensure             = "Present"
                }

                Mock -CommandName Get-CaseHoldRule -MockWith {
                    return $null
                }
            }

            It 'Should return false from the Test method' {
                Test-TargetResource @testParams | Should -Be $false
            }

            It 'Should return Absent from the Get method' {
                (Get-TargetResource @testParams).Ensure | Should -Be "Absent"
            }

            It "Should call the Set method" {
                Set-TargetResource @testParams
            }
        }

        Context -Name "Rule already exists and should be updated" -Fixture {
            BeforeAll {
                $testParams = @{
                    Name               = "TestRule"
                    Policy             = "TestPolicy"
                    Comment            = "This is a test Rule"
                    Disabled           = $false
                    ContentMatchQuery  = "filename:2016 budget filetype:xlsx"
                    Credential = $Credential
                    Ensure             = "Present"
                }

                Mock -CommandName Get-CaseHoldRule -MockWith {
                    return @{
                        Name              = "TestRule"
                        Policy            = "12345-12345-12345-12345-12345"
                        Comment           = "Different comment"
                        Disabled          = $true
                        ContentMatchQuery = "filename:2016 budget filetype:xlsx"
                    }
                }

                Mock -CommandName Get-CaseHoldPolicy -MockWith {
                    return @{
                        Name     = "TestPolicy"
                        Identity = "12345-12345-12345-12345-12345"
                    }
                }
            }

            It 'Should return false from the Test method' {
                Test-TargetResource @testParams | Should -Be $False
            }

            It 'Should update from the Set method' {
                Set-TargetResource @testParams
            }

            It 'Should return Present from the Get method' {
                (Get-TargetResource @testParams).Ensure | Should -Be "Present"
            }
        }

        Context -Name "Rule already exists, but should be absent" -Fixture {
            BeforeAll {
                $testParams = @{
                    Name               = "TestRule"
                    Policy             = "TestPolicy"
                    Comment            = "This is a test Rule"
                    Disabled           = $false
                    ContentMatchQuery  = "filename:2016 budget filetype:xlsx"
                    Credential = $Credential
                    Ensure             = "Absent"
                }

                Mock -CommandName Get-CaseHoldRule -MockWith {
                    return @{
                        Name              = "TestRule"
                        Policy            = "12345-12345-12345-12345-12345"
                        Comment           = "Different comment"
                        Disabled          = $true
                        ContentMatchQuery = "filename:2016 budget filetype:xlsx"
                    }
                }

                Mock -CommandName Get-CaseHoldPolicy -MockWith {
                    return @{
                        Name     = "TestPolicy"
                        Identity = "12345-12345-12345-12345-12345"
                    }
                }
            }

            It 'Should return false from the Test method' {
                Test-TargetResource @testParams | Should -Be $False
            }

            It 'Should update from the Set method' {
                Set-TargetResource @testParams
            }

            It 'Should return Present from the Get method' {
                (Get-TargetResource @testParams).Ensure | Should -Be "Present"
            }
        }

        Context -Name "ReverseDSC Tests" -Fixture {
            BeforeAll {
                $testParams = @{
                    Credential = $Credential
                }

                $testRule1 = @{
                    Name              = "TestRule1"
                    Policy            = "12345-12345-12345-12345-12345"
                    Comment           = "Different comment"
                    Disabled          = $true
                    ContentMatchQuery = "filename:2016 budget filetype:xlsx"
                }

                $testRule2 = @{
                    Name              = "TestRule2"
                    Policy            = "12345-12345-12345-12345-12345"
                    Comment           = "Different comment"
                    Disabled          = $true
                    ContentMatchQuery = "filename:2016 budget filetype:xlsx"
                }

                Mock -CommandName Get-CaseHoldPolicy -MockWith {
                    return @{
                        Name     = "TestPolicy"
                        Identity = "12345-12345-12345-12345-12345"
                    }
                }
            }

            It "Should Reverse Engineer resource from the Export method when single" {
                Mock -CommandName Get-CaseHoldRule -MockWith {
                    return $testRule1
                }

                Export-TargetResource @testParams
            }

            It "Should Reverse Engineer resource from the Export method when multiple" {
                Mock -CommandName Get-CaseHoldRule -MockWith {
                    return @($testRule1, $testRule2)
                }

                Export-TargetResource @testParams
            }
        }
    }
}

Invoke-Command -ScriptBlock $Global:DscHelper.CleanupScript -NoNewScope
