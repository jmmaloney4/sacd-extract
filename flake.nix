{
  inputs.nixpkgs.url = "nixpkgs/nixos-21.05";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });
    in
      {
        overlay = final: prev: {
          sacd-extract = with final; stdenv.mkDerivation rec {
            name = "sacd-extract";
            src = ./.;
            nativeBuildInputs = [ cmake libxml2 libiconv ];
            configurePhase = ''
              cd ./tools/sacd_extract
              cmake .
            '';
            buildPhase = "make -j $NIX_BUILD_CORES";
            installPhase = ''
              mkdir -p $out/bin
              mv sacd_extract $out/bin
            '';
          };

          docker = with final; pkgs.dockerTools.buildLayeredImage {
            name = "sacd-extract";
            contents = [
              sacd-extract
            ];
          };
        };

        packages = forAllSystems (system:
          {
            inherit (nixpkgsFor.${system}) sacd-extract;
            inherit (nixpkgsFor.${system}) docker;
          });

        defaultPackage = forAllSystems (system: self.packages.${system}.sacd-extract);
      };
}
