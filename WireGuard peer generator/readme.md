# WireGuard peer generator
this is first version of WireGuard peer generator.

it is a Windows PowerShell script which uses GUI elements.

## Generator consists of following files:
* WG-Peers.ps1 - main file
* WG-Peers.cfg.json - configuration file
* WG-Peers.forms.json - UI definition file
* UI_Lib-v3.ps1 - my UI library

please note: all files must be in the same directory!

## Configuration
* create API keys in Controller:
  * go to Global->Settings->Platform Intergation
  * click on `+Add New App`
  * name it, select Client Mode ad Admin role and All sites privileges
  * click on `Create`
  * copy the Client ID and Secret
* open WG-Peers.cfg.json file in editor and change the value of following three lines:\
    `"Host": "controller.contonso.com",`\
    `"ClientID": "........",`\
    `"ClientSecret": ".............."`
## Usage
The script creates peers for existing tunnel, please create WireGuard tunnel first in Controller, then run the  `WG-Peers.ps1`
