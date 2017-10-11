using System;
using System.Configuration;
using System.Security.Cryptography.X509Certificates;
using System.Threading.Tasks;
using Microsoft.Azure.KeyVault;
using Microsoft.Azure.KeyVault.Models;
using Microsoft.IdentityModel.Clients.ActiveDirectory;

public static async Task<string> GetKeyVaultSecret(string secretNode)
{
    var vaultUrl = ConfigurationManager.AppSettings["KeyVault.Url"];
    var secretUri = $"{vaultUrl}secrets/{secretNode}";
    
    var keyVaultClient = new KeyVaultClient(new KeyVaultClient.AuthenticationCallback(GetAccessToken));

    string value = null;
    try 
    {
        value = (await keyVaultClient.GetSecretAsync(secretUri)).Value;
    }
    catch (KeyVaultErrorException ex) 
    {
        if (!ex.Message.StartsWith("Secret not found")) 
        {
            throw;
        }
    }

    return value;
}

private static async Task<string> GetAccessToken(string authority, string resource, string scope)
{
    var authContext = new AuthenticationContext(authority);
    
    var clientId = ConfigurationManager.AppSettings["KeyVault.ClientId"];
    var thumbprint = ConfigurationManager.AppSettings["KeyVault.Thumbprint"];

    var certificate = GetCert(clientId, thumbprint);

    var result = await authContext.AcquireTokenAsync(resource, certificate);
    if (result == null)
    {
        throw new InvalidOperationException("Failed to obtain the JWT token");
    }
    
    return result.AccessToken;
}

private static ClientAssertionCertificate GetCert(string applicationId, string thumbprint)
{
    var clientAssertionCertPfx = FindCertificateByThumbprint(thumbprint);
    
    return new ClientAssertionCertificate(applicationId, clientAssertionCertPfx);
}

private static X509Certificate2 FindCertificateByThumbprint(string findValue)
{
    X509Store store = new X509Store(StoreName.My, StoreLocation.CurrentUser);
    try
    {
        store.Open(OpenFlags.ReadOnly);
        X509Certificate2Collection col = store.Certificates.Find(X509FindType.FindByThumbprint, findValue, false);
        if (col == null || col.Count == 0)
        {
            return null;
        }
        return col[0];
    }
    finally
    {
        store.Close();
    }
}