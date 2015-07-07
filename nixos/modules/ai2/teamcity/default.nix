{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.teamcity;
in

{
  options = {
    services.teamcity = {
      enable = mkOption {
        default = false;
        description = "
          Enable TeamCity.
        ";
      };

      stateDir = mkOption {
        default = "/opt/teamcity";
        description = "
          Directory containing TeamCity runtime and log files.
        ";
      };
    };
  };

  config = mkIf cfg.enable {
  
    systemd.services.teamcity = {
      description = "TeamCity";
      after = [ "network-interfaces.target" ];
      wantedBy = [ "multi-user.target" ];

#    environment = {
#      CATALINA_OUT = "${cfg.stateDir}/catalina.out";
#      CATALINA_TMPDIR = "${cfg.stateDir}";
#      TEAMCITY_LOGS = "${cfg.stateDir}";
#      TEAMCITY_CATALINA_HOME = "${pkgs.teamcity}";
#    };
      preStart =
        ''
          mkdir -p ${cfg.stateDir}/work
	  cp -r ${pkgs.teamcity}/webapps ${cfg.stateDir}
          chmod -R 777 ${cfg.stateDir}
          chown -R teamcity:users ${cfg.stateDir}
        '';
      serviceConfig = {
        User = "teamcity";
        WorkingDirectory = cfg.stateDir;
        PermissionsStartOnly = true;
        ExecStart = "${pkgs.teamcity}/bin/teamcity-server.sh start";
        #ExecStop = "${pkgs.teamcity}/bin/teamcity-server.sh stop";
      };

      unitConfig = {
        RequiresMountsFor = cfg.stateDir;
      };    
    };
    
    environment.systemPackages = [ pkgs.teamcity ];

    users.extraUsers = lib.singleton {
      name = "teamcity";
      description = "teamcity";
      uid = 100981;
      home = cfg.stateDir;
      extraGroups = [ "users" ];
    };
    
#    users.extraUsers.teamcity = {
#      group = "teamcity";
#      uid = config.ids.uids.teamcity;
#    };

#    users.extraGroups.teamcity.gid = config.ids.gids.teamcity;
  };
}
