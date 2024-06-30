{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { nixpkgs
    , flake-utils
    , ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
        };
        nativeBuildInputs = with pkgs; [ go ];
        buildInputs = with pkgs; [ ];
      in
      rec {
        devShells.default = pkgs.mkShell {
          inherit nativeBuildInputs;
          buildInputs = buildInputs ++ (with pkgs; [
            gopls
            (vscode-with-extensions.override {
              vscodeExtensions = with vscode-extensions; [
                golang.go
              ];
            })
          ]);
        };

        packages.default = pkgs.buildGoModule rec {
          inherit buildInputs;
          name = "handy-sshd";
          src = ./.;
          vendorHash = null;
          postInstall = ''
            mv $out/bin/main $out/bin/${name}
          '';
        };

        overlays.default = final: prev: {
          handy-sshd = packages.${system}.default;
        };
      }
    );
}
