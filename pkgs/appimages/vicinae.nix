{ lib, fetchurl, appimageTools }:

appimageTools.wrapType2 {
  pname = "vicinae";
  version = "0.20.12";
  src = fetchurl {
    url = "https://github.com/vicinaehq/vicinae/releases/download/v0.20.12/Vicinae-x86_64.AppImage";
    hash = "sha256-qifj8tiscJaLOjRIm+hlPVXZAzdhz9ZIUhFz3Y5FbtI=";
  };
  meta = with lib; {
    description = "Vicinae desktop client (upstream AppImage)";
    homepage = "https://github.com/vicinaehq/vicinae";
    license = licenses.gpl3Only;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
