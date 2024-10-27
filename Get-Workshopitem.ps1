[CmdletBinding()]
param (
  [Parameter(HelpMessage="The ID for the workshop item.",Mandatory=$true)]
  [string]
  $WorkshopId
)

if ($null -eq $WorkshopId)
{
  Write-Output -NoEnumerate -InputObject 1;
}

Import-Module PowerHTML

$WorkshopItemUri = 'https://steamcommunity.com/sharedfiles/filedetails/?id='+$WorkshopId

$Response = ConvertFrom-Html -Uri $WorkshopItemUri

if ($null -ne ($Response.SelectNodes('//h1') | Where-Object { $_.InnerTest -eq "Sorry!" }))
{
  $SteamID_b = (($Response.SelectNodes('//a[class="apphub_sectionTab"]') | Where-Object { $_.SelectNodes('//span') | Where-Object { $_.InnerText -eq "All" }})[0]);
  $SteamID =  $SteamID_b.GetAttributeValue("href", "").Replace('https://steamcommunity.com/app/','');
}