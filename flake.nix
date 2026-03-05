{
  description = "Python GTK4/Libadwaita development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        python = pkgs.python313;
        pythonEnv = python.withPackages (ps: [
          ps.pygobject3
          ps.pycairo
        ]);
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pythonEnv
            pkgs.gtk4
            pkgs.libadwaita
            pkgs.gobject-introspection
            pkgs.glib
            pkgs.cairo
          ];

          shellHook = ''
            export GI_TYPELIB_PATH="${pkgs.gtk4}/lib/girepository-1.0:${pkgs.libadwaita}/lib/girepository-1.0:${pkgs.glib.out}/lib/girepository-1.0:${pkgs.pango.out}/lib/girepository-1.0:${pkgs.gdk-pixbuf}/lib/girepository-1.0:${pkgs.graphene}/lib/girepository-1.0:${pkgs.harfbuzz}/lib/girepository-1.0:${pkgs.gobject-introspection}/lib/girepository-1.0"
            export PYTHONPATH="${pythonEnv}/${python.sitePackages}"

            # Write .env for VSCode so it doesn't depend on process inheritance
            cat > .env <<EOF
            GI_TYPELIB_PATH=$GI_TYPELIB_PATH
            PYTHONPATH=$PYTHONPATH
            EOF

            echo "Python GTK4/Libadwaita development environment"
            echo "Python version: $(python --version)"
            echo "Python path: $(which python)"
          '';
        };
      }
    );
}
