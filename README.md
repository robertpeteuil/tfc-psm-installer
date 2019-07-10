# Installer for Terraform Cloud Policy Sets Migration Utility

## Automatically Download, Extract and Install Latest or Specific Version

[![release](https://img.shields.io/github/release/robertpeteuil/tfc-psm-installer.svg?colorB=2067b8)](https://github.com/robertpeteuil/tfc-psm-installer)
[![bash](https://img.shields.io/badge/language-bash-89e051.svg?style=flat-square)](https://github.com/robertpeteuil/tfc-psm-installer)
[![license](https://img.shields.io/github/license/robertpeteuil/tfc-psm-installer.svg?colorB=2067b8)](https://github.com/robertpeteuil/tfc-psm-installer)

---

The **tfc-psm-install** script automates the process of downloading and installing the [tfc-policy-sets-migration](https://github.com/hashicorp/tfc-policy-sets-migration) utility.

This script detects the latest version, OS and CPU-Architecture and allows installation to local or system locations.  Optional parameters allow installing a specific version and installing to /usr/local/bin without prompting.

Options:

- `-i VERSION`:  Install specific version
- `-a`:          Automatically use `sudo` to install to /usr/local/bin
  - allows for unattended installation via scripts or CD tools
  - can be set as default behavior by uncommenting line 14 (`sudoInstall=true`)
  - sudo password may be required unless NOPASSWD is enabled
- `-c`:          leave binary in working directory (for CI/DevOps use)
- `-h`:          help
- `-v`:          display version

This installer is similar to my [Packer Installer](https://github.com/robertpeteuil/packer-installer), [Sentinel Simulator Installer](https://github.com/robertpeteuil/sentinel-installer) and [Vault Installer](https://github.com/robertpeteuil/vault-installer)

## Express install latest version via my bootstrap server (iac.sh or https://iac.sh)

``` shell
curl iac.sh/tfc-psm | sh
```

## Download and Use Locally

Download Installer

``` shell
curl -LO https://raw.github.com/robertpeteuil/tfc-psm-installer/master/tfc-psm-install
chmod +x tfc-psm-install
```

Download installer via my bootstrap server (iac.sh or <https://iac.sh)>

``` shell
curl iac.sh/tfc-psm-install.sh | sh
# downloads installer as tfc-psm-install.sh in current directory
```

### Run local installer

``` shell
./tfc-psm-install.sh

# usage: tfc-psm-install.sh [-i VERSION] [-a] [-c] [-h] [-v]
#      -i VERSION : specify version to install in format '' (OPTIONAL)
#      -a         : automatically use sudo to install to /usr/local/bin
#      -c         : leave binary in working directory (for CI/DevOps use)
#      -h         : help
#      -v         : display vault-install.sh version
```

## System Requirements

- System with Bash Shell (Linux, macOS, Windows Subsystem for Linux)
- `unzip` - terraform downloads are in zip format
- `curl` - used to retrieve metadata and download

## Script Process Details

- Determines Version to Download and Install
  - Uses Version specified by `-i VERSION` parameter (if specified)
  - Otherwise determines Latest Version
    - Uses GitHub API to retrieve latest version
- Calculates Download URL based on Version, OS and CPU-Architecture
- Verifies URL Validity before Downloading in Case:
  - VERSION incorrectly specified with `-i`
  - Download URL Format Changed
- Determines Install Destination
  - Performed before Download/Install Process in case user selects `abort`
- Installation Process
  - Download, Download SHA, Verify SHA of zip, Extract, Install, Cleanup and Display Results

### CPU Architecture Detection

CPU architecture is detected for each OS accordingly:

- Linux / Windows (WSL since this is a Bash script)
  - detected with `lscpu` or by inspecting `/proc/cpuinfo`
- macOS - uses Default Arch `amd64` as it's the only version available on macOS
- Default Value - `amd64`

## Disclaimer

I am a HashiCorp employee, but this is a personal project and not officially endorsed or supported by HashiCorp.

## License

Apache 2.0 License - Copyright (c) 2019    Robert Peteuil
