{
  lib,
  stdenvNoCC,
  texlivePackages,
}:

stdenvNoCC.mkDerivation {
  pname = "harano-aji-fonts";
  inherit (texlivePackages.haranoaji) version;

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 ${texlivePackages.haranoaji.tex}/fonts/opentype/public/haranoaji/*.otf \
      -t "$out/share/fonts/opentype/haranoaji"

    runHook postInstall
  '';

  meta = {
    description = "Harano Aji OpenType fonts";
    homepage = "https://ctan.org/pkg/haranoaji";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
}
