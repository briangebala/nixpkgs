{ config, pkgs, lib }:

# Adapted from https://gist.github.com/leehambley/9741431695da3787f6b3

let
  datasource = config.datasource // { isDefault = true; };
  dashboards = map (json: builtins.toFile "grafana-dashboard" "{\"dashboard\":  ${json}, \"overwrite\":  true}") config.dashboards.json;
  cmds =
    lib.optional (config.datasource.name != null) "setup_grafana\n"
    ++ map (dashboard: "grafana_create_dashboard ${dashboard}\n") dashboards;
in
''
PATH=${pkgs.curl}/bin:$PATH

COOKIEJAR=$(mktemp)
trap 'unlink $COOKIEJAR' EXIT

GRAFANA_URL="http://${config.addr}:${toString config.port}"

until curl -s -o /dev/null $GRAFANA_URL 2>&1; do
  sleep 1;
done

function error_exit {
  echo $1
  exit 1
}

function setup_grafana_session {
  if ! curl -H 'Content-Type: application/json;charset=UTF-8' \
      --data-binary '{"user":"${config.security.adminUser}","email":"","password":"${config.security.adminPassword}"}' \
      --cookie-jar "$COOKIEJAR" \
      --silent \
      "$GRAFANA_URL/login"  ; then
      echo
      error_exit "Grafana Session: Couldn't store cookies at $COOKIEJAR"
  fi
}

function grafana_has_data_source {
    curl --silent --cookie "$COOKIEJAR" "$GRAFANA_URL/api/datasources" \
    | grep "\"name\":\"${datasource.name}\"" --silent
}

function grafana_create_data_source {
    curl --cookie "$COOKIEJAR" \
    -X PUT \
    --silent \
    -H 'Content-Type: application/json;charset=UTF-8' \
    --data-binary '${builtins.toJSON datasource}' \
    "$GRAFANA_URL/api/datasources"  | grep 'Datasource added' --silent;
}

function grafana_create_dashboard {
    curl --cookie "$COOKIEJAR" \
    -X POST \
    --silent \
    -H 'Content-Type: application/json;charset=UTF-8' \
    --data-binary @$1 \
    "$GRAFANA_URL/api/dashboards/db" | grep 'success' --silent;
}

function setup_grafana {
  if grafana_has_data_source ; then
    echo "Grafana: Data source ${datasource.name} already exists"
  else
    if grafana_create_data_source ; then
      echo "Grafana: Data source ${datasource.name} created"
    else
      error_exit "Grafana: Data source ${datasource.name} could not be created"
    fi
  fi
}

setup_grafana_session
${builtins.toString cmds}
''
