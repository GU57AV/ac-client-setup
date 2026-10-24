# Asheron's Call client setup (ACEmulator)

Everything needed to play Asheron's Call on Windows 10/11 against an ACEmulator server,
with the usual add-on stack: Decal, ThwargLauncher,
Virindi Bundle, UtilityBelt, MagTools, Chaos Helper, TreeStats, Mag-Filter and the
DemonicControl VTank meta.

`Install-ACClient.ps1` does all of it. It downloads each file from its original source,
checks it against a pinned SHA-256 hash (or Microsoft's signature) and stops if anything
doesn't match. Nothing is redistributed from this repo.

## Quick start

1. Download this repo (Code -> Download ZIP) and unzip it, or `git clone` it.
2. Open **Windows PowerShell** (not as admin; the script asks for elevation itself) in that folder.
3. Optional dry run, changes nothing:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\Install-ACClient.ps1 -CheckOnly
   ```
4. Install, adding your ACE server to ThwargLauncher (use your server's name, address and port):
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\Install-ACClient.ps1 -ServerName "My Server" -ServerHost play.example.com -ServerPort 9000
   ```
   Accept the UAC prompt. Two windows need you:
   - the **Turbine installer**: accept the EULA if you agree, keep the default folder
     `C:\Turbine\Asheron's Call`, decline launching the game at the end;
   - the **Virindi Plugin Installer**: click *Check Libs*, then *Install*, then close it.
5. Finish the [manual steps](#after-the-script) below.

The script is safe to re-run: finished parts are skipped. Re-run it after Virindi comes back
online, after the first game start (for the dual-log setting), or after any failure.

About 1.3 GB is downloaded (most of it the client installer and the dat files) to
`%TEMP%\ac-client-setup`; delete that folder afterwards if you like.

### Options

| Option | Effect |
|---|---|
| `-CheckOnly` | Report what is installed or missing; change nothing. |
| `-SkipVirindi` | Leave out the Virindi Bundle and DemonicControl. |
| `-ServerName`, `-ServerHost`, `-ServerPort` | Add an ACE server to ThwargLauncher's list. |
| `-WorkDir <path>` | Download folder (default `%TEMP%\ac-client-setup`). |

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

All Decal plugins and filters are registered and enabled in Decal.

Notes:
- **TreeStats** uploads your characters' stats to the public site treestats.net while enabled.
  Untick it in Decal Agent if you don't want that.
- **Chaos Helper** and UtilityBelt's windows use Virindi Views, so they need the Virindi Bundle.
- **Mag-Filter** overlaps with ThwargLauncher's login handling; disable one if logins misbehave.

## After the script

1. **ThwargLauncher** (desktop shortcut):
   - *Settings*: the AC client path should be `C:\Turbine\Asheron's Call\acclient.exe`; tick **Inject Decal**.
   - If you didn't pass `-ServerHost`: *Edit Servers* -> add the server with the host and port
     its admin gives you (usually port `9000`), emulator **ACE**, rodat off.
   - *Add Account*: your account name and password. On most ACE servers the account is created
     at first login. Never put the password in a file or in this repo.
2. **Start the game once** from ThwargLauncher, log in, then log out. This creates
   `UserPreferences.ini`; re-run the script to switch on dual-logging.
3. **Decal Agent** (tray icon / desktop shortcut): every plugin should show a tick. Untick what
   you don't want.
4. **VTank**: in game, load the `DemonicControl` meta and pick a loot profile in the VTank window.

## Doing it by hand

The script follows these steps; use them if you'd rather click through yourself. Check each
file's SHA-256 (`Get-FileHash <file>`) against the value in the script's `$Downloads` table.

1. **Prerequisites.** Turn on *.NET Framework 3.5* in *Turn Windows features on or off*.
   Install both VC++ 2005 SP1 x86 packages, the VC++ 2015-2022 x86 runtime and the DirectX
   June 2010 runtime (unpack it, then run `DXSETUP.exe`).
2. **Client.** Run `ac1install.exe`, keep the default folder. Move `acclient.exe`,
   `client_cell_1.dat`, `client_local_English.dat` and `client_portal.dat` out of
   `C:\Turbine\Asheron's Call` into a backup folder, then copy the four files from
   `ac-updates.zip` in.
3. **Decal.** Install `Decal.msi`.
4. **ThwargLauncher.** Run `ThwargLauncherInstaller.exe`.
5. **Virindi.** Unzip `VirindiInstaller1008.zip`, run `VirindiInstaller.exe`, *Check Libs*, *Install*.
6. **UtilityBelt.** Run its installer; it registers itself in Decal.
7. **Other plugins.** Put each dll (and Chaos Helper's extra files) in its own folder under
   `C:\Games\Decal Plugins`, then in Decal Agent: *Add* -> *Browse* -> pick the dll. Do the same
   for `ThwargFilter.dll` in the ThwargLauncher folder.
8. **DemonicControl.** Copy `DemonicControl.met` and the files in `loot-profiles-and-autopack`
   into `C:\Games\VirindiPlugins\VirindiTank`.
9. **Dual-log.** In `Documents\Asheron's Call\UserPreferences.ini`, section `[Net]`, set
   `ComputeUniquePort=True` (with the game closed).

## Troubleshooting

- **A download fails with "connection reset" / curl exit 56** (seen with web.archive.org):
  a VPN (or a VPN exit node) can make the Wayback Machine drop large downloads.
  Pause the VPN/exit node for the download and turn it back on afterwards, then re-run the script.
- **Virindi installer: "You do not have the Visual C++ 2005 SP1 redistributable"**: it wants the
  original 8.0.50727.762 package, not only the later 6195 update. The script installs both.
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
