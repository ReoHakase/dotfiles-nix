{
  lib,
  stdenv,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule (finalAttrs: {
  pname = "mole";
  version = "1.36.2";

  src = fetchFromGitHub {
    owner = "tw93";
    repo = "Mole";
    rev = "V${finalAttrs.version}";
    hash = "sha256-8GvS4utzQ7ZOtnSlk37FGR52OYPn5grJb1FVr5LlU8M=";
  };

  vendorHash = "sha256-2UhKlei3yUJJkvavxUEQFcnaSekycaXymL29b7+Q0aw=";

  postPatch = ''
    patchShebangs .
  '';

  buildPhase = ''
    runHook preBuild

    go build -ldflags="-s -w" -o bin/analyze-go ./cmd/analyze
    go build -ldflags="-s -w" -o bin/status-go ./cmd/status

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/libexec/mole $out/bin
    cp -R . $out/libexec/mole/

    for command in mole mo; do
      printf '%s\n' '#!${stdenv.shell}' "exec \"$out/libexec/mole/mole\" \"\$@\"" > "$out/bin/$command"
      chmod +x "$out/bin/$command"
    done

    runHook postInstall
  '';

  meta = {
    description = "Deep clean and optimize your Mac";
    homepage = "https://github.com/tw93/Mole";
    license = lib.licenses.mit;
    mainProgram = "mo";
    platforms = lib.platforms.darwin;
    broken = !stdenv.hostPlatform.isDarwin;
  };
})
