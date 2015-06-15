{ stdenv, fetchurl, makeWrapper, jre, pythonPackages, procps, nettools, writeTextFile, bash }:

let
 runtimeDeps = ''
   ${procps}/bin
   ${nettools}/bin
   ${bash}/bin
 '';
in 
stdenv.mkDerivation rec {
  name = "spark-${version}";
  version = "1.2.0";
  
  src = fetchurl {
    # url = "http://d3kbcqa49mib13.cloudfront.net/spark-1.2.2-bin-hadoop2.4.tgz";
    # sha256 = "1cxl24kr90sy1sygxmrd3ks0cy2bwsssgk26j0mx1mmdabnx2h73";
    # url = "http://d3kbcqa49mib13.cloudfront.net/spark-1.2.1-bin-hadoop2.4.tgz";
    # sha256 = "0m5ljas24l8q9j26hi64cri1zr905rg6xa8rf7war41hggv8qqcf";
    # url = "http://d3kbcqa49mib13.cloudfront.net/spark-1.2.0-bin-hadoop2.4.tgz";
    # sha256 = "1qwzgl69ivbpc6fdij0db9vkr0ig4qlhkgfydb8vqr235rqcn886";
    url = "http://ai2-s2.s3.amazonaws.com/third-party/spark-1.2.0-bin-hadoop2.4-scala2.11.tgz";
    sha256 = "0bl6c96zw4v7yqwjgy4m6k6ch7dsx23h3hw6cs7lk596bjnxs4hw";
  };

  buildInputs = [ makeWrapper jre pythonPackages.python pythonPackages.numpy ];

  untarDirName = "${name}-bin-hadoop";
  dontStrip = true;
  installPhase = ''
    mkdir -p $out/lib/${untarDirName}
    
    mv * $out/lib/${untarDirName};
    
    for n in $(find $out/lib/${untarDirName}/bin -type f ! -name "*.cmd"); do
      makeWrapper "$n" "$out/bin/$(basename $n)" \
        --suffix-each PATH ":" "${runtimeDeps}" \
	--set JAVA_HOME "${jre}"
    done

    for n in $(find $out/lib/${untarDirName}/sbin -type f); do
      makeWrapper "$n" "$out/sbin/$(basename $n)" \
        --suffix-each PATH ":" "${runtimeDeps}" \
	--set JAVA_HOME "${jre}"
    done

    
  '';
  meta = {
    description      = "Lightning-fast cluster computing";
    homepage         = "http://spark.apache.org";
    license          = stdenv.lib.licenses.asl20;
    platforms        = stdenv.lib.platforms.all;
    repositories.git = git://git.apache.org/spark.git;
  };
}

