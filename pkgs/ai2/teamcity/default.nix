{ stdenv, makeWrapper, writeTextFile, jre, ... }:
let
  log4jXml = writeTextFile {
    name = "log4j.xml";
    text = ''
      <configuration>
        <appender name="STDOUT" class="org.apache.log4j.ConsoleAppender">
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
  buildAgentProperties = writeTextFile {
    name = "buildAgent.properties";
    text = builtins.readFile ./buildAgent.properties;
  };
  buildAgentDistProperties = writeTextFile {
    name = "buildAgent.dist.properties";
    text = builtins.readFile ./buildAgent.dist.properties;
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
    cp ${buildAgentProperties} $out/buildAgent/conf/buildAgent.properties
    cp ${buildAgentDistProperties} $out/buildAgent/conf/buildAgent.dist.properties
  '';
  
  meta = with stdenv.lib; {
    homepage = "https://www.jetbrains.com/teamcity/";
    description = "TeamCity";
  };
}
