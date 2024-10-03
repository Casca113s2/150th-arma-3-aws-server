#cloud-config
write_files:
  - path: /home/ssm-user/server_init.sh
    permissions: '0700'
    encoding: b64
    content: ${SERVERINIT}
  - path: /home/ssm-user/steamcmd_webpanel_init.sh
    permissions: '0705'
    encoding: b64
    content: ${STEAMCMDINIT}
  - path: /home/ssm-user/install_mods_and_config.sh
    permissions: '0705'
    encoding: b64
    content: ${SCRIPTINIT}
  - path: /home/ssm-user/install_ocap.sh
    permissions: '0705'
    encoding: b64
    content: ${OCAPINIT}
  
runcmd:
  - /home/ssm-user/server_init.sh