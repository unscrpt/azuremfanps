# Connect to Azure
Connect-AzAccount

###############################
# Variables                   #
###############################

$tenantId = (Get-AzTenant).Id
$certFilePath = "Your-New-Certificate"

###############################
# Upload Certificate to Azure #
###############################

# Specify the service principal and the certificate
$servicePrincipal = Get-AzADServicePrincipal -SearchString "Azure Multi-Factor Auth Client"
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
$cert.Import($certFilePath)
$certBase64 = [System.Convert]::ToBase64String($cert.GetRawCertData())
$oldcertificate = Get-AzADServicePrincipalCredential -ObjectId $servicePrincipal.Id

#Delete old certificate
if ($oldcertificate) {
    Write-Host ("Deleting old certificate")
    Remove-AzADServicePrincipalCredential -ObjectId $servicePrincipal.Id -KeyId $oldcertificate.KeyId
}

#Upload new certificate
Write-Host ("Uploading new certificate")
New-AzADServicePrincipalCredential -ObjectId $servicePrincipal.Id -CertValue $certBase64 

###############################
# Update MFA settings         #
###############################

$user='NETWORK SERVICE'
$permission='Read'

Write-Host ("Starting registry updates")

Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\AzureMfa\" -Name "CLIENT_CERT_IDENTIFIER" -VALUE $cert.Subject
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\AzureMfa\" -Name "TENANT_ID" -VALUE $tenantId
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\AzureMfa\" -Name "OVERRIDE_NUMBER_MATCHING_WITH_OTP" -VALUE "FALSE" # needed when used with remote desktop gateway

Write-Host ("Completed registry updates")

Write-Host ("Client certificate : " + $subject + " successfully associated with Azure MFA NPS Extension for Tenant ID: " + $tenantId )

$installedCert = Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Thumbprint -eq $cert.GetCertHashString() }

#set permissions for certificate private key
try
{
	# Get Location of the machine related keys
	$keyPath = $env:ProgramData + "\Microsoft\Crypto\RSA\MachineKeys\"; 
    $keyName = $installedCert.PrivateKey.CspKeyContainerInfo.UniqueKeyContainerName
	$keyFullPath = $keyPath + $keyName;
	#Get the current access levels and update it
	$acl = (Get-Item $keyFullPath).GetAccessControl('Access') 
	$buildAcl = New-Object  System.Security.AccessControl.FileSystemAccessRule($user,$permission,"Allow") 
	$acl.SetAccessRule($buildAcl) #Add Access Rule

	Write-Host "Granting certificate private key access to $user"
	Set-Acl $keyFullPath $acl #Save Access Rules
	
	Write-Host "Successfully granted to $user"
}
catch
{
	Write-Host "Unable to grant certificate private key access to $user. Please grant access manually." 
	throw $_;
}


Write-Host ("Restarting Network Policy Server (ias) service")
Restart-Service -Force ias 
