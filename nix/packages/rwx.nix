# rwx - CLI for the RWX CI/CD platform (Honeycomb's CI for hound).
#
# Not in nixpkgs, and unlike mq this is NOT built from source: the binary embeds
# a JS language server bundled from a separate repo (rwx-cloud/language-server)
# via npm. `internal/lsp/bundle/` ships only a .gitignore, so `go build` alone
# produces nothing usable and a source build would mean nesting an npm bundle in
# here. Upstream's own install instructions hand out the release binary, so that
# is what this does.
#
# To bump: set version, then re-hash each platform with
#   nix store prefetch-file --json --hash-type sha256 \
#     https://github.com/rwx-cloud/rwx/releases/download/v<version>/rwx-<platform>
{ lib, stdenv, fetchurl, autoPatchelfHook, installShellFiles }:

let
  version = "3.25.0";

  # Upstream's asset naming, keyed by nix system double.
  platforms = {
    aarch64-darwin = {
      asset = "rwx-darwin-aarch64";
      hash = "sha256-PagmmeK3efrbPQV0dA3ciBJgZhgDDl5StkFaeyx6uzY=";
    };
    x86_64-darwin = {
      asset = "rwx-darwin-x86_64";
      hash = "sha256-1G6sm1LiUBIteaduF6Ngh10LCoSBIPgo65oAjUXxJTk=";
    };
    aarch64-linux = {
      asset = "rwx-linux-aarch64";
      hash = "sha256-95RfgqG+KBpjUJSIlawV8KwcXviQ+zx9Dqq+Fp0FiD8=";
    };
    x86_64-linux = {
      asset = "rwx-linux-x86_64";
      hash = "sha256-62tEiJFOd1GpThlPxfc+/XSitNxKzuSXCZO5hsaX4pE=";
    };
  };

  inherit (stdenv.hostPlatform) system;

  platform = platforms.${system} or (throw "rwx: no release binary for ${system}");

in stdenv.mkDerivation {
  pname = "rwx";
  inherit version;

  src = fetchurl {
    url = "https://github.com/rwx-cloud/rwx/releases/download/v${version}/${platform.asset}";
    inherit (platform) hash;
  };

  # The download is a bare binary, not an archive.
  dontUnpack = true;

  # Linux release binaries link against glibc; Darwin ones need no patching.
  nativeBuildInputs = [ installShellFiles ]
    ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/rwx
    runHook postInstall
  '';

  # Completions must be generated in postFixup, not installPhase: on Linux the
  # binary is not runnable until autoPatchelfHook has done its work.
  postFixup = ''
    installShellCompletion --cmd rwx \
      --bash <($out/bin/rwx completion bash) \
      --zsh <($out/bin/rwx completion zsh) \
      --fish <($out/bin/rwx completion fish)
  '';

  # Cheap proof the binary actually runs on this platform before it lands on PATH.
  doInstallCheck = true;
  installCheckPhase = ''
    $out/bin/rwx --version
  '';

  meta = {
    description = "CLI for the RWX CI/CD platform";
    homepage = "https://www.rwx.com/docs/rwx/cli";
    license = lib.licenses.mit;
    mainProgram = "rwx";
    platforms = lib.attrNames platforms;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
