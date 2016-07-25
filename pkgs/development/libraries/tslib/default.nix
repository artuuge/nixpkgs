{ stdenv
, fetchFromGitHub
, libtool
, autoconf
, automake
}:
stdenv.mkDerivation rec {
  name = "tslib-${version}";
  version = "1.1";

  src = fetchFromGitHub {
    owner = "kergoth";
    repo = "tslib";
    rev = "0a11148eff4111afc8b241b59fdca541fcfa69c1";
    sha256 = "0pdnzwzq6vrkxs1clbq01qdkl4w2g8l8syrj33bbcmz9w8ypwg6d";
  };

  configurePhase = ''
    libtoolize
    ./autogen.sh
    ./configure --prefix=$out
  '';

  buildInputs = [
    libtool
    autoconf
    automake
  ];

  meta = with stdenv.lib; {
    homepage = https://github.com/kergoth/tslib;
    description = "Touchscreen access library";
    license = licenses.gpl2;
    maintainers = with maintainers; [ artuuge ];
  };
}

