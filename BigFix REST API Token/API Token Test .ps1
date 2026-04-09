# --- DEFENSIVE NETWORKING FIXES (Same as your working script) ---
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13
[System.Net.ServicePointManager]::Expect100Continue = $false

Add-Type @"
    using System.Net;
    using System.Net.Security;
    using System.Security.Cryptography.X509Certificates;
    public class SSLHandler {
        public static void Bypass() {
            ServicePointManager.ServerCertificateValidationCallback = 
                (sender, cert, chain, sslPolicyErrors) => true;
        }
    }
"@
[SSLHandler]::Bypass()

# --- NEW TOKEN AUTHENTICATION ---
$MyToken = "<token>"

# IMPORTANT: In BigFix 11.0.6, the header uses 'Bearer' 
$Headers = @{ 
    "Authorization" = "Bearer $MyToken" 
    "Accept"        = "application/xml"
}

# --- THE COMMAND ---
$BigFixServer = "https://<fqdn>:52311"
$SitesUrl     = "$BigFixServer/api/sites"

try {
    $SitesResponse = Invoke-RestMethod -Uri $SitesUrl -Method Get -Headers $Headers -DisableKeepAlive
    $SitesResponse.BESAPI # Should now work without a password!
}
catch {
    Write-Error "Token Request Failed: $($_.Exception.Message)"
}