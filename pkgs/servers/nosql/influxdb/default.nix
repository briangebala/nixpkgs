{ stdenv, fetchurl, makeWrapper, zlib, bzip2 }:

assert stdenv.isLinux;

stdenv.mkDerivation rec {
  name = "influxdb-${version}";
  version = "0.8.8";
  arch = if stdenv.system == "x86_64-linux" then "amd64" else "386";

  src = fetchurl {
    url = "http://s3.amazonaws.com/influxdb/${name}.${arch}.tar.gz";
    sha1 = if arch == "amd64" then
        "652a71472354222e3f73ff09baef13424e9c78ea" else
        "a8e875ea26667dc000f7232e5cd594ab872ad277";
  };

  buildInputs = [ makeWrapper ];

  installPhase = ''
    install -D influxdb $out/bin/influxdb
    patchelf --set-interpreter "$(cat $NIX_GCC/nix-support/dynamic-linker)" $out/bin/influxdb
    wrapProgram "$out/bin/influxdb" \
        --prefix LD_LIBRARY_PATH : "${stdenv.gcc.gcc}/lib:${stdenv.gcc.gcc}/lib64:${zlib}/lib:${bzip2}/lib"

    mkdir -p $out/share/influxdb
    cp -R scripts config.toml $out/share/influxdb
  '';

  meta = with stdenv.lib; {
    description = "Scalable datastore for metrics, events, and real-time analytics";
    homepage = http://influxdb.com/;
    license = licenses.mit;

    maintainers = [ maintainers.offline ];
    platforms = ["i686-linux" "x86_64-linux"];
  };
}
