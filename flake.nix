{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    devenv.url = "github:cachix/devenv";
    clj-nix.url = "github:jlesquembre/clj-nix";
    clj-nix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    cljfmt.url = "github:noblepayne/cljfmt-flake";
    cljfmt.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = {
    self,
    nixpkgs,
    devenv,
    clj-nix,
    treefmt-nix,
    cljfmt,
    ...
  } @ inputs: let
    supportedSystems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
    pkgsBySystem = nixpkgs.lib.getAttrs supportedSystems nixpkgs.legacyPackages;
    forAllPkgs = fn: nixpkgs.lib.mapAttrs (system: pkgs: (fn system pkgs)) pkgsBySystem;
    # treefmt configuration (cljfmt-flake has no aarch64-darwin package)
    cljfmtSupported = system: nixpkgs.lib.elem system ["x86_64-linux" "aarch64-linux"];
    treefmtEval = forAllPkgs (
      system: pkgs:
        treefmt-nix.lib.evalModule pkgs {
          projectRootFile = "flake.nix";
          programs.alejandra.enable = true;
          programs.cljfmt = (if cljfmtSupported system then {
            enable = true;
            package = cljfmt.packages.${system}.default;
          } else {
            enable = false;
          });
          programs.prettier.enable = true;
          programs.mdformat.enable = true;
        }
    );
  in {
    formatter = forAllPkgs (system: pkgs: treefmtEval.${system}.config.build.wrapper);

    checks = forAllPkgs (system: pkgs: {
      formatting = treefmtEval.${system}.config.build.check self;
    });

    devShells = forAllPkgs (system: pkgs': let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      testenv = devenv.lib.mkShell {
        inherit inputs pkgs;
        modules = [
          (
            {
              config,
              pkgs,
              ...
            }: {
              packages = [
                pkgs.clojure
              ];
              services.minio = {
                enable = true;
                accessKey = "s3accesskey";
                secretKey = "s3secretkey";
                buckets = ["testbucket"];
              };
              env = {
                ENV = "DEV";
              };
            }
          )
        ];
      };
      default = devenv.lib.mkShell {
        inherit inputs pkgs;
        modules = [
          (
            {
              config,
              pkgs,
              ...
            }: {
              # https://devenv.sh/reference/options/
              packages =
                [
                  pkgs.git
                  pkgs.babashka
                  pkgs.jet
                  pkgs.neovim
                  #pkgs.vscode
                  (pkgs.vscode-with-extensions.override {
                    vscodeExtensions = [
                      pkgs.vscode-extensions.betterthantomorrow.calva
                      pkgs.vscode-extensions.vscodevim.vim
                      pkgs.vscode-extensions.jnoortheen.nix-ide
                    ];
                  })
                ]
                ++ (builtins.attrValues treefmtEval.${system}.config.build.programs);

              languages.clojure.enable = true;
              services.minio = {
                enable = true;
                accessKey = "s3accesskey";
                secretKey = "s3secretkey";
                buckets = ["testbucket"];
              };

              # N.B. picks up quotes and inline comments
              dotenv.enable = true;

              env = {
                ENV = "DEV";
              };

              scripts.format.exec = ''
                nix fmt .
                if command -v cljfmt >/dev/null 2>&1; then
                  cljfmt fix src
                  cljfmt fix deps.edn
                fi
              '';
              scripts.lock.exec = ''
                nix flake lock
                nix run .#deps-lock
              '';
              scripts.update.exec = ''
                nix flake update
                nix run .#deps-lock
              '';
              scripts.build.exec = ''
                nix build .
              '';
              scripts.repl.exec = ''
                clojure -M:repl \
                        -m nrepl.cmdline \
                        --middleware "[cider.nrepl/cider-middleware]" \
                        -b 0.0.0.0 \
                        -p 9998
              '';
              scripts.tests.exec = ''
                clojure -M:test
              '';
              scripts.watch.exec = ''
                clojure -M:test/watch
              '';
              scripts.outdated.exec = ''
                clojure -Aoutdated -M -m "antq.core"
              '';
              scripts.scripts.exec = ''
                echo ${builtins.concatStringsSep " " (builtins.attrNames config.scripts)}
              '';

              enterShell = ''
                echo    "===================================================="
                echo "Type \`scripts\` for help and a list of available scripts."
                echo -n "Available scripts: "
                scripts
                echo    "===================================================="
                echo
                export SHELL=$OLDSHELL
              '';
            }
          )
        ];
      };
    });
    nixosModules = {
      default = {
        options,
        config,
        pkgs,
        ...
      }: {
        imports = [./module.nix];
        config.services.boostbox.package = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      };
    };

    packages = forAllPkgs (system: pkgs:
      {
        deps-lock = clj-nix.packages.${system}.deps-lock;
        default = clj-nix.lib.mkCljApp {
          inherit pkgs;
          modules = [
            {
              projectSrc = ./.;
              name = "com.noblepayne/boostbox";
              main-ns = "boostbox.boostbox";
            }
          ];
        };
      }
      // (nixpkgs.lib.optionalAttrs (nixpkgs.lib.hasSuffix "-linux" system) {
        container = pkgs.dockerTools.buildLayeredImage {
          name = "boostbox";
          tag = "latest";
          config = {
            Entrypoint = ["${self.packages.${system}.default}/bin/boostbox"];
            ExposedPorts = {
              "8080" = {};
            };
          };
        };
      })
    );
  };
}
