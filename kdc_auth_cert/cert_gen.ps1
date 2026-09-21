# Generate KDC Root CA
openssl req -x509 -newkey rsa:4096 -nodes `
    -keyout kdc_root_ca.key -out kdc_root_ca.crt `
    -days 3650 -config kdc_root_ca.cnf -extensions v3_ca

# Generate KDC key and CSR
openssl req -new -newkey rsa:2048 -nodes `
    -keyout kdc.key -out kdc.csr -config kdc.cnf

# Sign the KDC certiticate
openssl x509 -req -in kdc.csr `
    -CA kdc_root_ca.crt -CAkey kdc_root_ca.key -CAcreateserial `
    -out kdc.crt -days 1825 `
    -extfile kdc.cnf -extensions v3_kdc

# Set up a minimal CA database for CRL
New-Item -ItemType Directory -Force -Path C:\localkdc | Out-Null
New-Item -ItemType File -Force -Path C:\localkdc\index.txt | Out-Null
Set-Content -Path C:\localkdc\crlnumber -Value "01"

# Generate an empty CRL
openssl ca -gencrl -config kdc_crl.cnf -out C:\localkdc\kdc.crl

# Import KDC Root CA to the Root store and NTAuth
Import-Certificate -FilePath kdc_root_ca.crt -CertStoreLocation Cert:\LocalMachine\Root
certutil -enterprise -addstore NTAuth kdc_root_ca.crt

# Import KDC certificate to the Personal store
openssl pkcs12 -export -in kdc.crt -inkey kdc.key -out kdc.pfx -password pass:TempPass123!
Import-PfxCertificate -FilePath kdc.pfx -CertStoreLocation Cert:\LocalMachine\My `
    -Password (ConvertTo-SecureString "TempPass123!" -AsPlainText -Force)

# Clean up plaintext key
Remove-Item kdc.pfx, kdc.key -Force

# Import CRL directly to the CA store
certutil -addstore CA C:\localkdc\kdc.crl