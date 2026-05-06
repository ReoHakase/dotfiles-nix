{
  lib,
  fetchFromGitHub,
  rustPlatform,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "similarity";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "mizchi";
    repo = "similarity";
    rev = "v${finalAttrs.version}";
    hash = "sha256-xYA1o4nmZLo0TY56KOtm2eTR9xL4/uEVTKmFaQT+kCQ=";
  };

  cargoHash = "sha256-r/9Yq1h8i7OWMicK9z36TzUTQRDOk6cND+5RvL045yA=";

  postInstall = ''
    rm -f $out/bin/test_parser
  '';

  meta = {
    description = "AST-based code similarity tools (similarity-ts, similarity-py, similarity-rs, …)";
    homepage = "https://github.com/mizchi/similarity";
    license = lib.licenses.mit;
    mainProgram = "similarity-ts";
  };
})
