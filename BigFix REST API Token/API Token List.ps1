# --- 1. NETWORKING & AUTH SETUP ---
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12 -bor [System.Net.SecurityProtocolType]::Tls13
[System.Net.ServicePointManager]::Expect100Continue = $false

if (-not ([System.Management.Automation.PSTypeName]'SSLHandler').Type) {
    Add-Type @"
        using System.Net;
        using System.Net.Security;
        using System.Security.Cryptography.X509Certificates;
        public class SSLHandler {
            public static void Bypass() {
                ServicePointManager.ServerCertificateValidationCallback = (sender, cert, chain, sslPolicyErrors) => true;
            }
        }
"@
}
[SSLHandler]::Bypass()

$BigFixServer = "https://<fqdn>:52311"
$Token = "<token>"
$Headers = @{ 
    "Authorization" = "Bearer $Token"
    "Accept"        = "application/json"
}

# 1. FETCH USERS (XML HANDLING)
$QueryUrl = "$BigFixServer/api/query?relevance=(names%20of%20it,%20ids%20of%20it)%20of%20bes%20users"

try {
    # We use Invoke-RestMethod; if it returns XML, PS treats it as an [XmlDocument]
    $response = Invoke-RestMethod -Uri $QueryUrl -Method Get -Headers $Headers
    
    # Drill down into the XML: Query -> Result -> Tuple
    $tuples = $response.BESAPI.Query.Result.Tuple
}
catch {
    Write-Error "Failed to fetch users: $($_.Exception.Message)"
    exit
}

# 2. LOOP THROUGH TUPLES
$ResultsTable = New-Object System.Collections.Generic.List[PSObject]

foreach ($tuple in $tuples) {
    # In your XML, Answer[0] is Name (string), Answer[1] is ID (integer)
    $UName = $tuple.Answer[0].'#text'
    $UID   = $tuple.Answer[1].'#text'

    try {
        # Fetch tokens for this specific UID
        $TokenUrl = "$BigFixServer/api/tokens/user/$UID"
        # Force JSON for the token endpoint as it's cleaner to parse
        $TokenHeaders = $Headers.Clone()
        $TokenHeaders["Accept"] = "application/json"
        
        $TokenData = Invoke-RestMethod -Uri $TokenUrl -Method Get -Headers $TokenHeaders
        
        # Parse the Tokens array from the JSON response
        if ($TokenData.Tokens -and $TokenData.Tokens.Count -gt 0) {
            foreach ($T in $TokenData.Tokens) {
                $ResultsTable.Add([PSCustomObject]@{
                    ID              = $UID
                    Username        = $UName
                    TokenID         = $T.Id
                    TokenExpiration = if ($null -eq $T.Expiration) { "Non-Expiring" } else { $T.Expiration }
                })
            }
        }
        else {
            $ResultsTable.Add([PSCustomObject]@{
                ID              = $UID
                Username        = $UName
                TokenID         = "None"
                TokenExpiration = "N/A"
            })
        }
    }
    catch {
        # This usually triggers if the user doesn't have permissions to view other users' tokens
        Write-Warning "Could not fetch tokens for $UName (ID: $UID)"
    }
}

# 3. OUTPUT AS TABLE
$ResultsTable | Format-Table -AutoSize
# Export to CSV
$ResultsTable | Export-Csv -Path "C:\Windows\Temp\BigFixTokens.csv" -NoTypeInformation
Write-Host "`nReport exported to BigFixTokens.csv" -ForegroundColor Green