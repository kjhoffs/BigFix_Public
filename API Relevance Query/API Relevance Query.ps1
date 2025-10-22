$key_dir = "C:\Users\kjhoffs\Documents\BF_Password_Updates\" # Location of the key.txt and output file
$key_file = "key.txt"
$passwd_file = "tdbfserver1.txt"

$input_dir = "C:\Users\kjhoffs\Documents\API Relevance Query\input\"
$output_dir = "C:\Users\kjhoffs\Documents\API Relevance Query\output\"

if ( -Not ( Test-Path ${output_dir} ) ) {
    New-Item -Path ${output_dir} -ItemType Directory | Out-Null
}

$relevance_file = "relevance.txt"

#To Address Cert issues

add-type @"
  using System.Net;
  using System.Security.Cryptography.X509Certificates;
  public class TrustAllCertsPolicy : ICertificatePolicy {
      public bool CheckValidationResult(
          ServicePoint srvPoint, X509Certificate certificate,
          WebRequest request, int certificateProblem) {
          return true;
      }
  }
"@

#$AllProtocols = [System.Net.SecurityProtocolType]"Ssl3,Tls,Tls11,Tls12,TLS13"
$AllProtocols = [System.Net.SecurityProtocolType]"TLS13"
[System.Net.ServicePointManager]::SecurityProtocol = ${AllProtocols}
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

$server = "tdbfserver1.tdbigfix.lab" # Root Server address
$urlbase = "https://${server}:52311/api/" #May need to change port if not using 52311

# Retrieve encrypted password

$username = "bfapiuser" #console login
$EncryptionKeyFile = ( ${key_dir} + ${key_file} )
$password = Get-Content ( ${key_dir} + ${passwd_file} ) | ConvertTo-SecureString -Key (Get-Content -path ${EncryptionKeyFile})

$BSTRP = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR(${password})
$password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(${BSTRP})

$EncodedAuthorization = [System.Text.Encoding]::UTF8.GetBytes(${username} + ':' + ${password})
$EncodedPassword = [System.Convert]::ToBase64String(${EncodedAuthorization})

$headers = @{"Authorization"="Basic $(${EncodedPassword})"}


$query_string_unencoded = Get-Content -Path ( $input_dir + $relevance_file )

$query_string = [uri]::EscapeDataString(${query_string_unencoded})
$query = "query?relevance=${query_string}"
$url = ${urlbase} + ${query}

$response = Invoke-RestMethod -Uri $url -Method GET -Headers $headers -ContentType 'application/xml'

Out-File -FilePath "${output_dir}\response.xml" -InputObject $response.InnerXML
