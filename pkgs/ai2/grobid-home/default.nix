{ stdenv, fetchurl, unzip, writeText, bash, pdf2xml, xpdf, libxml2,  makeWrapper, grobid-native-libs }:
let
  grobidProperties = writeText "grobid.properties" (import ./grobid.properties.nix {
    grobidTempPath = "/tmp/grobid";
    grobidNativeLibsPath = "${grobid-native-libs}";
    pdf2xmlMemoryLimitMb = 1024;
  });
in
stdenv.mkDerivation rec {
  name = "grobid-home-${version}";
  version = "2015-07-01";
  src = fetchurl {
    url = "https://github.com/allenai/grobid/zipball/${version}";
    sha256 = "0mlsrciy9rr7nxcfbbg5vzri612xk9wi43my9hpr8416isa4mch3";
    name = "grobid-src-${version}.zip";
  };

  buildInputs = [unzip bash makeWrapper pdf2xml];
  
  installPhase = ''
    mkdir -p $out
    rm -rf ./grobid-home/lib
    mv ./grobid-home/* $out
    
    cp ${grobidProperties} $out/config/grobid.properties

    rm -rf $out/pdf2xml/*
    mkdir $out/pdf2xml/lin-64
    cp -R ${pdf2xml}/bin/* $out/pdf2xml/lin-64
   '';
  
  meta = with stdenv.lib; {
    homepage = "https://github.com/allenai/grobid";
    description = "the allenai grobid home";
  };
}
