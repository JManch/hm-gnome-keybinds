{
  description = "Declarative Gnome keybinds with Nix and Home Manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      homeManagerModules.default = self.homeManagerModules.gnome-keybinds;
      homeManagerModules.gnome-keybinds = import ./module.nix;

      packages.${system}.generate-schemas = pkgs.writeShellApplication {
        name = "generate-schemas";
        runtimeInputs = [ ];
        text = # bash
          ''
            schemas=(
              "org.gnome.desktop.wm.keybindings"
              "org.gnome.settings-daemon.plugins.media-keys"
              "org.gnome.shell.keybindings"
              "org.gnome.mutter.keybindings"
            )

            # https://github.com/NixOS/nixpkgs/issues/114514
            export GSETTINGS_SCHEMA_DIR=${pkgs.glib.passthru.getSchemaPath pkgs.mutter}

            output="schemas.nix";
            if [ -f "./$output" ]; then echo "schemas.nix file already exists"; exit 1; fi
            echo "{" > "$output"

            for schema in "''${schemas[@]}"; do
              keys=$(gsettings list-keys "$schema" | grep -Ev '^custom-keybindings$|-static$' | sed -e 's/\(.*\)/"\1"/')
              schema_path="''${schema//./\/}"
              {
                echo "\"$schema_path\" = ["
                echo "$keys"
                echo "];"
              } >> "$output"
            done

            echo "}" >> "$output"
          '';
      };
    };
}
