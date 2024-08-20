#This is customized for Isplicity to easily be uploaded to a router preconfigured

#Runs at 3 AM by default
:global startTime "03:00:00" 

#Runs every 30 days by default
:global updateFrequency "30d" 


/tool e-mail
set server=mail.smtp2go.com from=rtrupdater@isplicity.com port=2525 tls=starttls user=isplicity.com password="Ug45iJnv9bte53fe"
/system scheduler add name="Firmware Updater" on-event="/system script run BackupAndUpdate;" start-time=$startTime interval=$updateFrequency comment="" disabled=no

/system script
add dont-require-permissions=no name=BackupAndUpdate owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source="#\
    \_Script name: BackupAndUpdate\r\
    \n#\r\
    \n#----------SCRIPT INFORMATION-------------------------------------------\
    --------\r\
    \n#\r\
    \n# Script:  Mikrotik RouterOS automatic backup & update\r\
    \n# Version: 22.11.12\r\
    \n# Created: 07/08/2018\r\
    \n# Updated: 12/11/2022\r\
    \n# Author:  Alexander Tebiev\r\
    \n# Website: https://github.com/beeyev\r\
    \n# You can contact me by e-mail at tebiev@mail.com\r\
    \n#\r\
    \n# IMPORTANT!\r\
    \n# Minimum supported RouterOS version is v6.43.7\r\
    \n#\r\
    \n#----------MODIFY THIS SECTION AS NEEDED--------------------------------\
    --------\r\
    \n## Notification e-mail\r\
    \n## (Make sure you have configurated Email settings in Tools -> Email)\r\
    \n:local emailAddress \"isplicity@isplicity.com\";\r\
    \n\r\
    \n## Script mode, possible values: backup, osupdate, osnotify.\r\
    \n# backup    -   Only backup will be performed. (default value, if none p\
    rovided)\r\
    \n#\r\
    \n# osupdate  -   The script will install a new RouterOS version if it is \
    available.\r\
    \n#               It will also create backups before and after update proc\
    ess (it does not matter what value `forceBackup` is set to)\r\
    \n#               Email will be sent only if a new RouterOS version is ava\
    ilable.\r\
    \n#               Change parameter `forceBackup` if you need the script to\
    \_create backups every time when it runs (even when no updates were found)\
    .\r\
    \n#\r\
    \n# osnotify  -   The script will send email notifications only (without b\
    ackups) if a new RouterOS update is available.\r\
    \n#               Change parameter `forceBackup` if you need the script to\
    \_create backups every time when it runs.\r\
    \n:local scriptMode \"osupdate\";\r\
    \n\r\
    \n## Additional parameter if you set `scriptMode` to `osupdate` or `osnoti\
    fy`\r\
    \n# Set `true` if you want the script to perform backup every time it's fi\
    red, whatever script mode is set.\r\
    \n:local forceBackup false;\r\
    \n\r\
    \n## Backup encryption password, no encryption if no password.\r\
    \n:local backupPassword \"\"\r\
    \n\r\
    \n## If true, passwords will be included in exported config.\r\
    \n:local sensitiveDataInConfig true;\r\
    \n\r\
    \n## Update channel. Possible values: stable, long-term, testing, developm\
    ent\r\
    \n:local updateChannel \"stable\";\r\
    \n\r\
    \n## Install only patch versions of RouterOS updates.\r\
    \n## Works only if you set scriptMode to \"osupdate\"\r\
    \n## Means that new update will be installed only if MAJOR and MINOR versi\
    on numbers remained the same as currently installed RouterOS.\r\
    \n## Example: v6.43.6 => major.minor.PATCH\r\
    \n## Script will send information if new version is greater than just patc\
    h.\r\
    \n:local installOnlyPatchUpdates false;\r\
    \n\r\
    \n##----------------------------------------------------------------------\
    --------------------##\r\
    \n#  !!!! DO NOT CHANGE ANYTHING BELOW THIS LINE, IF YOU ARE NOT SURE WHAT\
    \_YOU ARE DOING !!!!  #\r\
    \n##----------------------------------------------------------------------\
    --------------------##\r\
    \n\r\
    \n#Script messages prefix\r\
    \n:local SMP \"Bkp&Upd:\"\r\
    \n\r\
    \n:log info \"\\r\\n\$SMP script \\\"Mikrotik RouterOS automatic backup & \
    update\\\" started.\";\r\
    \n:log info \"\$SMP Script Mode: \$scriptMode, forceBackup: \$forceBackup\
    \";\r\
    \n\r\
    \n#Check proper email config\r\
    \n:if ([:len \$emailAddress] = 0 or [:len [/tool e-mail get address]] = 0 \
    or [:len [/tool e-mail get from]] = 0) do={\r\
    \n    :log error (\"\$SMP Email configuration is not correct, please check\
    \_Tools -> Email. Script stopped.\");\r\
    \n    :error \"\$SMP bye!\";\r\
    \n}\r\
    \n\r\
    \n#Check if proper identity name is set\r\
    \nif ([:len [/system identity get name]] = 0 or [/system identity get name\
    ] = \"MikroTik\") do={\r\
    \n    :log warning (\"\$SMP Please set identity name of your device (Syste\
    m -> Identity), keep it short and informative.\");\r\
    \n};\r\
    \n\r\
    \n############### vvvvvvvvv GLOBALS vvvvvvvvv ###############\r\
    \n# Function converts standard mikrotik build versions to the number.\r\
    \n# Possible arguments: paramOsVer\r\
    \n# Example:\r\
    \n# :put [\$buGlobalFuncGetOsVerNum paramOsVer=[/system routerboard get cu\
    rrent-RouterOS]];\r\
    \n# Result will be: 64301, because current RouterOS version is: 6.43.1\r\
    \n:global buGlobalFuncGetOsVerNum do={\r\
    \n    :local osVer \$paramOsVer;\r\
    \n    :local osVerNum;\r\
    \n    :local osVerMicroPart;\r\
    \n    :local zro 0;\r\
    \n    :local tmp;\r\
    \n\r\
    \n    # Replace word `beta` with dot\r\
    \n    :local isBetaPos [:tonum [:find \$osVer \"beta\" 0]];\r\
    \n    :if (\$isBetaPos > 1) do={\r\
    \n        :set osVer ([:pick \$osVer 0 \$isBetaPos] . \".\" . [:pick \$osV\
    er (\$isBetaPos + 4) [:len \$osVer]]);\r\
    \n    }\r\
    \n    # Replace word `rc` with dot\r\
    \n    :local isRcPos [:tonum [:find \$osVer \"rc\" 0]];\r\
    \n    :if (\$isRcPos > 1) do={\r\
    \n        :set osVer ([:pick \$osVer 0 \$isRcPos] . \".\" . [:pick \$osVer\
    \_(\$isRcPos + 2) [:len \$osVer]]);\r\
    \n    }\r\
    \n\r\
    \n    :local dotPos1 [:find \$osVer \".\" 0];\r\
    \n\r\
    \n    :if (\$dotPos1 > 0) do={\r\
    \n\r\
    \n        # AA\r\
    \n        :set osVerNum  [:pick \$osVer 0 \$dotPos1];\r\
    \n\r\
    \n        :local dotPos2 [:find \$osVer \".\" \$dotPos1];\r\
    \n                #Taking minor version, everything after first dot\r\
    \n        :if ([:len \$dotPos2] = 0) do={:set tmp [:pick \$osVer (\$dotPos\
    1+1) [:len \$osVer]];}\r\
    \n        #Taking minor version, everything between first and second dots\
    \r\
    \n        :if (\$dotPos2 > 0) do={:set tmp [:pick \$osVer (\$dotPos1+1) \$\
    dotPos2];}\r\
    \n\r\
    \n        # AA 0B\r\
    \n        :if ([:len \$tmp] = 1) do={:set osVerNum \"\$osVerNum\$zro\$tmp\
    \";}\r\
    \n        # AA BB\r\
    \n        :if ([:len \$tmp] = 2) do={:set osVerNum \"\$osVerNum\$tmp\";}\r\
    \n\r\
    \n        :if (\$dotPos2 > 0) do={\r\
    \n            :set tmp [:pick \$osVer (\$dotPos2+1) [:len \$osVer]];\r\
    \n            # AA BB 0C\r\
    \n            :if ([:len \$tmp] = 1) do={:set osVerNum \"\$osVerNum\$zro\$\
    tmp\";}\r\
    \n            # AA BB CC\r\
    \n            :if ([:len \$tmp] = 2) do={:set osVerNum \"\$osVerNum\$tmp\"\
    ;}\r\
    \n        } else={\r\
    \n            # AA BB 00\r\
    \n            :set osVerNum \"\$osVerNum\$zro\$zro\";\r\
    \n        }\r\
    \n    } else={\r\
    \n        # AA 00 00\r\
    \n        :set osVerNum \"\$osVer\$zro\$zro\$zro\$zro\";\r\
    \n    }\r\
    \n\r\
    \n    :return \$osVerNum;\r\
    \n}\r\
    \n\r\
    \n\r\
    \n# Function creates backups (system and config) and returns array with na\
    mes\r\
    \n# Possible arguments:\r\
    \n#    `backupName`               | string    | backup file name, without \
    extension!\r\
    \n#    `backupPassword`           | string    |\r\
    \n#    `sensitiveDataInConfig`    | boolean   |\r\
    \n# Example:\r\
    \n# :put [\$buGlobalFuncCreateBackups name=\"daily-backup\"];\r\
    \n:global buGlobalFuncCreateBackups do={\r\
    \n    :log info (\"\$SMP Global function \\\"buGlobalFuncCreateBackups\\\"\
    \_was fired.\");\r\
    \n\r\
    \n    :local backupFileSys \"\$backupName.backup\";\r\
    \n    :local backupFileConfig \"\$backupName.rsc\";\r\
    \n    :local backupNames {\$backupFileSys;\$backupFileConfig};\r\
    \n\r\
    \n    ## Make system backup\r\
    \n    :if ([:len \$backupPassword] = 0) do={\r\
    \n        /system backup save dont-encrypt=yes name=\$backupName;\r\
    \n    } else={\r\
    \n        /system backup save password=\$backupPassword name=\$backupName;\
    \r\
    \n    }\r\
    \n    :log info (\"\$SMP System backup created. \$backupFileSys\");\r\
    \n\r\
    \n    ## Export config file\r\
    \n    :if (\$sensitiveDataInConfig = true) do={\r\
    \n        # Since RouterOS v7 it needs to be explicitly set that we want t\
    o export sensitive data\r\
    \n        :if ([:pick [/system package update get installed-version] 0 1] \
    < 7) do={\r\
    \n            :execute \"/export compact terse file=\$backupName\";\r\
    \n        } else={\r\
    \n            :execute \"/export compact show-sensitive terse file=\$backu\
    pName\";\r\
    \n        }\r\
    \n    } else={\r\
    \n        /export compact hide-sensitive terse file=\$backupName;\r\
    \n    }\r\
    \n    :log info (\"\$SMP Config file was exported. \$backupFileConfig, the\
    \_script execution will be paused for a moment.\");\r\
    \n\r\
    \n    #Delay after creating backups\r\
    \n    :delay 20s;\r\
    \n    :return \$backupNames;\r\
    \n}\r\
    \n\r\
    \n:global buGlobalVarUpdateStep;\r\
    \n############### ^^^^^^^^^ GLOBALS ^^^^^^^^^ ###############\r\
    \n\r\
    \n:local scriptVersion \"22.11.12\";\r\
    \n\r\
    \n#Current date time in format: yyyymmmdd-hhMMss. E.g. 2020jan15-221324\r\
    \n:local dateTime ([:pick [/system clock get date] 7 11] . [:pick [/system\
    \_clock get date] 0 3] . [:pick [/system clock get date] 4 6] . \"-\" . [:\
    pick [/system clock get time] 0 2] . [:pick [/system clock get time] 3 5] \
    . [:pick [/system clock get time] 6 8]);\r\
    \n\r\
    \n:local isSoftBased false;\r\
    \n:if ([/system resource get board-name] = \"CHR\" or [/system resource ge\
    t board-name] = \"x86\") do={\r\
    \n    :set isSoftBased true;\r\
    \n}\r\
    \n\r\
    \n:local deviceOsVerInst          [/system package update get installed-ve\
    rsion];\r\
    \n:local deviceOsVerInstNum       [\$buGlobalFuncGetOsVerNum paramOsVer=\$\
    deviceOsVerInst];\r\
    \n:local deviceOsVerAvail         \"\";\r\
    \n:local deviceOsVerAvailNum      0;\r\
    \n:local deviceIdentityName       [/system identity get name];\r\
    \n:local deviceIdentityNameShort  [:pick \$deviceIdentityName 0 18]\r\
    \n:local deviceUpdateChannel      [/system package update get channel];\r\
    \n\r\
    \n\r\
    \n:local deviceRbModel            \"CloudHostedRouter\";\r\
    \n:local deviceRbSerialNumber     \"--\";\r\
    \n:local deviceRbCurrentFw        \"--\";\r\
    \n:local deviceRbUpgradeFw        \"--\";\r\
    \n\r\
    \n:if (\$isSoftBased = false) do={\r\
    \n    :set deviceRbModel          [/system routerboard get model];\r\
    \n    :set deviceRbSerialNumber   [/system routerboard get serial-number];\
    \r\
    \n    :set deviceRbCurrentFw      [/system routerboard get current-firmwar\
    e];\r\
    \n    :set deviceRbUpgradeFw      [/system routerboard get upgrade-firmwar\
    e];\r\
    \n};\r\
    \n\r\
    \n:local isOsUpdateAvailable false;\r\
    \n:local isOsNeedsToBeUpdated false;\r\
    \n\r\
    \n:local isSendEmailRequired true;\r\
    \n\r\
    \n:local mailSubject  \"\$SMP Device - \$deviceIdentityNameShort.\";\r\
    \n:local mailBody     \"\";\r\
    \n\r\
    \n:local mailBodyDeviceInfo   \"\\r\\n\\r\\nDevice information: \\r\\nIden\
    tity: \$deviceIdentityName \\r\\nModel: \$deviceRbModel \\r\\nSerial numbe\
    r: \$deviceRbSerialNumber \\r\\nCurrent RouterOS: \$deviceOsVerInst (\$[/s\
    ystem package update get channel]) \$[/system resource get build-time] \\r\
    \\nCurrent routerboard FW: \$deviceRbCurrentFw \\r\\nDevice uptime: \$[/sy\
    stem resource get uptime]\";\r\
    \n:local mailBodyCopyright    \"\\r\\n\\r\\nMikrotik RouterOS automatic ba\
    ckup & update (ver. \$scriptVersion) \\r\\nhttps://github.com/beeyev/Mikro\
    tik-RouterOS-automatic-backup-and-update\";\r\
    \n:local changelogUrl         (\"Check RouterOS changelog: https://mikroti\
    k.com/download/changelogs/\" . \$updateChannel . \"-release-tree\");\r\
    \n\r\
    \n:local backupName           \"v\$deviceOsVerInst_\$deviceUpdateChannel_\
    \$dateTime\";\r\
    \n:local backupNameBeforeUpd  \"backup_before_update_\$backupName\";\r\
    \n:local backupNameAfterUpd   \"backup_after_update_\$backupName\";\r\
    \n\r\
    \n:local backupNameFinal  \$backupName;\r\
    \n:local mailAttachments  [:toarray \"\"];\r\
    \n\r\
    \n\r\
    \n:local updateStep \$buGlobalVarUpdateStep;\r\
    \n:do {/system script environment remove buGlobalVarUpdateStep;} on-error=\
    {}\r\
    \n:if ([:len \$updateStep] = 0) do={\r\
    \n    :set updateStep 1;\r\
    \n}\r\
    \n\r\
    \n\r\
    \n## STEP ONE: Creating backups, checking for new RouterOs version and sen\
    ding email with backups,\r\
    \n## Steps 2 and 3 are fired only if script is set to automatically update\
    \_device and if a new RouterOs version is available.\r\
    \n:if (\$updateStep = 1) do={\r\
    \n    :log info (\"\$SMP Performing the first step.\");\r\
    \n\r\
    \n    # Checking for new RouterOS version\r\
    \n    if (\$scriptMode = \"osupdate\" or \$scriptMode = \"osnotify\") do={\
    \r\
    \n        log info (\"\$SMP Checking for new RouterOS version. Current ver\
    sion is: \$deviceOsVerInst\");\r\
    \n        /system package update set channel=\$updateChannel;\r\
    \n        /system package update check-for-updates;\r\
    \n        :delay 5s;\r\
    \n        :set deviceOsVerAvail [/system package update get latest-version\
    ];\r\
    \n\r\
    \n        # If there is a problem getting information about available Rout\
    erOS versions from server\r\
    \n        :if ([:len \$deviceOsVerAvail] = 0) do={\r\
    \n            :log warning (\"\$SMP There is a problem getting information\
    \_about new RouterOS from server.\");\r\
    \n            :set mailSubject    (\$mailSubject . \" Error: No data about\
    \_new RouterOS!\")\r\
    \n            :set mailBody         (\$mailBody . \"Error occured! \\r\\nM\
    ikrotik couldn't get any information about new RouterOS from server! \\r\\\
    nWatch additional information in device logs.\")\r\
    \n        } else={\r\
    \n            #Get numeric version of OS\r\
    \n            :set deviceOsVerAvailNum [\$buGlobalFuncGetOsVerNum paramOsV\
    er=\$deviceOsVerAvail];\r\
    \n\r\
    \n            # Checking if OS on server is greater than installed one.\r\
    \n            :if (\$deviceOsVerAvailNum > \$deviceOsVerInstNum) do={\r\
    \n                :set isOsUpdateAvailable true;\r\
    \n                :log info (\"\$SMP New RouterOS is available! \$deviceOs\
    VerAvail\");\r\
    \n            } else={\r\
    \n                :set isSendEmailRequired false;\r\
    \n                :log info (\"\$SMP System is already up to date.\");\r\
    \n                :set mailSubject (\$mailSubject . \" No new OS updates.\
    \");\r\
    \n                :set mailBody      (\$mailBody . \"Your system is up to \
    date.\");\r\
    \n            }\r\
    \n        };\r\
    \n    } else={\r\
    \n        :set scriptMode \"backup\";\r\
    \n    };\r\
    \n\r\
    \n    if (\$forceBackup = true) do={\r\
    \n        # In this case the script will always send email, because it has\
    \_to create backups\r\
    \n        :set isSendEmailRequired true;\r\
    \n    }\r\
    \n\r\
    \n    # If a new OS version is available to install\r\
    \n    if (\$isOsUpdateAvailable = true and \$isSendEmailRequired = true) d\
    o={\r\
    \n        # If we only need to notify about a new available version\r\
    \n        if (\$scriptMode = \"osnotify\") do={\r\
    \n            :set mailSubject    (\$mailSubject . \" New RouterOS is avai\
    lable! v.\$deviceOsVerAvail.\")\r\
    \n            :set mailBody       (\$mailBody . \"New RouterOS version is \
    available to install: v.\$deviceOsVerAvail (\$updateChannel) \\r\\n\$chang\
    elogUrl\")\r\
    \n        }\r\
    \n\r\
    \n        # If we need to initiate RouterOS update process\r\
    \n        if (\$scriptMode = \"osupdate\") do={\r\
    \n            :set isOsNeedsToBeUpdated true;\r\
    \n            # If we need to install only patch updates\r\
    \n            :if (\$installOnlyPatchUpdates = true) do={\r\
    \n                #Check if Major and Minor builds are the same.\r\
    \n                :if ([:pick \$deviceOsVerInstNum 0 ([:len \$deviceOsVerI\
    nstNum]-2)] = [:pick \$deviceOsVerAvailNum 0 ([:len \$deviceOsVerAvailNum]\
    -2)]) do={\r\
    \n                    :log info (\"\$SMP New patch version of RouterOS fir\
    mware is available.\");\r\
    \n                } else={\r\
    \n                    :log info           (\"\$SMP New major or minor vers\
    ion of RouterOS firmware is available. You need to update it manually.\");\
    \r\
    \n                    :set mailSubject    (\$mailSubject . \" New RouterOS\
    : v.\$deviceOsVerAvail needs to be installed manually.\");\r\
    \n                    :set mailBody       (\$mailBody . \"New major or min\
    or RouterOS version is available to install: v.\$deviceOsVerAvail (\$updat\
    eChannel). \\r\\nYou chose to automatically install only patch updates, so\
    \_this major update you need to install manually. \\r\\n\$changelogUrl\");\
    \r\
    \n                    :set isOsNeedsToBeUpdated false;\r\
    \n                }\r\
    \n            }\r\
    \n\r\
    \n            #Check again, because this variable could be changed during \
    checking for installing only patch updats\r\
    \n            if (\$isOsNeedsToBeUpdated = true) do={\r\
    \n                :log info           (\"\$SMP New RouterOS is going to be\
    \_installed! v.\$deviceOsVerInst -> v.\$deviceOsVerAvail\");\r\
    \n                :set mailSubject    (\$mailSubject . \" New RouterOS is \
    going to be installed! v.\$deviceOsVerInst -> v.\$deviceOsVerAvail.\");\r\
    \n                :set mailBody       (\$mailBody . \"Your Mikrotik will b\
    e updated to the new RouterOS version from v.\$deviceOsVerInst to v.\$devi\
    ceOsVerAvail (Update channel: \$updateChannel) \\r\\nFinal report with the\
    \_detailed information will be sent when update process is completed. \\r\
    \\nIf you have not received second email in the next 10 minutes, then prob\
    ably something went wrong. (Check your device logs)\");\r\
    \n                #!! There is more code connected to this part and first \
    step at the end of the script.\r\
    \n            }\r\
    \n\r\
    \n        }\r\
    \n    }\r\
    \n\r\
    \n    ## Checking If the script needs to create a backup\r\
    \n    :log info (\"\$SMP Checking If the script needs to create a backup.\
    \");\r\
    \n    if (\$forceBackup = true or \$scriptMode = \"backup\" or \$isOsNeeds\
    ToBeUpdated = true) do={\r\
    \n        :log info (\"\$SMP Creating system backups.\");\r\
    \n        if (\$isOsNeedsToBeUpdated = true) do={\r\
    \n            :set backupNameFinal \$backupNameBeforeUpd;\r\
    \n        };\r\
    \n        if (\$scriptMode != \"backup\") do={\r\
    \n            :set mailBody (\$mailBody . \"\\r\\n\\r\\n\");\r\
    \n        };\r\
    \n\r\
    \n        :set mailSubject    (\$mailSubject . \" Backup was created.\");\
    \r\
    \n        :set mailBody       (\$mailBody . \"System backups were created \
    and attached to this email.\");\r\
    \n\r\
    \n        :set mailAttachments [\$buGlobalFuncCreateBackups backupName=\$b\
    ackupNameFinal backupPassword=\$backupPassword sensitiveDataInConfig=\$sen\
    sitiveDataInConfig];\r\
    \n    } else={\r\
    \n        :log info (\"\$SMP There is no need to create a backup.\");\r\
    \n    }\r\
    \n\r\
    \n    # Combine first step email\r\
    \n    :set mailBody (\$mailBody . \$mailBodyDeviceInfo . \$mailBodyCopyrig\
    ht);\r\
    \n}\r\
    \n\r\
    \n## STEP TWO: (after first reboot) routerboard firmware upgrade\r\
    \n## Steps 2 and 3 are fired only if script is set to automatically update\
    \_device and if new RouterOs is available.\r\
    \n:if (\$updateStep = 2) do={\r\
    \n    :log info (\"\$SMP Performing the second step.\");\r\
    \n    ## RouterOS is the latest, let's check for upgraded routerboard firm\
    ware\r\
    \n    if (\$deviceRbCurrentFw != \$deviceRbUpgradeFw) do={\r\
    \n        :set isSendEmailRequired false;\r\
    \n        :delay 10s;\r\
    \n        :log info \"\$SMP Upgrading routerboard firmware from v.\$device\
    RbCurrentFw to v.\$deviceRbUpgradeFw\";\r\
    \n        ## Start the upgrading process\r\
    \n        /system routerboard upgrade;\r\
    \n        ## Wait until the upgrade is completed\r\
    \n        :delay 5s;\r\
    \n        :log info \"\$SMP routerboard upgrade process was completed, goi\
    ng to reboot in a moment!\";\r\
    \n        ## Set scheduled task to send final report on the next boot, tas\
    k will be deleted when is is done. (That is why you should keep original s\
    cript name)\r\
    \n        /system scheduler add name=BKPUPD-FINAL-REPORT-ON-NEXT-BOOT on-e\
    vent=\":delay 5s; /system scheduler remove BKPUPD-FINAL-REPORT-ON-NEXT-BOO\
    T; :global buGlobalVarUpdateStep 3; :delay 10s; /system script run BackupA\
    ndUpdate;\" start-time=startup interval=0;\r\
    \n        ## Reboot system to boot with new firmware\r\
    \n        /system reboot;\r\
    \n    } else={\r\
    \n        :log info \"\$SMP It appers that your routerboard is already up \
    to date, skipping this step.\";\r\
    \n        :set updateStep 3;\r\
    \n    };\r\
    \n}\r\
    \n\r\
    \n## STEP THREE: Last step (after second reboot) sending final report\r\
    \n## Steps 2 and 3 are fired only if script is set to automatically update\
    \_device and if new RouterOs is available.\r\
    \n:if (\$updateStep = 3) do={\r\
    \n    :log info (\"\$SMP Performing the third step.\");\r\
    \n    :log info \"Bkp&Upd: RouterOS and routerboard upgrade process was co\
    mpleted. New RouterOS version: v.\$deviceOsVerInst, routerboard firmware: \
    v.\$deviceRbCurrentFw.\";\r\
    \n    ## Small delay in case mikrotik needs some time to initialize connec\
    tions\r\
    \n    :log info \"\$SMP The final email with report and backups of upgrade\
    d system will be sent in a minute.\";\r\
    \n    :delay 1m;\r\
    \n    :set mailSubject    (\$mailSubject . \" RouterOS Upgrade is complete\
    d, new version: v.\$deviceOsVerInst!\");\r\
    \n    :set mailBody       \"RouterOS and routerboard upgrade process was c\
    ompleted. \\r\\nNew RouterOS version: v.\$deviceOsVerInst, routerboard fir\
    mware: v.\$deviceRbCurrentFw. \\r\\n\$changelogUrl \\r\\n\\r\\nBackups of \
    the upgraded system are in the attachment of this email.  \$mailBodyDevice\
    Info \$mailBodyCopyright\";\r\
    \n    :set mailAttachments [\$buGlobalFuncCreateBackups backupName=\$backu\
    pNameAfterUpd backupPassword=\$backupPassword sensitiveDataInConfig=\$sens\
    itiveDataInConfig];\r\
    \n}\r\
    \n\r\
    \n# Remove functions from global environment to keep it fresh and clean.\r\
    \n:do {/system script environment remove buGlobalFuncGetOsVerNum;} on-erro\
    r={}\r\
    \n:do {/system script environment remove buGlobalFuncCreateBackups;} on-er\
    ror={}\r\
    \n\r\
    \n##\r\
    \n## SENDING EMAIL\r\
    \n##\r\
    \n# Trying to send email with backups as attachments.\r\
    \n\r\
    \n:if (\$isSendEmailRequired = true) do={\r\
    \n    :log info \"\$SMP Sending email message, it will take around half a \
    minute...\";\r\
    \n    :do {/tool e-mail send to=\$emailAddress subject=\$mailSubject body=\
    \$mailBody file=\$mailAttachments;} on-error={\r\
    \n        :delay 5s;\r\
    \n        :log error \"\$SMP could not send email message (\$[/tool e-mail\
    \_get last-status]). Going to try it again in a while.\"\r\
    \n\r\
    \n        :delay 5m;\r\
    \n\r\
    \n        :do {/tool e-mail send to=\$emailAddress subject=\$mailSubject b\
    ody=\$mailBody file=\$mailAttachments;} on-error={\r\
    \n            :delay 5s;\r\
    \n            :log error \"\$SMP could not send email message (\$[/tool e-\
    mail get last-status]) for the second time.\"\r\
    \n\r\
    \n            if (\$isOsNeedsToBeUpdated = true) do={\r\
    \n                :set isOsNeedsToBeUpdated false;\r\
    \n                :log warning \"\$SMP script is not going to initialise u\
    pdate process due to inability to send backups to email.\"\r\
    \n            }\r\
    \n        }\r\
    \n    }\r\
    \n\r\
    \n    :delay 30s;\r\
    \n\r\
    \n    :if ([:len \$mailAttachments] > 0 and [/tool e-mail get last-status]\
    \_= \"succeeded\") do={\r\
    \n        :log info \"\$SMP File system cleanup.\"\r\
    \n        /file remove \$mailAttachments;\r\
    \n        :delay 2s;\r\
    \n    }\r\
    \n\r\
    \n}\r\
    \n\r\
    \n\r\
    \n# Fire RouterOS update process\r\
    \nif (\$isOsNeedsToBeUpdated = true) do={\r\
    \n\r\
    \n    :if (\$isSoftBased = false) do={\r\
    \n        ## Set scheduled task to upgrade routerboard firmware on the nex\
    t boot, task will be deleted when upgrade is done. (That is why you should\
    \_keep original script name)\r\
    \n        /system scheduler add name=BKPUPD-UPGRADE-ON-NEXT-BOOT on-event=\
    \":delay 5s; /system scheduler remove BKPUPD-UPGRADE-ON-NEXT-BOOT; :global\
    \_buGlobalVarUpdateStep 2; :delay 10s; /system script run BackupAndUpdate;\
    \" start-time=startup interval=0;\r\
    \n    } else= {\r\
    \n        ## If the script is executed on CHR, step 2 will be skipped\r\
    \n        /system scheduler add name=BKPUPD-UPGRADE-ON-NEXT-BOOT on-event=\
    \":delay 5s; /system scheduler remove BKPUPD-UPGRADE-ON-NEXT-BOOT; :global\
    \_buGlobalVarUpdateStep 3; :delay 10s; /system script run BackupAndUpdate;\
    \" start-time=startup interval=0;\r\
    \n    };\r\
    \n\r\
    \n\r\
    \n    :log info \"\$SMP everything is ready to install new RouterOS, going\
    \_to reboot in a moment!\"\r\
    \n    ## Command is reincarnation of the \"upgrade\" command - doing exact\
    ly the same but under a different name\r\
    \n    /system package update install;\r\
    \n}\r\
    \n\r\
    \n:log info \"\$SMP script \\\"Mikrotik RouterOS automatic backup & update\
    \\\" completed it's job.\\r\\n\";\r\
    \n"
