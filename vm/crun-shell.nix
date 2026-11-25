# Cross-build shell for crun on aarch64 (see build-crun.sh). Pinned by the nixpkgs in the
# flake registry of nix-portable; crun's own flake only builds static release binaries.
let
  pkgs = (builtins.getFlake "nixpkgs").legacyPackages.x86_64-linux;
  cross = pkgs.pkgsCross.aarch64-multiplatform;
in
cross.mkShell {
  depsBuildBuild = [ pkgs.buildPackages.stdenv.cc ];
  nativeBuildInputs = with pkgs.buildPackages; [ autoconf automake libtool pkg-config python3 gperf go-md2man git which m4 ];
  buildInputs = with cross; [ json_c libcap libseccomp systemdLibs yajl ];
}
