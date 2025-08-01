{
  lib,
  autoPatchelfHook,
  bzip2,
  cairo,
  fetchurl,
  gdk-pixbuf,
  glibc,
  pango,
  gtk2,
  kcoreaddons,
  ki18n,
  kio,
  kservice,
  stdenv,
  runtimeShell,
  unzip,
}: let
  pname = "bcompare";
  version = "5.1.2.31185";
  throwSystem = throw "Unsupported system: ${stdenv.hostPlatform.system}";

  srcs = {
    x86_64-linux = fetchurl {
      url = "https://www.scootersoftware.com/${pname}-${version}_amd64.deb";
      sha256 = "fdb30ad1f4bb2699c3c9d140b947f815d497dee8c8296292878d83b5e25197f1";
    };
  };

  src = srcs.${stdenv.hostPlatform.system} or throwSystem;

  meta = with lib; {
    description = "GUI application that allows to quickly and easily compare files and folders";
    longDescription = ''
      Beyond Compare is focused. Beyond Compare allows you to quickly and easily compare your files and folders.
      By using simple, powerful commands you can focus on the differences you're interested in and ignore those you're not.
      You can then merge the changes, synchronize your files, and generate reports for your records.
    '';
    homepage = "https://www.scootersoftware.com";
    sourceProvenance = with sourceTypes; [binaryNativeCode];
    license = licenses.unfree;
    maintainers = with maintainers; [
      ktor
      arkivm
    ];
    platforms = builtins.attrNames srcs;
    mainProgram = "bcompare";
  };
in
  stdenv.mkDerivation {
    inherit
      pname
      version
      src
      meta
      ;
    unpackPhase = ''
      ar x $src
      tar xfz data.tar.gz
    '';

    installPhase = ''
      mkdir -p $out/{bin,lib,share}

      cp -R usr/{bin,lib,share} $out/

      # Remove library that refuses to be autoPatchelf'ed
      rm $out/lib/beyondcompare/ext/bcompare_ext_kde.amd64.so

      substituteInPlace $out/bin/${pname} \
        --replace "/usr/lib/beyondcompare" "$out/lib/beyondcompare" \
        --replace "ldd" "${glibc.bin}/bin/ldd" \
        --replace "/bin/bash" "${runtimeShell}"

      # Create symlink bzip2 library
      ln -s ${bzip2.out}/lib/libbz2.so.1 $out/lib/beyondcompare/libbz2.so.1.0
    '';

    nativeBuildInputs = [autoPatchelfHook];

    buildInputs = [
      (lib.getLib stdenv.cc.cc)
      gtk2
      pango
      cairo
      kio
      kservice
      ki18n
      kcoreaddons
      gdk-pixbuf
      bzip2
    ];

    dontBuild = true;
    dontConfigure = true;
    dontWrapQtApps = true;
  }
