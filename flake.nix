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
            src = ./tools/sacd_extract;
            nativeBuildInputs = [ cmake libxml2 libiconv ];
          };
        };

        packages = forAllSystems (system:
          {
            inherit (nixpkgsFor.${system}) sacd-extract;
          });

        defaultPackage = forAllSystems (system: self.packages.${system}.sacd-extract);
      };
}
