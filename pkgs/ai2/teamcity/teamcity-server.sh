#!/bin/sh

# ---------------------------------------------------------------------
# TeamCity server start/stop script
# ---------------------------------------------------------------------
# Environment variables:
#
# TEAMCITY_SERVER_MEM_OPTS   server memory options (JVM options)
#
# TEAMCITY_SERVER_OPTS       additional server JVM options
#
# TEAMCITY_DATA_PATH         path to TeamCity data directory
#
# TEAMCITY_PREPARE_SCRIPT    name of a script to execute before start/stop
#
# ---------------------------------------------------------------------

case "$1" in
start|stop|run)
  old_cwd=`pwd`

  BIN=`dirname $0`
  cd $BIN
  BIN=`pwd`

  mkdir ../logs 2>/dev/null

  if [ -f "$BIN/teamcity-init.sh" ]; then
    . "$BIN/teamcity-init.sh"
  fi

  if [ "$TEAMCITY_SERVER_MEM_OPTS" = "" ]; then
    # Default options suitable for product evaluation
    TEAMCITY_SERVER_MEM_OPTS="-Xmx512m -XX:MaxPermSize=270m"

    # Options recommended for dedicated server installation (commented by default)
    #TEAMCITY_SERVER_MEM_OPTS="-Xms750m -Xmx750m -XX:MaxPermSize=270m"
  fi

  CATALINA_OPTS="$CATALINA_OPTS $TEAMCITY_SERVER_OPTS -server $TEAMCITY_SERVER_MEM_OPTS -Dlog4j.configuration=\"file:$BIN/../conf/teamcity-server-log4j.xml\" -Dteamcity_logs=$TEAMCITY_LOGS -Djsse.enableSNIExtension=false -Djava.awt.headless=true"

  export CATALINA_OPTS
  CATALINA_HOME="$TEAMCITY_CATALINA_HOME"
  CATALINA_BASE="$TEAMCITY_CATALINA_HOME"

  echo "INFO teamcity-server.sh: CATALINA_HOME=$CATALINA_HOME"
  
  if [ "$TEAMCITY_PREPARE_SCRIPT" != "" ]; then
      "$TEAMCITY_PREPARE_SCRIPT" $*
  fi

  echo "BEFORE"
  ./catalina.sh $1
  echo "AFTER"

  cd "$old_cwd"

;;
*)
    echo "Run as $0 (start|stop)"
    exit 1
;;
esac

