{ lib, config, ... }:
let
  inherit (lib)
    types
    mkOption
    mapAttrs
    foldl'
    optional
    foldlAttrs
    imap0
    listToAttrs
    optionalAttrs
    nameValuePair
    attrNames
    ;
  cfg = config.gnome-keybinds;
  schemas = import ./schemas.nix;
in
{
  options.gnome-keybinds = {
    binds = foldlAttrs (
      binds: schema: schemaBinds:
      (
        binds
        // (foldl' (
          acc: bind:
          acc
          // {
            ${bind} = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "<Super>1";
              description = "Binding for ${bind}. Set to empty string to remove the default binding.";
            };
          }
        ) { } schemaBinds)
      )
    ) { } schemas;

    custom = mkOption {
      type = types.listOf (
        types.submodule {
          options = {
            name = mkOption { type = types.str; };
            binding = mkOption { type = types.str; };
            command = mkOption { type = types.str; };
          };
        }
      );
      default = [ ];
      example = [
        {
          name = "Terminal";
          binding = "<Super>Return";
          command = "alacritty";
        }
      ];
    };
  };

  config.dconf.settings =
    let
      schemaBinds = mapAttrs (
        schema: binds:
        foldl' (
          acc: bind:
          let
            key = cfg.binds.${bind};
          in
          acc // optionalAttrs (key != null) { ${bind} = optional (key != "") key; }
        ) { } binds
      ) schemas;

      customBinds = listToAttrs (
        imap0 (
          i: bind:
          nameValuePair "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${toString i}" bind
        ) cfg.custom
      );

      customBindDefs = {
        "org/gnome/settings-daemon/plugins/media-keys".custom-keybindings = map (path: "/${path}/") (
          attrNames customBinds
        );
      };
    in
    schemaBinds // customBinds // customBindDefs;
}
