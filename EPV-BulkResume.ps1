$baseURI = "https://cyberarkdemo.com"
$servers = Get-Content resumeServers.txt
$safe = "SAFE_NAME"

Function EPV-Login {
	$user = Read-Host
	$pass = Read-Host
	
	Write-Host "Logging In..." -NoNewLine
	
	$data = @{
		username=$user
		password=$pass
		useRadiusAuthentication=$false
	}
	
	$loginData = $data | ConvertTo-Json
		
	$ret = Invoke-RestMethod -Uri "$baseURI/PasswordVault/WebServices/auth/Cyberark/CyberArkAuthenticationService.svc/Logon" -Method POST -Body $loginData -ContentType 'application/json'
	
	Write-Host "Done!"
	
	return $ret
}

Function EPV-Logoff {
	Write-Host "Logging Off..." -NoNewLine
	$ret = Invoke-RestMethod -Uri "$baseURI/PasswordVault/WebServices/auth/Cyberark/CyberArkAuthenticationService.svc/Logoff" -Method POST -Headers $header -ContentType 'application/json'
	Write-Host "Done!"
}

Function EPV-GetAccountDetails {
	Param(
		[string]$Account,
		[string]$Safe
	)

	Write-Host "Getting account details..." -NoNewLine
	$ret = Invoke-RestMethod -Uri "$baseURI/PasswordVault/WebServices/PIMServices.svc/Accounts?Keywords=$Account&Safe=$Safe" -Method GET -Headers $header -ContentType 'application/json'
	Write-Host "Done!"

	return $ret.accounts.AccountID
}

Function EPV-ChangeCredentials {
	Param(
		[string]$AccountID
	)

	Write-Host "Resuming acocunt..." -NoNewline

	$header.Add("ImmediateChangeByCPM", "Yes")
	$ret = Invoke-RestMethod -Uri "$baseURI/PasswordVault/WebServices/PIMServices.svc/Accounts/$AccountID/ChangeCredentials" -Method Put -Headers $header -ContentType 'application/json'
	$header.Remove("ImmediateChangeByCPM") | Out-Null

	Write-Host "Done!"
}

$login = EPV-Login
$header = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$header.Add("Authorization", $login.CyberArkLogonResult)

ForEach ($server in $servers) {
	Write-Host $server -ForegroundColor Yellow

	$acctID = EPV-GetAccountDetails -Account $SID -Safe $safe

	EPV-ChangeCredentials -AccountID $acctID
}

EPV-Logoff
