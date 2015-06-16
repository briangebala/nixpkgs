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
  version = "1.4.0";
  
  src = fetchurl {
    url = "http://ai2-s2.s3.amazonaws.com/third-party/spark-${version}-bin-hadoop2.4-scala2.11.tgz";
    sha256 = "19dwcrdd79jdp046c8fpy616hfvh2vyw676jhrjqa264xj37pmnd";
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

