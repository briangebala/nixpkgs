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
        description = "Whether to enable TeamCity.";
	type = types.bool;
      };

      heapSize = mkOption {
        default = "512m";
	description = "Max heap size for the TeamCity Java process.";
	type = types.str;
      };

      stateDir = mkOption {
        default = "/opt/teamcity";
        description = "Directory containing TeamCity runtime and log files.";
	type = types.str;
      };
    };
  };

  config = mkIf cfg.enable {
  
    systemd.services.teamcity = {
      description = "TeamCity";

      after = [ "network-interfaces.target" ];
      wantedBy = [ "multi-user.target" ];

      preStart = ''
        mkdir -p ${cfg.stateDir}/work
        cp -r ${pkgs.teamcity}/webapps ${cfg.stateDir}
	chmod -R u+rw *
        chown -R teamcity:users ${cfg.stateDir}
      '';

      serviceConfig = {
        User = "teamcity";
        WorkingDirectory = cfg.stateDir;
        PermissionsStartOnly = true;
        ExecStart = ''
          ${pkgs.jre}/bin/java \
	  -Djava.util.logging.config.file=${pkgs.teamcity}/conf/logging.properties \
	  -Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager \
	  -server \
	  -Xmx${cfg.heapSize} \
	  -XX:MaxPermSize=270m \
	  -Dlog4j.configuration=file:${pkgs.teamcity}/conf/teamcity-server-log4j.xml \
	  -Dteamcity_logs=${cfg.stateDir} \
	  -Djsse.enableSNIExtension=false \
	  -Djava.awt.headless=true \
	  -Djava.endorsed.dirs=${pkgs.teamcity}/endorsed \
	  -classpath ${pkgs.teamcity}/bin/bootstrap.jar:${pkgs.teamcity}/bin/tomcat-juli.jar \
	  -Dcatalina.home=${pkgs.teamcity} \
	  -Djava.io.tmpdir=${cfg.stateDir} \
	  org.apache.catalina.startup.Bootstrap start
	'';
        #ExecStop = "${pkgs.teamcity}/bin/teamcity-server.sh stop";
      };

    };
    
    environment.systemPackages = [ pkgs.teamcity ];

    users.extraUsers = lib.singleton {
      name = "teamcity";
      description = "teamcity";
      uid = 100881;
      home = cfg.stateDir;
      createHome = true;
      extraGroups = [ "users" ];
    };
    
#    users.extraUsers.teamcity = {
#      group = "teamcity";
#      uid = config.ids.uids.teamcity;
#    };

#    users.extraGroups.teamcity.gid = config.ids.gids.teamcity;
  };
}
