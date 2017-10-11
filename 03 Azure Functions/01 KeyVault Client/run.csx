#load "keyvaultclient.csx"

using System.Net;

public static async Task<HttpResponseMessage> Run(HttpRequestMessage req, TraceWriter log)
{
    log.Info("C# HTTP trigger function processed a request.");

    var secretValue = await GetKeyVaultSecret("VerySecret");

    return req.CreateResponse(HttpStatusCode.OK, $"Hello {secretValue}");
}
