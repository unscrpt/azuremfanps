# Azure MFA for NPS Certificate Powershell
The Powershell script's in this repository should help you automate the certificate renewal of the Azure service principal for Azure Multi-Factor Auth Client.
I had to renew the certificate for a customer after it has expired and the MFA authentication for the Remote Desktop Gateway failed. This was stopping the user from login into their Remote Desktop Session.

With these script's you will not create a self-signed certificate but a CA signed certificate. This should also help you keep track of the expiration date of the certificate. If you want the NPS extension just to work without the hassle of creating a CA and signing certificates you can also just run the script located at c:\Program Files\Microsoft\AzureMfa\Config\AzureMfaNpsExtnConfigSetup.ps1 and create a self-signed certificate.

The script in this repo are meant to be used with the Network Policy Server (NPS) extension mentioned [here] (https://learn.microsoft.com/en-us/azure/active-directory/authentication/howto-mfa-nps-extension)

## What do these Powershell script's do
The script generateCaCert.ps1 request's a new certificate from your Certificate Authority (CA). The certificate has to match the subject in the script, othwerise it will not work. The certificate can then be approved on the CA and be downloaded and installed on the NPS server with the extension installed.

The script azureMfaCertUpdate.ps1 deletes the old certificate linked to the service principal and uploads the new one. It also updates the configuration of the NPS extension and sets the correct permissions on the private key of the certificate.

## Why are there two script's and not everything is done in one go?
The script's are separated because it's best practice to manually approve a certificate with a customized subject, to reduce the risks of abusing this capability and creating fake certificate's and starting man-in-the-middle attacks on your domain joined computers.

## Troubleshooting
I also installed the newest version of the Azure MFA NPS extension. The newest extensions changes the MFA method to TOTP. Remote Desktop Gateway doesn't support this MFA method and fails the authentication. Because of this the Registry String OVERRIDE_NUMBER_MATCHING_WITH_OTP must be set in the azureMfaCertUpdate.ps1 script. This is also documented [here] (https://learn.microsoft.com/en-us/azure/active-directory/authentication/how-to-mfa-number-match)

## License
[GPLv3] (https://choosealicense.com/licenses/gpl-3.0/)


