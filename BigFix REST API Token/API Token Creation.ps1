# ==============================================================================
# BigFix REST API - Unified Targeting Report with Group Resolution & Counts
# ==============================================================================

$BigFixServer = "https://<fqdn>:52311"
$Username     = "<username>"
$Password     = "<password>"

# --- DEFENSIVE NETWORKING FIXES ---
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls13
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

$AuthBytes  = [System.Text.Encoding]::UTF8.GetBytes("${Username}:${Password}")
$AuthHeader = [Convert]::ToBase64String($AuthBytes)
$Headers    = @{ "Authorization" = "Basic $AuthHeader" }

# Use your working Basic Auth Headers from the other script
$TokenName = "MyNewPowerShellToken"
$CreateUrl = "$BigFixServer/api/token?name=$TokenName&duration=0"

try {
    # We POST using Basic Auth to GET the token
    $TokenJSON = Invoke-RestMethod -Uri $CreateUrl -Method Post -Headers $Headers
    Write-Host "--- SAVE THIS TOKEN ---" -ForegroundColor Cyan
    Write-Host $TokenJSON.Token -ForegroundColor Yellow
    # This string usually looks like: cGt2PxRXAX...AAAAE
}
catch {
    Write-Error "If this fails with 401/404, check username and password."
}