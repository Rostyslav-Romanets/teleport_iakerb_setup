# IAKerb Feature Setup Guide

## Windows 11 Insider Build Setup

1. Enroll in the [Windows Insider Program](https://www.microsoft.com/en-us/software-download/windowsinsiderpreviewiso).
2. Download and install the **Experimental (Build 29xxx.xxxx) - Future Platforms** edition.
3. Follow the [Configure Access for Local Windows Users](https://goteleport.com/docs/enroll-resources/desktop-access/getting-started/) guide.

After performing this setup, follow additional steps to enable IAKerb feature
(these tasks can be automated in the Teleport Windows Auth Installer later):

1. Enable the IAKerb feature.
On recent Windows Experimental builds, import [`enable_iakerb.reg`](enable_iakerb.reg). This sets the `DisableIAKerb` and `DisableLocalKDC` registry values.
Restart Windows and verify that the `Kerberos Local Key Distribution Center` service is running. If the service is not running, or if you are using an older build, import [`ntlmless_feat.reg`](ntlmless_feat.reg) instead.
2. Import the `teleport.cer` certificate downloaded during the [Configure Access for Local Windows Users](https://goteleport.com/docs/enroll-resources/desktop-access/getting-started/) setup into the NTAuth store:
```
certutil -enterprise -addstore NTAuth teleport.cer
```
3. Build the patched version of Teleport (see [Build the Teleport](#build-the-teleport)), then download and install the Teleport CA CRL
```
curl.exe -fo crl.crl https://teleport.example.com/webapi/auth/crl
certutil -addstore CA crl.crl
```
4. Install OpenSSL. The Light edition is sufficient: https://slproweb.com/products/Win32OpenSSL.html.
5. Generate the KDC Authentication certificate. Use the [`kdc_auth_cert/cert_gen.ps1`](kdc_auth_cert/cert_gen.ps1) script.
6. Switch from the Microsoft account required during Windows setup to a local Windows account: `Settings` -> `Account` -> `Your info` -> `Account settings` -> `Sign in with local account instead`.
7. Restart the Windows to apply changes.

## Teleport client configuration

Add the Windows host to the Teleport configuration:

```yaml
  static_hosts:
    - name: "Windows 11 IAKerb"
      ad: false
      addr: 192.168.10.10
      sid: "S-1-5-...-1001"
      labels:
        teleport.dev/computer_name: "DESKTOP-063RJLL"
```

Replace the example `address`, `SID`, and `computer name` with the values for your Windows host.

To get the user SID, run:

```
whoami /user
```

The Windows login must also be added in the windows_desktop_logins list. For example:

```yaml
kind: role
version: v5
metadata:
  name: windows-desktop-admins
spec:
  allow:
    windows_desktop_labels:
      "*": "*"
    windows_desktop_logins: ["Administrator", "User123"]
```

## Build the Teleport

Clone all repositories into the same parent directory:

```
mkdir teleport-iakerb
cd teleport-iakerb

git clone https://github.com/Rostyslav-Romanets/picky-rs
git -C picky-rs checkout add-iakerb-messages

git clone https://github.com/Rostyslav-Romanets/sspi-rs
git -C sspi-rs checkout ia-kerb-support

git clone https://github.com/Rostyslav-Romanets/IronRDP
git -C IronRDP checkout iakerb-smart-card-login-fix

git clone https://github.com/Rostyslav-Romanets/teleport
git -C teleport checkout nla-kerb-for-local-accounts
```

Build the Teleport client:

```
cd teleport
make build/teleport
```

To enable RDP NLA when launching Teleport, set the `TELEPORT_ENABLE_RDP_NLA="yes"` environment variable.
