{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.teamcity;
  stateDir = "/opt/teamcity/server";
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
    };
  };

  config = mkIf cfg.enable {
  
    systemd.services.teamcity = {
      description = "TeamCity";

      after = [ "network-interfaces.target" ];
      wantedBy = [ "multi-user.target" ];

      preStart = ''
        mkdir -p ${stateDir}/work
        cp -r ${pkgs.teamcity}/webapps ${stateDir}
        chown -R teamcity:teamcity ${stateDir}
	chmod -R u+rw ${stateDir}
	chmod -R a+rX /opt
      '';

      serviceConfig = {
        User = "teamcity";
        WorkingDirectory = stateDir;
        PermissionsStartOnly = true;
        ExecStart = ''
          ${pkgs.jre}/bin/java \
	  -Djava.util.logging.config.file=${pkgs.teamcity}/conf/logging.properties \
	  -Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager \
	  -server \
	  -Xmx${cfg.heapSize} \
	  -XX:MaxPermSize=270m \
	  -Dlog4j.configuration=file:${pkgs.teamcity}/conf/teamcity-server-log4j.xml \
	  -Dteamcity_logs=${stateDir} \
	  -Djsse.enableSNIExtension=false \
	  -Djava.awt.headless=true \
	  -Djava.endorsed.dirs=${pkgs.teamcity}/endorsed \
	  -classpath ${pkgs.teamcity}/bin/bootstrap.jar:${pkgs.teamcity}/bin/tomcat-juli.jar \
	  -Dcatalina.home=${pkgs.teamcity} \
	  -Djava.io.tmpdir=${stateDir} \
	  org.apache.catalina.startup.Bootstrap start
	'';
      };
    };
    
    environment.systemPackages = [ pkgs.teamcity ];

    users.extraUsers.teamcity = {
      group = "teamcity";
      home = stateDir;
      createHome = true;
    };

    users.extraGroups.teamcity = {};
        
#    users.extraUsers = lib.singleton {
#      name = "teamcity";
#      description = "teamcity";
#      home = stateDir;
#      createHome = true;
#      extraGroups = [ "users" ];
#    };
  };
}
