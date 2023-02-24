{
  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }: flake-utils.lib.eachSystem flake-utils.lib.allSystems (system: 
    let
      # supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      # forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      # Nixpkgs instantiated for supported system types.
      # nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; overlays = [ self.overlay ]; });
      pkgs = import nixpkgs { inherit system; };
    in
      rec {
        packages = rec {
          sacd-extract = pkgs.stdenv.mkDerivation rec {
              name = "sacd_extract";
              src = ./.;
              nativeBuildInputs = with pkgs; [ cmake libxml2 libiconv ];
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

          docker = pkgs.dockerTools.buildLayeredImage {
              name = "sacd_extract";
              contents = with pkgs; [
                nix
                bashInteractive
                coreutils-full
                cacert.out
                iana-etc
                
                sacd-extract
              ];
            };
          default = sacd-extract;
        };

        apps = flake-utils.lib.mkApp {
          drv = packages.default;
          exePath = "/bin/sacd_extract";
        };        
      });
}
