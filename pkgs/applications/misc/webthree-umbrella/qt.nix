{ stdenv
, fetchurl
, coreutils
, pkgconfig
, zlib
, libjpeg
, libpng
, dbus
, libproxy
, glib
, icu
, mesa
, fontconfig
, libxkbcommon
, libinput
, libX11
, libxcb
, xcbutilwm
, xcbutilimage
, xcbutilkeysyms
, libXrender
, libXi
, libXext
, libXfixes
, xcbutilrenderutil
, double_conversion
, harfbuzz
, openssl
, pcre16
, libdrm
, perl
, tslib
, python
, bash
, libcap
, libvpx
, snappy
, srtp
, minizip
, libwebp
, libxml2
, libxslt
, libevent
, jsoncpp
, libopus
, protobuf
, nspr 
, nss
, libXcomposite
, libXcursor
, libXrandr
, libXScrnSaver 
, libXtst
, libXdamage
, gperf
, bison
, pciutils
, which
, git
, re2c
, alsaLib
}:
let
  major_minor = "5.7";
  version = "${major_minor}.0";
  versionFull = "${version}";
  mirror_prefix = "http://download.qt.io/official_releases/qt/${major_minor}/${versionFull}/submodules";
in
stdenv.mkDerivation rec {
  name = "qt_cpp_ethereum_gui-${version}";

  srcs = [
    (fetchurl {
      url = "${mirror_prefix}/qtbase-opensource-src-${versionFull}.tar.gz";
      sha256 = "3520a3979b139a7714cb0a2a6e8b61f8cd892872abf473f91b7b05c21eff709c";
    })
    (fetchurl {
      url = "${mirror_prefix}/qtdeclarative-opensource-src-${versionFull}.tar.gz";
      sha256 = "147cb36407672f134f4707e1fee7ba7cb697b7121aeaf7f5598833eed078f79a";
    })
    (fetchurl {
      url = "${mirror_prefix}/qtquickcontrols-opensource-src-${versionFull}.tar.gz";
      sha256 = "cca84356504244360908a4732a7639290b778ef71a8baa90dbc87bdb1aedfd29";
    })
    (fetchurl {
      url = "${mirror_prefix}/qtquickcontrols2-opensource-src-${versionFull}.tar.gz";
      sha256 = "4a3bd31d6d8b0e3e9f1dd8ade5926427ee71807d0c72da98ae0219a8cfa4404c";
    })
    (fetchurl {
      url = "${mirror_prefix}/qtgraphicaleffects-opensource-src-${versionFull}.tar.gz";
      sha256 = "601129a10c4703a2a14d4452f7400a36a71610c1b9bc633e5459e1c3e72376b3";
    })
    (fetchurl {
      url = "${mirror_prefix}/qtwebchannel-opensource-src-${versionFull}.tar.gz"; 
      sha256 = "6ba3299c30ab3ec811a786aa92a4d8defffa832b700f3fbb268a06c6d21930da";
    })
    (fetchurl {
      url = "${mirror_prefix}/qtwebengine-opensource-src-${versionFull}.tar.gz";
      sha256 = "35852a0af8c57f0c6b8f46c57a3e82c3f6fb59031ff644a7788cc1f3c914405a";
    })
  ];

  sourceRoot = ".";

  patchPhase = ''
    for f in $(grep -rnwl . -e "/bin/pwd"); do
      sed -i -re "s#([\s \`])/bin/pwd#\1${coreutils}/bin/pwd#g" $f;
    done;

    for f in $(grep -rnwl . -e "/bin/ls"); do
      sed -i -re "s#(readelf\ \-l\ )/bin/ls#\1${coreutils}/bin/ls#g" $f;
    done;

    for f in $(find | grep "ppoll\.cpp\|pollts\.cpp"); do 
      sed -i -re "s/nullptr/0/g" $f; 
    done;

    for f in $(grep -rnwl . -e "#\!/usr/bin/env perl"); do
      sed -i -re "s@#\!/usr/bin/env perl@#\!${perl}/bin/perl@g" $f; 
    done;

    pushd qtwebengine-opensource-src-${version}
    for f in $(grep -rnwl . -e "/bin/echo"); do
      sed -i.bak0 -re "s#/bin/echo#${coreutils}/bin/echo#g" $f
    done

    for f in $(grep -rnwl . -e "#\!.*python"); do 
      sed -i.bak1 -re "1s@^#\!.*python(.*)\$@#\!${python}/bin/python\1@g" $f
    done

    for f in $(grep -rnwl . -e "#\!.*bash"); do 
      sed -i.bak2 -re "1s@^#\!.*bash(.*)\$@#\!${bash}/bin/bash\1@g" $f
    done
    popd
  '';

  configureFlags = [
    "--opensource"
    "--confirm-license"
    "--verbose"
    "--no-openvg"
    "--no-sql-mysql"
    "--no-sql-odbc"
    "--no-sql-oci"
    "--no-sql-psql"
    "--no-sql-tds"
    "--no-sql-db2"
    "--no-sql-sqlite"
    "--no-sql-ibase"
    "--no-sql-sqlite2"
    "--no-pulseaudio"
    "--no-alsa"
    "--no-cups"
    "--no-mtdev"
    "--no-gbm"
    "--no-gstreamer"
    "--no-eglfs"
    "--no-mirclient"
  ];

  configurePhase = ''
    mkdir -p build_base && pushd "$_"

    ../qtbase-opensource-src-${version}/configure --prefix=$out $configureFlags --opengl=desktop

    runHook hook_base
  '';

  buildPhase = ''
    make -j $(nproc)
  '';

  installPhase = ''
    make install
    popd
    runHook postInstall
  '';

  hook_base = ''
    sed -i.bak -re "/\-strip.*\.pl/d" Makefile
  '';
  hook_declarative = "";
  hook_quickcontrols = "";
  hook_quickcontrols2 = "";
  hook_graphicaleffects = "";
  hook_webchannel = ''
    sed -i.bak -re "/\-strip.*\.js/d" examples/webchannel/qwclient/Makefile
  '';
  hook_webengine = "";

  postInstall = ''
    function addQtModule {
      mkdir -p "build_"$1 && pushd "$_"
      $out/bin/qmake "../qt"$1"-opensource-src-${version}/qt"$1".pro"
      make -j $(nproc)
      runHook "hook_"$1
      make install
      popd
    }

    for m in declarative quickcontrols quickcontrols2 graphicaleffects webchannel webengine; do
      addQtModule $m
    done

    pushd $out/lib/pkgconfig
    cp Qt5WebEngineCore.pc Qt5WebEngineCore.pc.orig
    sed -re "s/\ /\\n/g" Qt5WebEngineCore.pc > Qt5WebEngineCore.pc.lines
    echo $(sed -re "s#/.*build_webengine#$out#g" Qt5WebEngineCore.pc.lines) | sed -re "s/[a-zA-Z_.]*[:=]/\n&/g" | sed -re "s/Name:/\n\n&/g" | sed '1d' > Qt5WebEngineCore.pc

    echo $(for f in $(cat Qt5WebEngineCore.pc.lines | grep "\.a"); do 
      echo $f | sed -re "s#/.*build_webengine/##g"; 
    done) > Qt5WebEngineCore.pc.a_files
    popd

    pushd build_webengine
    for f in $(cat $out/lib/pkgconfig/Qt5WebEngineCore.pc.a_files); do
    mkdir -p $out/$(dirname $f)
    cp -p $f "$_"
    done
    popd
  '';

  propagatedBuildInputs = [
    pkgconfig
    zlib
    libjpeg
    libpng
    dbus
    libproxy
    glib
    icu
    mesa
    fontconfig
    libxkbcommon
    libinput
    libX11
    libxcb
    xcbutilwm
    xcbutilimage
    xcbutilkeysyms
    libXrender
    libXi
    libXext
    libXfixes
    xcbutilrenderutil
    double_conversion
    harfbuzz
    openssl
    pcre16
    libdrm
    perl
    tslib
    python
    bash
    libcap
    libvpx
    snappy
    srtp
    minizip
    libwebp
    libxml2
    libxslt
    libevent
    jsoncpp
    libopus
    protobuf
    nspr 
    nss
    libXcomposite
    libXcursor
    libXrandr
    libXScrnSaver 
    libXtst
    libXdamage
    gperf
    bison
    pciutils
    which
    git
    re2c
    alsaLib
  ];

}

