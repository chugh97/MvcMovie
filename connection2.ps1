
Function getCredentials {
	# if Env variable not found it set the output of $shell to null
	$shell = (Get-ChildItem Env:AZURE_HTTP_USER_AGENT).Value  2>$null 3>$null

	if ($shell -eq "" -or $null -eq $shell ) {
		Write-Host "Running under PS Core"	
	}
	else {
			Write-Host " "
			Write-Host "Running under Azure Cloud Shell, bypassing login/connect processing"
			if ($null -eq $subscription -or $subscription -eq "") {
					return
			}
			setSubscription
			return
	}

	# Just need to check one of the service principal variables to assume it is valid
	if ($null -ne $clientid -and $clientid -ne "") {
			if ($trace -eq $true) {
					Write-Host "Attempting to connect with submitted credentials:"
					Write-Host "    clientid: $clientid"
					Write-Host "    clientkey: $clientkey"
					Write-Host "    tenantid: $tenantid"
			}

			$error.Clear()

			$passwd = ConvertTo-SecureString $clientkey -AsPlainText -Force
			$pscredential = New-Object System.Management.Automation.PSCredential($clientid, $passwd)
			Connect-AzAccount -ServicePrincipal -Credential $pscredential -TenantId $tenantid

			if ($error) {
					Write-Host "Unable to connect to Azure. Check your Service Principal variables to ensure they are correct and valid." -ForegroundColor Red
					exit
			}
			else {
					Write-Host " "
					Write-Host "Connected to Azure with submitted Service Principal." -ForegroundColor Green
					if ($null -eq $subscription -or $subscription -eq "") {
						return
					}
					setSubscription
					return
			}
	}
	# check if we are currently connected and use that if possible
	$currentLogin = (Get-AzContext).Account.Id
	if ($currentLogin -ne "" -and $null -ne $currentLogin) {
			Write-Host "Running with current logged on account" -ForegroundColor Green
			if ($null -eq $subscription -or $subscription -eq "") {
					return
			}
			setSubscription
			return
	}
	# apparently no other connection options are available, so force an Azure connect
	Connect-AzAccount
	$currentLogin = (Get-AzContext).Account.Id
	if ($currentLogin -eq "" -or $null -eq $currentLogin) {
			Write-Host "Unable to determine connection status.  Please re-run and connect with valid credentials." -ForegroundColor Red
			exit  
	}
	$subscriptionId = Read-Host "Please enter the subscriptionID"
	if ($null -ne $subscriptionId -and $subscriptionId -ne "") {
			Select-AzSubscription -Subscription  "$subscriptionId"
	}
	else {
			Write-Host "Unable to determine the subscription required.  Please re-run and submit valid subscription when prompted." -ForegroundColor Red
			exit
	}
}

Function setSubscription {
	   # If subscription was not entered, then we don't need to be here 
	if ($null -eq $subscription -or $subscription -eq "") {
			# Get subscription ID that we are currently running under
			$subscription_id = Get-AzContext
			# Check if more than one subscription has been returned.
			$subscriptionCheck = $subscription_id.Subscription -split ' '
			if ($subscriptionCheck.Count -gt 1) {
					Write-Host " "
					Write-Host "Multiple subscriptions found.  Please run again with '-subscription' parameter to set a default subscription" -ForegroundColor Red
					Exit
			}
			return
	}
	$found = $false
	# Get all subscriptions we currently have access to           
	$subscriptions = Get-AzContext -ListAvailable
	$subscriptions.Name | ForEach-Object {
			$sub = ($_ -split "\(|\)")[1]
			if ($trace -eq $true) {
				Write-Host "subscriptionId $sub"
			}
			if ($sub -eq $subscription) {
				$found = $true									
			}
	}		

	if ($found -eq $true) {
		Write-Host " "
		Write-Host "Setting connection subscription to: $subscription"
		Select-AzSubscription -Subscription  "$subscription"
	}
	else {
		Write-Host "Requested subscription $subscription is not contained in your connection context" -ForegroundColor Red                
		Exit
	}
}

