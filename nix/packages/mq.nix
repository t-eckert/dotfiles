# mq - a jq-like query language for Markdown
# Not in nixpkgs, so built from source here.
{ lib, rustPlatform, fetchFromGitHub }:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "mq";
  version = "0.7.0";

  src = fetchFromGitHub {
    owner = "harehare";
    repo = "mq";
    tag = "v${finalAttrs.version}";
    hash = "sha256-33MTLqMxxnOtqiBNqov9H91oK11OAqusAXMAuM4u7vQ=";
  };

  cargoHash = "sha256-fxKi1X0lzv+TLSH/HerUn9tOov0++ug8KeSUGhTord4=";

  # The workspace also contains wasm, web-api and fuzz members that we don't
  # want; mq-run is the CLI crate and produces the `mq` binary.
  cargoBuildFlags = [ "-p" "mq-run" ];
  cargoTestFlags = [ "-p" "mq-run" ];

  meta = {
    description = "jq-like Markdown query language for command-line processing";
    homepage = "https://github.com/harehare/mq";
    license = lib.licenses.mit;
    mainProgram = "mq";
    platforms = lib.platforms.unix;
  };
})
