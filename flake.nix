{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    zmk-nix = {
      url = "github:lilyinstarlight/zmk-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zephyr-nix = {
      url = "github:adisbladis/zephyr-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, zmk-nix, zephyr-nix }: let
    forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ];
  in {
    packages = forAllSystems (system: let
      inherit (zmk-nix.legacyPackages.${system}) buildKeyboard buildSplitKeyboard;
      zmkPackages = zmk-nix.packages.${system};

      zephyrSdk = zephyr-nix.packages.${system}.sdk-0_16.override {
        targets = [ "arm-zephyr-eabi" ];
      };

      common = {
        src = nixpkgs.lib.fileset.toSource {
          root = ./.;
          fileset = ./config;
        };
        board = "nice_nano_v2";
        zephyrDepsHash = "sha256-o6CwJBFFMo9/dIR2ljgZnu15unG3BhGdSw6Z4/uOdz0=";
        env = {
          ZEPHYR_TOOLCHAIN_VARIANT = "zephyr";
          ZEPHYR_SDK_INSTALL_DIR = "${zephyrSdk}";
        };
      };
    in rec {
      default = firmware;

      firmware = buildSplitKeyboard (common // {
        name = "lotus58";
        shield = {
          left = "lotus58_left";
          right = "lotus58_right nice_view_adapter nice_view_gem";
        };
        centralPart = "right";
      });

      settings-reset = buildKeyboard (common // {
        name = "settings-reset";
        shield = "settings_reset";
        inherit (firmware) westDeps;
      });

      flash = zmkPackages.flash.override { inherit firmware; };
      flash-settings-reset = zmkPackages.flash.override { firmware = settings-reset; };

      inherit (zmkPackages) update;
    });
  };
}
