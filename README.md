# Asheron's Call client setup (ACEmulator)

A step-by-step guide to installing Asheron's Call on Windows 10/11 for an
[ACEmulator](https://github.com/ACEmulator/ACE) (ACE) server, with the usual add-on stack: Decal,
ThwargLauncher, Virindi Bundle, UtilityBelt, MagTools, Chaos Helper, TreeStats, Mag-Filter and the
DemonicControl VTank meta.

There are two ways to do it:

- **[Part A: with the script](#part-a-install-with-the-script)**. `Install-ACClient.ps1` downloads
  every file from its original source, checks it against a pinned SHA-256 hash (or Microsoft's
  signature), installs it and registers the plugins. You only click through two installers.
- **[Part B: by hand](#part-b-install-by-hand)**. The same steps, done yourself, with every download
  link.

Both end with **[Part C: first start and checks](#part-c-first-start-and-checks)**.
Nothing is redistributed from this repo; everything comes from its authors or their documented mirrors.

## Before you start

You need:

- **Windows 10 or 11**, an account that can approve admin (UAC) prompts, and about **3 GB** free on `C:`
  (1.3 GB of downloads, which you can delete afterwards, plus the game).
- From your server's admin: the **server address** (host name or IP), the **port** (usually `9000`) and
  whether accounts are created at first login (most ACE servers do this).
- Internet access to `web.archive.org`, `archive.org`, `github.com`, `gitlab.com`, `decaldev.com`,
  `thwargle.com`, `virindi.net` and Microsoft's download sites. If you use a VPN and a download keeps
  failing, see [Troubleshooting](#troubleshooting).

Good to know:

- Installing takes 15-30 minutes, most of it downloading.
- **Virindi** (VTank, Virindi Views) installs only while virindi.net is online, because its installer
  downloads the plugins from there. If it is down, everything else still installs; run the script again
  later.

---

## Part A: Install with the script

### A1. Get the files

On this page, click **Code -> Download ZIP**, then unzip it, e.g. to `Downloads\ac-client-setup`.
(Or `git clone` the repo.)

### A2. Open PowerShell in that folder

Open the unzipped folder in Explorer, click the address bar, type `powershell` and press Enter.
**Don't** start it as administrator; the script asks for that itself.

### A3. Dry run (optional, changes nothing)

```powershell
powershell -ExecutionPolicy Bypass -File .\Install-ACClient.ps1 -CheckOnly
```

You get a table of every component as `present` or `MISSING`. On a fresh PC everything is missing.
The *Virindi Bundle* row says "virindi.net unreachable" if that site is down right now.

### A4. Run the install

Use your server's name, address and port:

```powershell
powershell -ExecutionPolicy Bypass -File .\Install-ACClient.ps1 -ServerName "My Server" -ServerHost play.example.com -ServerPort 9000
```

`-ServerName/-ServerHost/-ServerPort` are optional: they add the server to ThwargLauncher for you.
Leave them out and you add the server by hand in [C1](#c1-thwarglauncher).

What happens:

1. **UAC prompt**: click *Yes*. A new, elevated PowerShell window continues. Keep it open.
2. **Prerequisites** install silently: .NET 3.5 (from Windows Update; this can take a few minutes),
   Visual C++ runtimes, DirectX 9.
3. The client installer (about 570 MB) downloads, then the **Turbine installer window** opens:
   - accept the license agreement if you agree to it,
   - keep the default folder **`C:\Turbine\Asheron's Call`**,
   - at the end, **don't** launch or update the game.
4. The end-of-retail files (about 485 MB) download and replace the installer's older ones (the originals
   are kept in `C:\Turbine\Asheron's Call\_original-installer-files`).
5. **Decal** and **ThwargLauncher** install silently.
6. If virindi.net is online, the **Virindi Plugin Installer** window opens: click **Check Libs**, then
   **Install**, then close the window when it says the install is complete.
7. **UtilityBelt**, **MagTools**, **Mag-Filter**, **Chaos Helper**, **TreeStats** and the
   **DemonicControl** files are installed and registered in Decal.
8. A **summary table** shows every component. `pending` lines need you (see the next step).

If anything fails, the script stops with a message saying why. Fix it (see
[Troubleshooting](#troubleshooting)) and run the same command again: finished parts are skipped.

### A5. Run it again after the first game start

Once you have started the game and logged in once (Part C), run the same command again. It then switches
on dual-logging (that file only exists after the first start) and, if virindi.net was down before,
installs Virindi and moves DemonicControl into VTank's folder.

When everything shows `present`, you can delete the download folder `%TEMP%\ac-client-setup`.

### Script options

| Option | Effect |
|---|---|
| `-CheckOnly` | Report what is installed or missing; change nothing. |
| `-SkipVirindi` | Leave out the Virindi Bundle and DemonicControl. |
| `-ServerName`, `-ServerHost`, `-ServerPort` | Add an ACE server to ThwargLauncher's list. |
| `-WorkDir <path>` | Download folder (default `%TEMP%\ac-client-setup`). |

Continue with [Part C](#part-c-first-start-and-checks).

---

## Part B: Install by hand

The script does exactly these steps. Download each file into its own folder. To check a download, run
`Get-FileHash <file>` in PowerShell and compare it with the SHA-256 in the script's `$Downloads` table
(Microsoft files: right-click -> *Properties* -> *Digital Signatures* should show Microsoft Corporation).

### B1. .NET Framework 3.5

Start menu -> type *Turn Windows features on or off* -> tick **.NET Framework 3.5 (includes .NET 2.0
and 3.0)** -> OK. Windows downloads it from Windows Update.

### B2. Visual C++ runtimes (all three, x86)

| File | Link |
|---|---|
| VC++ 2005 SP1 (8.0.50727.762), Microsoft no longer hosts it | [Wayback Machine copy of Microsoft's URL](https://web.archive.org/web/20190419092632id_/https://download.microsoft.com/download/e/1/c/e1c773de-73ba-494a-a5ba-f24906ecf088/vcredist_x86.exe) |
| VC++ 2005 SP1 MFC security update (8.0.50727.6195) | [download.microsoft.com](https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x86.EXE) |
| VC++ 2015-2022 x86 (Decal needs it) | [aka.ms/vs/17/release/vc_redist.x86.exe](https://aka.ms/vs/17/release/vc_redist.x86.exe) |

Run each one and accept its defaults. You need **both** 2005 packages: the Virindi installer checks for
the original 762 one.

### B3. DirectX 9.0c (June 2010)

Download [directx_Jun2010_redist.exe](https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe).
Run it, unpack it into an empty folder, then run **`DXSETUP.exe`** from that folder.

### B4. The Asheron's Call client

1. Download [ac1install.exe](https://web.archive.org/web/20201121104423id_/http://content.turbine.com/sites/clientdl/ac1/ac1install.exe)
   (Turbine's original installer, about 570 MB, from the Wayback Machine).
2. Run it, accept the license if you agree, keep the default folder **`C:\Turbine\Asheron's Call`**,
   and don't launch or update the game at the end.

### B5. End-of-retail files

1. Download [ac-updates.zip](https://archive.org/download/ac-updates/ac-updates.zip) (about 485 MB). It is
   byte-identical to the MEGA download the community guides link to.
2. In `C:\Turbine\Asheron's Call`, make a folder `_original-installer-files` and move these four files
   into it: `acclient.exe`, `client_cell_1.dat`, `client_local_English.dat`, `client_portal.dat`.
3. Copy the four files from the zip into `C:\Turbine\Asheron's Call`.
4. Check: `client_portal.dat` is 926,941,184 bytes and `client_cell_1.dat` is 348,127,232 bytes.

### B6. Decal

Download [Decal.msi](https://www.decaldev.com/releases/2983/Decal.msi) (2.9.8.3) and install it.

### B7. ThwargLauncher

Download [ThwargLauncherInstaller.exe](https://thwargle.com/thwarglauncher/updates/ThwargLauncherInstaller.exe)
(7.4.0.0) and install it with the defaults.

### B8. Virindi Bundle (needs virindi.net online)

1. Download [VirindiInstaller1008.zip](https://web.archive.org/web/20250820082918id_/http://www.virindi.net/plugins/updates/VirindiInstaller1008.zip)
   and unzip it into an empty folder.
2. Run `VirindiInstaller.exe`: **Check Libs**, then **Install**, then close it.

### B9. UtilityBelt

Download [UtilityBeltInstaller-0.2.7.exe](https://gitlab.com/utilitybelt/utilitybelt.gitlab.io/uploads/f24f9359893592252815818da7b3b7ba/UtilityBeltInstaller-0.2.7.exe)
and install it. It registers itself in Decal.

### B10. MagTools, Mag-Filter, Chaos Helper, TreeStats

| Plugin | Download | Put it in |
|---|---|---|
| MagTools 2.2.0 | [MagTools.dll](https://github.com/Mag-nus/Mag-Plugins/releases/download/Mag-Tools-v2.2.0/MagTools.dll) | `C:\Games\Decal Plugins\MagTools` |
| Mag-Filter 2.0.3 | [MagFilter.dll](https://github.com/Mag-nus/Mag-Plugins/releases/download/Mag-Filter-v2.0.3/MagFilter.dll) | `C:\Games\Decal Plugins\MagFilter` |
| Chaos Helper 2.2.6.1 | [chaoshelperv2.2.6.1.zip](https://github.com/Oonej/ChaosHelper/releases/download/2.2.6.1/chaoshelperv2.2.6.1.zip) (unzip all files) | `C:\Games\Decal Plugins\ChaosHelper` |
| TreeStats 1.2.3b | [TreeStats_v1.2.3b.zip](https://github.com/amoeba/treestats/releases/download/v1.2.3b/TreeStats_v1.2.3b.zip) (unzip) | `C:\Games\Decal Plugins\TreeStats` |

Then register each one in Decal:

1. Open **Decal Agent** (desktop shortcut *Decal 3.0*, or its tray icon).
2. Click **Add**, then **Browse**, pick the `.dll`, and confirm. Repeat for each plugin.
3. Add **`ThwargFilter.dll`** the same way, from
   `C:\Program Files (x86)\Thwargle Games\ThwargLauncher`.
4. Make sure every entry has a tick.

### B11. DemonicControl (needs VTank from B8)

From [github.com/RonGeorge/DemonicControl](https://github.com/RonGeorge/DemonicControl) (tested at commit
`4a83fe1`), download `DemonicControl.met` and the files in `loot-profiles-and-autopack/`, and copy them all
into **`C:\Games\VirindiPlugins\VirindiTank`**.

Continue with Part C. Dual-logging (C5) is a manual step there too.

---

## Part C: First start and checks

### C1. ThwargLauncher

Start **ThwargLauncher** from the desktop:

1. **Settings**: the client location should be `C:\Turbine\Asheron's Call\acclient.exe`. Tick
   **Inject Decal**.
2. **Servers** (if the script didn't add yours): **Edit Servers** -> add a server with the name, host and
   port from your server's admin, emulator **ACE**, rodat **off**. Make sure it is ticked as visible.
3. **Add Account**: your account name and password, linked to that server. On most ACE servers the
   account is created at your first login. Never put your password in a file or a repo.

### C2. First login

Select the account and click **Launch**. The game starts, connects and shows character selection.
Create a character, enter the world, then **log out** and close the game. That first start creates
`Documents\Asheron's Call\UserPreferences.ini`.

If you hear sound but the screen stays black, see [Troubleshooting](#troubleshooting).

### C3. Check Decal and the plugins

Start the game again from ThwargLauncher. In game you should see the **Decal bar**, and windows or icons
for MagTools, UtilityBelt, Chaos Helper and (with Virindi) VTank. If one is missing, open **Decal
Agent** outside the game and check that it is listed and ticked.

### C4. VTank and DemonicControl

In the VTank window, load the **DemonicControl** meta and pick a loot profile.

### C5. Dual-logging (two clients at once)

Script users: run the script again (A5). By hand: close the game, open
`Documents\Asheron's Call\UserPreferences.ini`, and in the `[Net]` section set `ComputeUniquePort=True`.
ACE logs in one character per account, so add a second account in ThwargLauncher for the second client.

---

## What gets installed

| # | Component | Version | Installed to | Source |
|---|---|---|---|---|
| 1 | .NET Framework 3.5 | 3.5 SP1 | Windows feature | Windows Update (DISM) |
| 1 | Visual C++ 2005 SP1 x86 | 8.0.50727.762 | Windows | Microsoft (removed by Microsoft; Wayback Machine copy of its original URL, Microsoft-signed) |
| 1 | Visual C++ 2005 SP1 MFC update x86 | 8.0.50727.6195 | Windows | download.microsoft.com |
| 1 | Visual C++ 2015-2022 x86 | current | Windows | aka.ms/vs/17/release (Decal needs it) |
| 1 | DirectX 9.0c end-user runtime | June 2010 | Windows | download.microsoft.com |
| 2 | Asheron's Call client (`ac1install.exe`) | Turbine installer | `C:\Turbine\Asheron's Call` | Turbine's URL via the Wayback Machine (as linked by emulator.ac and ACCPP) |
| 2 | End-of-retail files (`ac-updates.zip`) | portal 926,941,184 / cell 348,127,232 bytes | same folder; originals moved to `_original-installer-files` | archive.org mirror, byte-identical (same MD5) to the MEGA file linked by emulator.ac/ACCPP |
| 3 | Decal | 2.9.8.3 | `C:\Program Files (x86)\Decal 3.0` | decaldev.com |
| 4 | ThwargLauncher (+ ThwargFilter) | 7.4.0.0 | `C:\Program Files (x86)\Thwargle Games\ThwargLauncher` | thwargle.com |
| 5 | Virindi Bundle (VTank, Virindi Views, Integrator, HUDs...) | installer 1.0.0.8 | `C:\Games\VirindiPlugins` | virindi.net (installer from the Wayback Machine; it downloads the plugins from virindi.net) |
| 6 | UtilityBelt | 0.2.7 | `C:\Games\Decal Plugins\UtilityBelt` | utilitybelt.gitlab.io |
| 7 | MagTools | 2.2.0 | `C:\Games\Decal Plugins\MagTools` | github.com/Mag-nus/Mag-Plugins |
| 7 | Mag-Filter | 2.0.3 | `C:\Games\Decal Plugins\MagFilter` | github.com/Mag-nus/Mag-Plugins |
| 7 | Chaos Helper | 2.2.6.1 | `C:\Games\Decal Plugins\ChaosHelper` | github.com/Oonej/ChaosHelper |
| 7 | TreeStats | 1.2.3b | `C:\Games\Decal Plugins\TreeStats` | github.com/amoeba/treestats |
| 8 | DemonicControl meta + loot/autopack profiles | commit `4a83fe1` (2025-07-18) | VTank folder `C:\Games\VirindiPlugins\VirindiTank` | github.com/RonGeorge/DemonicControl |
| 9 | Dual-log setting | `ComputeUniquePort=True` | `Documents\Asheron's Call\UserPreferences.ini` | - |

Notes:
- **TreeStats** uploads your characters' stats to the public site treestats.net while enabled.
  Untick it in Decal Agent if you don't want that.
- **Chaos Helper** and UtilityBelt's windows use Virindi Views, so they need the Virindi Bundle.
- **Mag-Filter** overlaps with ThwargLauncher's login handling; disable one if logins misbehave.

## Troubleshooting

- **Sound but a black screen** (common on Intel graphics): the client's full-screen mode fails. Press
  **Alt+Enter** to switch to a window. To make it stick: close the game, and in
  `Documents\Asheron's Call\UserPreferences.ini`, section `[Display]`, set `FullScreen=False`. Change the
  window size later in the game's options (any resolution smaller than your screen works).
- **A download fails with "connection reset" / curl exit 56** (seen with web.archive.org):
  a VPN (or a VPN exit node) can make the Wayback Machine drop large downloads.
  Pause the VPN/exit node for the download and turn it back on afterwards, then re-run the script.
- **Virindi installer: "You do not have the Visual C++ 2005 SP1 redistributable"**: it wants the
  original 8.0.50727.762 package, not only the later 6195 update. Install both (B2; the script does).
- **Virindi installer: *Install* stays greyed out** after *Check Libs*: it couldn't download its
  component list from virindi.net (`updatelist.php`). The site is down; try again later.
  `-CheckOnly` tells you whether virindi.net answers.
- **A pinned hash no longer matches**: the source changed the file. The script refuses it on
  purpose. Check the new file's origin, then update the hash in `$Downloads` in a commit.
- **DirectX error when entering the world**: at character select press Alt+Enter for windowed
  mode, then change the resolution in the game options.
- **Can't reach the server**: ACE uses UDP on the port you entered and the next one (e.g.
  9000-9001). A server on a home or private network is only reachable from that network or
  through its VPN.
- **Two clients at once**: ACE logs in one character per account, so use a second account in
  ThwargLauncher; `ComputeUniquePort=True` lets both clients run.

## Credits

All software is downloaded from its authors or their documented mirrors: Turbine/WB (client),
Decal Development, Thwargle (ThwargLauncher), Virindi, the UtilityBelt team, Mag-nus (MagTools,
Mag-Filter), Oonej (Chaos Helper), amoeba (TreeStats), RonGeorge (DemonicControl), and the
ACEmulator, emulator.ac and ACCPP communities for the setup documentation.

The script and this guide are MIT licensed (see `LICENSE`). That covers only this repo's own
files, not the software it downloads, which stays under its owners' terms. Asheron's Call is a
trademark of Warner Bros. Entertainment; this project is not affiliated with it.
