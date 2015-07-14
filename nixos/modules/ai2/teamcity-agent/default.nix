{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.teamcity-agent;
  stateDir = "/opt/teamcity/agent";				
in
{
  options = {
    services.teamcity-agent = {
      enable = mkOption {
        default = false;
        description = "Whether to enable the TeamCity agent.";
	type = types.bool;
      };

      heapSize = mkOption {
        default = "384m";
	description = "Max heap size for the TeamCity Java process.";
	type = types.str;
      };

      gitPublicKey = mkOption {
        description = "Contents of the public SSH key file for checking out from GitHub.";
	type = types.str;
      };

      gitPrivateKey = mkOption {
        description = "Contents of the private SSH key file for checking out from GitHub.";
	type = types.str;
      };
                  
      sonatypeUser = mkOption {
        description = "Sonatype user needed to build s2-online";
        type = types.str;
      };

      sonatypePassword = mkOption {
        description = "Sonatype password needed to build s2-online";
        type = types.str;
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.teamcity-agent = {
      description = "TeamCity agent";

      requires = [ "teamcity.service" ];
      
      after = [ "network-interfaces.target" ];
      wantedBy = [ "multi-user.target" ];

      path = [ pkgs.bash pkgs.procps pkgs.jre pkgs.git pkgs.pkgconfig pkgs.openssh ];
      
      preStart =
        let
          sbtCreds = builtins.toFile "allenai.sbt" ''
            credentials += Credentials("Sonatype Nexus Repository Manager",
            "utility.allenai.org",
            "${cfg.sonatypeUser}",
            "${cfg.sonatypePassword}")
          '';
	  sshConfig = builtins.toFile "config" ''Host github.com
	    IdentityFile ${stateDir}/.ssh/git-dev
	  '';
        in
        ''
          if [ ! -d ${stateDir}/.ssh ] ; then
            mkdir -p ${stateDir}/.ssh
            cp ${sshConfig} ${stateDir}/.ssh/config;
            echo "${cfg.gitPrivateKey}" > ${stateDir}/.ssh/git-dev
            echo "${cfg.gitPublicKey}" > ${stateDir}/.ssh/git-dev.pub

            mkdir -p ${stateDir}/sbt
            cp ${sbtCreds} ${stateDir}/sbt/allenai.sbt;

	    mkdir -p ${stateDir}/bin
            ln -s /bin/sh ${stateDir}/bin/sh
          fi

          cp ${pkgs.teamcity}/buildAgent/bin/*.sh ${stateDir}/bin
          mkdir -p ${stateDir}/conf
          cp ${pkgs.teamcity}/buildAgent/conf/buildAgent.properties ${stateDir}/conf
          mkdir -p ${stateDir}/lib
          cp ${pkgs.teamcity}/buildAgent/lib/*.jar ${stateDir}/lib
          mkdir -p ${stateDir}/logs

          chown -R teamcity-agent:teamcity-agent ${stateDir}
          chmod -R ug+rw ${stateDir}
          chmod -R a+rX /opt/teamcity
          chmod -R 600 ${stateDir}/.ssh
        '';

      serviceConfig = {
        User = "teamcity-agent";
        WorkingDirectory = stateDir;
        PermissionsStartOnly = true;
        ExecStart = ''
	  ${pkgs.jre}/bin/java \
	    -ea \
	    -cp ${stateDir}/lib/launcher.jar \
	    jetbrains.buildServer.agent.Launcher \
	    -ea \
	    -Xmx${cfg.heapSize} \
	    -Dteamcity_logs=${stateDir}/logs/ \
	    -Dlog4j.configuration=file:${pkgs.teamcity}/buildAgent/conf/teamcity-agent-log4j.xml \
	    jetbrains.buildServer.agent.AgentMain \
	    -file ${stateDir}/conf/buildAgent.properties
	'';
      };
    };
    
    environment.systemPackages = [ pkgs.teamcity ];

    users.extraUsers.teamcity-agent = {
      group = "teamcity-agent";
      home = stateDir;
      createHome = true;
    };

    users.extraGroups.teamcity-agent = {};
  };
}
