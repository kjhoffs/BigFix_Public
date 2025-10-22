# Import encryption key
# 24 integers, values 0-255, one per line, followed by a comma, except for line 24.

$EncryptionKey = Get-Content -Path "C:\Users\kjhoffs\Documents\BF_Password_Updates\key_sample.txt"

# USER: Change $EncryptedFile to "EncryptedProd.txt" or "EncryptedTestnet.txt" as necessary

$EncryptedFile = "encoded_password.txt"
$EncryptedPath = "C:\Users\kjhoffs\Documents\BF_Password_Updates\${EncryptedFile}"

# USER: Enter username and password into pop-up

(Get-Credential).password | ConvertFrom-SecureString -Key ${EncryptionKey} | Set-Content ${EncryptedPath}
