{ stdenv, makeWrapper, writeTextFile, jre, ... }:
let
  teamcityOutputDir = "/opt/teamcity";
  log4jXml = writeTextFile {
    name = "log4j.xml";
    text = ''
      <configuration>
        <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
          <encoder>
            <pattern>%date{YYYY-MM-dd HH:mm:ss} %level [%thread] %logger{10} [%file:%line] %msg%n</pattern>
	  </encoder>
	</appender>

	<root level="INFO">
	  <appender-ref ref="STDOUT" />
	</root>
      </configuration>
    '';
  };
  loggingProperties = writeTextFile {
    name="logging.properties";
    text = ''
      handlers = java.util.logging.ConsoleHandler
      .handlers = java.util.logging.ConsoleHandler
      java.util.logging.ConsoleHandler.level = INFO
      java.util.logging.ConsoleHandler.formatter = java.util.logging.SimpleFormatter    
    '';
  };
  serverXml = writeTextFile {
    name="server.xml";
    text = builtins.readFile ./server.xml;
  };
  teamcityServer = writeTextFile {
    executable = true;
    name="teamcity-server.sh";
    text = builtins.readFile ./teamcity-server.sh;
  };
  catalinaSh = writeTextFile {
    executable = true;
    name="catalina.sh";
    text = builtins.readFile ./catalina.sh;
  };
  
in
stdenv.mkDerivation rec {
  name = "teamcity-${version}";
  version = "9.0.5";
  src = "/tmp/TeamCity-${version}.tar.gz";

  buildInputs = [ makeWrapper jre ];
  
  installPhase = ''
    mkdir -p $out
    cp -r * $out
    cp ${loggingProperties} $out/conf/logging.properties
    cp ${log4jXml} $out/conf/teamcity-maintenance-log4j.xml
    cp ${log4jXml} $out/conf/teamcity-server-log4j.xml
    cp ${serverXml} $out/conf/server.xml
    cp ${teamcityServer} $out/bin/teamcity-server.sh
    cp ${catalinaSh} $out/bin/catalina.sh    

    wrapProgram $out/bin/teamcity-server.sh \
    --set JAVA_HOME "${jre}" \
    --set CATALINA_TMPDIR "/opt/teamcity" \
    --set TEAMCITY_CATALINA_HOME $out \
    --set TEAMCITY_LOGS "/opt/teamcity" \
    --set CATALINA_OUT "/opt/teamcity/catalina.out" \
    --set CATALINA_PID "/opt/teamcity/catalina.pid" \
    --add-flags start
   '';
  
  meta = with stdenv.lib; {
    homepage = "https://www.jetbrains.com/teamcity/";
    description = "TeamCity";
  };
}
