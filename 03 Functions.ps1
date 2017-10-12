clear

# Get the Azure AD app
$application = Get-AzureRmADApplication -DisplayNameStartWith "YOUR-AZURE-AD-APP-NAME"
$applicationId = $application.ApplicationId

# Current App Credentials
Get-AzureRmADAppCredential -ApplicationId $applicationId

# Update Function app AppSettings
$webApp = Get-AzureRmWebApp -Name $webAppName -ResourceGroupName $webAppResourceGroup

$appSettings = [ordered]@{}
$webapp.SiteConfig.AppSettings | % { $appSettings[$_.Name] = $_.Value }

$appSettings["KeyVault.Url"] = "https://$vaultName.vault.azure.net/"
$appSettings["KeyVault.ClientId"] = "$applicationId"
$appSettings["KeyVault.ClientSecret"] = "YOUR-GENERATED-KEY"

$webapp = Set-AzureRmWebApp -Name $webAppName -ResourceGroupName $webAppResourceGroup `
                            -AppSettings $appSettings



# Certificate subject
$fqdn = "keyvaultaccess.techdays2017.tld"

# New certificate
$newCert = New-SelfSignedCertificate -CertStoreLocation cert:\CurrentUser\my `
            -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider" `
            -Subject "cn=$fqdn" `
            -NotBefore ([DateTime]::Today) `
            -NotAfter ([DateTime]::Today).AddYears(2)

$newCert | Format-List

# Password
$plainPassword = "YOUR_RANDOM_PASSWORD"
$password = ConvertTo-SecureString $plainPassword -Force -AsPlainText

# Export as PFX
Export-PfxCertificate -Cert "cert:\CurrentUser\my\$($newCert.Thumbprint)" `
                      -FilePath "$PWD\$fqdn.pfx" `
                      -Password $password

# Export as CRT
Export-Certificate -Cert "cert:\CurrentUser\my\$($newCert.Thumbprint)" `
                   -FilePath "$PWD\$fqdn.crt"

# Get certificate as object
$cer = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
$cer.Import("$PWD\$fqdn.crt")
$certValue = [System.Convert]::ToBase64String($cer.GetRawCertData())

# Add certificate as credentials to Azure AD app
New-AzureRmADAppCredential -ApplicationId $applicationId `
                           -CertValue $certValue `
                           -StartDate $cer.NotBefore `
                           -EndDate $cer.NotAfter

# Current App Credentials
Get-AzureRmADAppCredential -ApplicationId $applicationId

# Add PFX to web application, will throw error
New-AzureRmWebAppSSLBinding -WebAppName loremipsum `
                            -ResourceGroupName loremipsum `
                            -Name $fqdn `
                            -CertificateFilePath "$PWD\$fqdn.pfx" `
                            -CertificatePassword $plainPassword

# Add Thumbprint and Remove ClientSecret
$webApp = Get-AzureRmWebApp -Name $webAppName -ResourceGroupName $webAppResourceGroup

$appSettings = [ordered]@{}
$webapp.SiteConfig.AppSettings `
        | ? { $_.Name -ne "KeyVault.ClientSecret" } `
        | % { $appSettings[$_.Name] = $_.Value }

$appSettings["WEBSITE_LOAD_CERTIFICATES"] = $cer.Thumbprint
$appSettings["KeyVault.Thumbprint"] = $cer.Thumbprint

$webapp = Set-AzureRmWebApp -Name $webAppName -ResourceGroupName $webAppResourceGroup `
                            -AppSettings $appSettings
