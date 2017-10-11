#load "keyvaultclientwithcert.csx"
#r "Microsoft.WindowsAzure.Storage"

using System.Net;
using Microsoft.WindowsAzure.Storage;
using Microsoft.WindowsAzure.Storage.Auth;
using Microsoft.WindowsAzure.Storage.Blob;

public static async Task<HttpResponseMessage> Run(HttpRequestMessage req, TraceWriter log)
{
    log.Info("C# HTTP trigger function processed a request.");

    //var storageAccount = CloudStorageAccount.Parse(ConfigurationManager.AppSettings["StorageConnectionString"]);
    //var blobClient = storageAccount.CreateCloudBlobClient();

    var secretValue = await GetKeyVaultSecret("MSAKV01-BlobSAS3");

    var accountSasCredential = new StorageCredentials(secretValue); 

    var blobClient = new CloudBlobClient(new Uri("https://techdaysnl.blob.core.windows.net/"), accountSasCredential); 

    var container = blobClient.GetContainerReference("container");
    var blob = container.GetBlockBlobReference("nocontent.txt");

    var content = await blob.DownloadTextAsync();

    return req.CreateResponse(HttpStatusCode.OK, $"Hello {content}");
}
