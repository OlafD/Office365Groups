param (
	[Parameter(Mandatory=$true)]
    [string]$Url,
	[Parameter(Mandatory=$true)]
	$Credential
)

function MakeSiteName()
{
	param (
		$Name
	)

	$result = $Name

	$pattern = "[^a-zA-Z0-9-]"

	$result = $result -replace $pattern, ""

	return "/sites/$result"
}

Connect-SPOService -Url $Url -Credential $Credential

Write-Host "Connected to $Url"

$Url = $Url.ToLower().Replace("-admin", "")

Write-Host "Connecting to Exchange Online"

$exchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $Credential -Authentication Basic -AllowRedirection

Import-PSSession $exchangeSession | Out-Null

Write-Host "Connected to Exchange Online"

Write-Host "Start processing..."

$collection = @()

$exchangeGroups = Get-UnifiedGroup -ResultSize unlimited
$count = $exchangeGroups.Count
Write-Host "$count groups found in Exchange Online"
Write-Host

$i = 1

foreach ($exchangeGroup in $exchangeGroups)
{
	$progress = $i * 100 / $count
	$progress = [int]$progress

	Write-Host -NoNewline "`rProgress: $progress%"

	$i++

	$groupName = $exchangeGroup.DisplayName
	$siteUrl = $exchangeGroup.SharePointSiteUrl
	
	if ($siteUrl -ne "") 
	{
		Try
		{
			$site = Get-SPOSite $siteUrl -ErrorAction SilentlyContinue

			if ($site -ne $null)
			{
				$object = New-Object System.Object

				$quota = $site.StorageQuota

				$object | Add-Member -MemberType NoteProperty -Name "GroupName" -Value $groupName
				$object | Add-Member -MemberType NoteProperty -Name "SiteUrl" -Value $siteUrl
				$object | Add-Member -MemberType NoteProperty -Name "StorageQuota" -Value $quota

				$collection += $object

				# Write-Host "$siteUrl`t$quota"
			}
		}
		Catch
		{
			# do nothing
		}
	}
}

Write-Host "`rProgress: 100%"

Remove-PSSession $exchangeSession

Write-Host "Disconnected from Exchange Online"

$collection
