{
  description = "FLM Q4NX Converter — converts GGUF models to Q4NX format";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ { flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      perSystem = { pkgs, ... }:
        let
          python = pkgs.python313;

          runtimeDeps = ps: with ps; [
            torch
            einops
            numpy
            safetensors
            mpmath
            gguf
          ];

          q4nx-converter = python.pkgs.buildPythonApplication {
            pname = "flm-q4nx-converter";
            version = "0.1.0";
            pyproject = true;

            src = self;

            build-system = with python.pkgs; [ setuptools ];
            dependencies = runtimeDeps python.pkgs;

            postInstall = ''
              mkdir -p $out/share/q4nx
              cp -r ${self}/configs $out/share/q4nx/configs
            '';

            makeWrapperArgs = [
              "--set Q4NX_CONFIG_DIR \${out}/share/q4nx/configs"
            ];

            meta.mainProgram = "convert";
          };
        in
        {
          packages.convert = q4nx-converter;

          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              python
              uv
              git
            ];

            env = {
              UV_PYTHON_PREFERENCE = "only-system";
              UV_PYTHON = "${python}/bin/python3";
            };

            shellHook = ''
              echo "FLM Q4NX Converter dev environment"
              echo "Run 'uv sync' to install Python dependencies"
            '';
          };
        };
    };
}
