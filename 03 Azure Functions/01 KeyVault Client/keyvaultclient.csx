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
    var clientSecret = ConfigurationManager.AppSettings["KeyVault.ClientSecret"];

    var clientCred = new ClientCredential(clientId, clientSecret);

    var result = await authContext.AcquireTokenAsync(resource, clientCred);
    if (result == null)
    {
        throw new InvalidOperationException("Failed to obtain the JWT token");
    }
    
    return result.AccessToken;
}