using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.Extensions.Configuration;

namespace WebApplication1.Pages
{
    public class IndexModel : PageModel
    {
        private readonly IConfiguration _configuration;

        public IndexModel(IConfiguration configuration)
        {
            _configuration = configuration;
        }

        public string ConnectionString { get; set; }

        public void OnGet()
        {
            this.ConnectionString = _configuration.GetSection("ConnectionStrings")["BlobStorage"];
        }
    }
}
