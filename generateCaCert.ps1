# Connect to Azure
Connect-AzAccount

###############################
# Variables                   #
###############################

$ca = "Your-CA-Server" #change to your CA server
$certificateTemplate = "Your-Certificate-Template-name" #change to the name of your Certificate template name on CA

$tenantId = (Get-AzTenant).Id
$subject = "CN=$tenantId,OU=Microsoft NPS Extension" 
$certFilePath = "$env:TEMP\newcert.cer"

###############################
# Generate new Certificate    #
############################### 


# Content of new Certificate
$infContent = @"
[Version]
Signature="$Windows NT$"

[NewRequest]
Subject = "$subject" 
KeySpec = 1
KeyLength = 2048
Exportable = TRUE
MachineKeySet = TRUE
SMIME = False
PrivateKeyArchive = FALSE
UserProtected = FALSE
UseExistingKeySet = FALSE
ProviderName = "Microsoft RSA SChannel Cryptographic Provider"
ProviderType = 12
RequestType = PKCS10
KeyUsage = 0xa0

[RequestAttributes]
CertificateTemplate = "$certificateTemplate"
"@

# Write the .inf content to a file
$infContent | Out-File -FilePath "$env:TEMP\certrequest.inf" -Encoding ascii

# Generate a certificate signing request (CSR)
certreq -new -machine "$env:TEMP\certrequest.inf" "$env:TEMP\certrequest.csr" 

# Submit the CSR to the CA and save the issued certificate to a .cer file
certreq -submit -AdminForceMachine -config $ca "$env:TEMP\certrequest.csr" $certFilePath
