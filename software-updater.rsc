/system scheduler
add interval=1m name=software-updater on-event=software-updater

/system script
add dont-require-permissions=no name=software-updater \
    source="/system package update set channel=stable\r\
    \n/system package update install"

#Do not edit script directly in here. Fix the raw script in the raw-scripts folder
#put the raw script on a router then use "/system script export to dump" to update this file
:do {{
/system scheduler
add name=firmware-updater on-event=firmware-updater \
    start-time=startup
/system script
add dont-require-permissions=no name=firmware-updater owner=admin policy=\
    ftp,reboot,read,write,policy,test,password,sniff,sensitive,romon source=":if\
    \_([/system routerboard get current-firmware] != [/system routerboard get up\
    grade-firmware] ) do {{\r\
    \n    :log info \"firmware-updater: Updating routerboard firmware\";\r\
    \n    /system routerboard upgrade;\r\
    \n    :delay 5s;\r\
    \n    /system reboot\r\
    \n}} else={{\r\
    \n    :log info \"firmware-updater:No FW Update Required\"\r\
    \n}}\r\
    \n\r\
    \n\r\
    \n"

}} on-error={{:log error "failed to set up firmware updater"}}