clear

# Cleanup
Get-AzureRmADAppCredential -ApplicationId $applicationId | Remove-AzureRmADAppCredential -ApplicationId $applicationId -Force

$webApp = Get-AzureRmWebApp -ResourceGroupName $resourceGroup `
                            -Name $webAppName

$appSettings = [ordered]@{}
$webapp.SiteConfig.AppSettings `
    | ? { $_.Name -notlike 'KeyVault.*' -and $_.Name -ne "WEBSITE_LOAD_CERTIFICATES"} `
    | % { $appSettings[$_.Name] = $_.Value }

$webApp = Set-AzureRmWebApp -ResourceGroupName $resourceGroup `
                            -Name $webAppName `
                            -AppSettings $appSettings

Remove-AzureKeyVaultManagedStorageSasDefinition -VaultName $vaultName -AccountName MSAKV01 -Name BlobSAS1 -Force
Remove-AzureKeyVaultManagedStorageSasDefinition -VaultName $vaultName -AccountName MSAKV01 -Name BlobSAS2 -Force
Remove-AzureKeyVaultManagedStorageSasDefinition -VaultName $vaultName -AccountName MSAKV01 -Name BlobSAS3 -Force

Remove-AzureKeyVaultManagedStorageAccount -VaultName $vaultName -Name MSAKV01 -Force

Remove-AzureRmRoleAssignment -ObjectId $vaultPrincipalId -Scope $storageId `
                             -RoleDefinitionName "Storage Account Key Operator Service Role"

Get-AzureRmKeyVault -VaultName $vaultName `
           | Select -ExpandProperty AccessPolicies `
           | ? { $_.DisplayName -like 'YOUR-AZURE-AD-APP-NAME*' } `
           | Remove-AzureRmKeyVaultAccessPolicy -VaultName $vaultName
