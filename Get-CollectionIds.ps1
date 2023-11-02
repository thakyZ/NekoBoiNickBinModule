Param (
  [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = 'Input a workshop id.')]
  [ValidateNotNull()]
  [ValidateNotNullOrEmpty()]
  [string]$Id,

  [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, HelpMessage = 'Enter the file path.')]
  [ValidateNotNull()]
  [ValidateNotNullOrEmpty()]
  [string]$Path
)

Import-Module PowerHTML

$WorkshopCollectionURL = 'https://steamcommunity.com/sharedfiles/filedetails/?id='+$Id

$GetPage = ConvertFrom-Html -Uri $WorkshopCollectionURL
$ModIDCollection = @()
$Links = $GetPage.SelectNodes('//a') | Where-Object { $_.SelectNodes("div[@class='workshopItemTitle']") }
foreach ($Link in $Links) {
  $ModID = $Link.GetAttributeValue("href", "").Replace('https://steamcommunity.com/sharedfiles/filedetails/?id=','')
  if($ModIDCollection -notcontains $modID) {
  $Desc = $Link.innerText
  Write-Host "Found Mod: $Desc"
  $ModIDCollection += $ModID
  }
}
if (Test-Path $Path) {
  Remove-Item -Path $Path
}
Set-Content -Path $Path $ModIDCollection
Write-Host "Your mod list is at: $Path"
$ModIDCollection

# SIG # Begin signature block
# MIIFuQYJKoZIhvcNAQcCoIIFqjCCBaYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUZXpgMTuuyTgTbu1Z1TyMIh9e
# YimgggNCMIIDPjCCAiqgAwIBAgIQR6CKAOXtwqBDcj2H8Lfv5jAJBgUrDgMCHQUA
# MCwxKjAoBgNVBAMTIVBvd2VyU2hlbGwgTG9jYWwgQ2VydGlmaWNhdGUgUm9vdDAe
# Fw0yMDA1MTEwMTU5MjlaFw0zOTEyMzEyMzU5NTlaMBoxGDAWBgNVBAMTD1Bvd2Vy
# U2hlbGwgVXNlcjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMzdqHWd
# jbuBMMVkWgB/sFHjJCHjntMPDsoA10diyMwH2WbH0E3x+tqKy67kuGxgyvfmnv+G
# UieZ1hvtmeONVOZbWzKRELftNbpSMa7Q8e1KGmaavOlTCYtKHsyFH/Lipv5UCTRh
# X5pNe98jfHcxjoGq0thYiE+KrRXtf9zzswHHHdKEk/pk2GFFUPKn0V6iNPS0X37j
# uKCZrO/5X7whT3mI4NhDa/bPB+nUaXHXJqZgKIFOVNIWgkvTiII0tpEg5cbsldVS
# S+yn6YhikwYj2iXGcLHjODNP3SzPzDhMbWkORBJpzC8eaN91T3xozZ8HnI0QFxu/
# ja1LA1xy6ormRskCAwEAAaN2MHQwEwYDVR0lBAwwCgYIKwYBBQUHAwMwXQYDVR0B
# BFYwVIAQBiYBz3Bn/wK9+DDw0H+Xs6EuMCwxKjAoBgNVBAMTIVBvd2VyU2hlbGwg
# TG9jYWwgQ2VydGlmaWNhdGUgUm9vdIIQH7UbGw1fDadOf3Ie6agmETAJBgUrDgMC
# HQUAA4IBAQBRECaQ9ibBsNindMtSkmSqC+dyTsplxZ08QO/aYbvKnKVpmeKxI8fB
# 7S5i751SBAvrVhYTs1BH5vNuA3NuHZYDeltoUxuYJP/yccXt0vgpFGLtfocfTGG5
# DyIMj2lXFFAnQgTgBigisSh9r8qpTB4DBUZY/DMMzdIsfCU3tNgtSnzjQsX05lev
# luOFaeukKdK+OydvARPIsBPuXKwuzBj3AGcIPjIP3GCcidilwMoS2Skl1pQg5fDu
# WuTv2hlNDcGjqnbbAJeYFC36yAATeAAfmh54CzUxb8o608lKV+JSs3q4K9R6Pb4m
# 75BP7vyWylsMl9MUAnLt3blPhi/Cb2mAMYIB4TCCAd0CAQEwQDAsMSowKAYDVQQD
# EyFQb3dlclNoZWxsIExvY2FsIENlcnRpZmljYXRlIFJvb3QCEEegigDl7cKgQ3I9
# h/C37+YwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJ
# KoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQB
# gjcCARUwIwYJKoZIhvcNAQkEMRYEFChbwq3qV052cR1PWoG7oPkIU8wPMA0GCSqG
# SIb3DQEBAQUABIIBABQe/scsk9m+CW+Pyqj5XqUHbKzMULs9+Y69kkIcPaVKqCho
# WncNpbj1h5eRhwBzNdpBBqEjFbh1Ow23e71ngyzpY5mB0pPzif+8NR/J1awVrHxg
# h7QammIjh/aogkdFXMAoS9V2PJ5rg8Kyph3/0teOXRvakhiV5pMZhY4eS0QlLtqY
# 8okVjTOre/5E/obQsgeL4vVrba6K+HoQfCvxogiDmwXFp7ayEEMdavnHdaBjkjv4
# 7moIHkryLbQcAEH7l3R0UTTqSaQ2elZnMsTMriSJz3alnGLJDcumW0pq9BYZXB2G
# OhoACiFVS0EYvbA1+Igw1wLfWk8i/SYNUybRC94=
# SIG # End signature block
