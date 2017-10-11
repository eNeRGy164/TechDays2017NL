clear

# Setup
$vaultPrincipalId = Get-AzureRmADServicePrincipal -SearchString "Azure Key Vault" `
                                         | Select -ExpandProperty Id

$storageId = Get-AzureRmStorageAccount -Name $storageName -ResourceGroupName $storageResourceGroup `
                              | Select -ExpandProperty Id

# Add Azure Key Vault als Key Operator
New-AzureRmRoleAssignment -ObjectId $vaultPrincipalId -Scope $storageId `
                          -RoleDefinitionName "Storage Account Key Operator Service Role"

# Add Managed Storage Account
Add-AzureKeyVaultManagedStorageAccount -VaultName $vaultName `
                                       -Name MSAKV01 `
                                       -AccountResourceId $storageId `
                                       -ActiveKeyName key2 `
                                       -RegenerationPeriod "30.00:00:00"

# Show Current Storage Keys
Get-AzureRmStorageAccountKey -Name $storageName -ResourceGroupName $storageResourceGroup

# Update a Storage Key from Key Vault
Update-AzureKeyVaultManagedStorageAccountKey -VaultName $vaultName `
                                             -AccountName MSAKV01 `
                                             -KeyName key2 `
                                             -Force

# Show changed Key
Get-AzureRmStorageAccountKey -Name $storageName -ResourceGroupName $storageResourceGroup

# Add SAS Definitions
Set-AzureKeyVaultManagedStorageSasDefinition -Service Blob `
                                             -ResourceType Container,Service `
                                             -VaultName $vaultName `
                                             -AccountName MSAKV01 `
                                             -Name BlobSAS1 `
                                             -Protocol HttpsOnly `
                                             -ValidityPeriod "01.00:00:00" `
                                             -Permission Read,List

Set-AzureKeyVaultManagedStorageSasDefinition -Service Blob `
                                             -ResourceType Container,Service,Object `
                                             -VaultName $vaultName `
                                             -AccountName MSAKV01 `
                                             -Name BlobSAS2 `
                                             -Protocol HttpsOnly `
                                             -ValidityPeriod "01.00:00:00" `
                                             -Permission Read,List,Write

# Create SAS Tokens 
$sasToken1 = Get-AzureKeyVaultSecret -VaultName $vaultName -SecretName MSAKV01-BlobSAS1 `
                            | Select -ExpandProperty SecretValueText
$sasToken2 = Get-AzureKeyVaultSecret -VaultName $vaultName -SecretName MSAKV01-BlobSAS2 `
                            | Select -ExpandProperty SecretValueText

# Create Storage Context based on SAS Tokens
$context1 = New-AzureStorageContext -SasToken $sasToken1 -StorageAccountName $storageName
$context2 = New-AzureStorageContext -SasToken $sasToken2 -StorageAccountName $storageName

# Upload file, Should not be allowed
Set-AzureStorageBlobContent -Container container -File nocontent.txt -Context $context1

# Upload file, Should be allowed
Set-AzureStorageBlobContent -Container container -File nocontent.txt -Context $context2 -Force

# Create a very short-lived SAS Token that can only read blobs
Set-AzureKeyVaultManagedStorageSasDefinition -Service Blob `
                                             -ResourceType Object `
                                             -VaultName $vaultName `
                                             -AccountName MSAKV01 `
                                             -Name BlobSAS3 `
                                             -Protocol HttpsOnly `
                                             -ValidityPeriod "00.00:00:10" `
                                             -Permission Read

$sasToken3 = Get-AzureKeyVaultSecret -VaultName $vaultName -SecretName MSAKV01-BlobSAS3 `
                            | Select -ExpandProperty SecretValueText
$context3 = New-AzureStorageContext -SasToken $sasToken3 -StorageAccountName $storageName

Get-AzureStorageBlobContent -Container container -Blob nocontent.txt -Context $context3 -Force