{ stdenv, sbt, makeWrapper, jre, bash, git, openssh, writeTextFile, which, spark, ... }:
let
  buildTargetDir = "offline/pipeline/target/scala-2.11/";
  assemblyJar = "pipeline-assembly-2014.09.02-5-SNAPSHOT.jar";
  assemblyDepsJar = "pipeline-assembly-2014.09.02-5-SNAPSHOT-deps.jar";

  #
  # TODO: see comments in ../services/spark-worker.nix
  # Note that here we set the spark executor classpath directly to a file on the local
  # filesystem. This is necesary to do a problem with Kryo Serialization in spark. 
  start-script = writeTextFile {
    executable = true;
    name = "start-s2-pipeline";
    text = ''
      if [ -z "$SPARK_MASTER" ]; then
        echo "SPARK_MASTER is unset. aborting.";
        exit 1;
      fi

      if [ -z "$PIPELINE_ASSEMBLY_JAR" ]; then
        echo "PIPELINE_ASSEMBLY_JAR is unset. aborting.";
        exit 1;
      fi

      if [ -z "$PIPELINE_ASSEMBLY_DEPS_JAR" ]; then
        echo "PIPELINE_ASSEMBLY_DEPS_JAR is unset. aborting.";
        exit 1;
      fi

      if [ -z "$PIPELINE_CONF_FILES" ]; then
        echo "PIPELINE_CONF_FILES is unset. aborting.";
          exit 1;
      fi

      if [ -z "$AWS_ACCESS_KEY_ID" ]; then
        echo "AWS_ACCESS_KEY_ID is unset. aborting.";
          exit 1;
      fi

      if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
        echo "AWS_SECRET_ACCESS_KEY is unset. aborting.";
          exit 1;
      fi

      # This gets picked up by conf/SparkPipeline.conf
      if [ -z "$SPARK_EVENT_LOG_DIR" ]; then
        echo "SPARK_EVENT_LOG_DIR is unset. aborting.";
        exit 1;
      fi

      if [ -z "$GROBID_HOME" ]; then
        echo "GROBID_HOME is unset. aborting.";
        exit 1
      fi

      if [ -z "$GROBID_PROPERTIES" ]; then
        echo "GROBID_PROPERTIES is unset. aborting.";
        exit 1
      fi

      if [ -z "$METRICS_PROPERTIES" ]; then
        echo "METRICS_PROPERTIES is unset. aborting.";
        exit 1
      fi

      PWD_AJAR=$(basename $PIPELINE_ASSEMBLY_JAR)
      PWD_ADJAR=$(basename $PIPELINE_ASSEMBLY_DEPS_JAR)

      export SPARK_EXECUTOR_EXTRA_CLASSPATH=/opt/data/spark/worker/lib/$PWD_AJAR:/opt/data/spark/worker/lib/$PWD_ADJAR;
      
      ${spark}/bin/spark-submit \
       --class org.allenai.scholar.pipeline.spark.BuildIndexFromPdfs \
       --master $SPARK_MASTER \
       --deploy-mode client \
       --driver-class-path "$PIPELINE_ASSEMBLY_DEPS_JAR" \
       --conf spark.metrics.conf="$METRICS_PROPERTIES" \
       $PIPELINE_ASSEMBLY_JAR \
       $PIPELINE_CONF_FILES
    '';
  };

  srcInfo = import /home/vagrant/local/s2-pipeline-src-info.nix {};
  sonatypeInfo = import /home/vagrant/local/s2-online-sonatype-credentials.nix;
in
stdenv.mkDerivation
rec {
  name = "s2-pipeline-${version}";
  version = srcInfo.version;
  src = srcInfo.src;

  buildInputs = [ sbt makeWrapper jre git openssh which ];

  dontStrip = true;

  buildPhase =
    let
      sbtDir = "./.sbt/0.13";
      sbtBootDir = "./.sbt-boot";
      ivyHomeDir = "/tmp/`whoami`/ivy-home";

      sbtOpts = "-Dsbt.global.base=${sbtDir} -Dsbt.boot.directory=${sbtBootDir} -Dsbt.ivy.home=${ivyHomeDir}";
      credentials = builtins.toFile "allenai.sbt" ''
        credentials += Credentials("Sonatype Nexus Repository Manager",
          "utility.allenai.org",
          "${sonatypeInfo.username}",
          "${sonatypeInfo.password}")
          '';
      in
        ''
        mkdir -p ${sbtDir}
        mkdir -p ${ivyHomeDir};

        cp ${credentials} ${sbtDir}/allenai.sbt;

        mkdir -p target
        sbt ${sbtOpts} "project pipeline" assembly assemblyPackageDependency
        '';


  installPhase =
    ''
      mkdir -p $out/lib
      mkdir -p $out/bin

      cp ${buildTargetDir}${assemblyJar} $out/lib
      cp ${buildTargetDir}${assemblyDepsJar} $out/lib
      
      cp ${start-script} $out/bin/start-s2-pipeline-acl;
      cp ${start-script} $out/bin/start-s2-pipeline-citeseer;
      cp ${start-script} $out/bin/start-s2-pipeline-all;
      
      wrapProgram $out/bin/start-s2-pipeline-acl \
        --set JAVA_HOME "${jre}" \
        --set PIPELINE_ASSEMBLY_JAR $out/lib/${assemblyJar} \
        --set PIPELINE_ASSEMBLY_DEPS_JAR $out/lib/${assemblyDepsJar} \
        --set PIPELINE_CONF_FILES acl/BuildIndexFromPdfs.conf

      wrapProgram $out/bin/start-s2-pipeline-citeseer \
        --set JAVA_HOME "${jre}" \
	--set PIPELINE_ASSEMBLY_JAR $out/lib/${assemblyJar} \
        --set PIPELINE_ASSEMBLY_DEPS_JAR $out/lib/${assemblyDepsJar} \
        --set PIPELINE_CONF_FILES citeseer/BuildIndexFromPdfs.conf

      wrapProgram $out/bin/start-s2-pipeline-all \
	--set JAVA_HOME "${jre}" \
	--set PIPELINE_ASSEMBLY_JAR $out/lib/${assemblyJar} \
        --set PIPELINE_ASSEMBLY_DEPS_JAR $out/lib/${assemblyDepsJar} \
        --set PIPELINE_CONF_FILES all-pdfs/BuildIndexFromPdfs.conf
    '';

  meta = with stdenv.lib; {
    homepage = "https://github.com/allenai/scholar";
    description = "the scholar pipeline";
  };
}
