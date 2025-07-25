#! /usr/bin/env nix-shell
#! nix-shell -i bash -p coreutils haskellPackages.cabal2nix-unstable git -I nixpkgs=.

set -euo pipefail

self=$0

print_help () {
cat <<END_HELP
Usage: $self [options]

Options:
   --do-commit    Commit changes to this file.
   -f | --fast    Do not update the transitive-broken.yaml file.
   -h | --help    Show this help.

This script is used to regenerate nixpkgs' Haskell package set, using the
tool hackage2nix from the nixos/cabal2nix repo. hackage2nix looks at the
config files in pkgs/development/haskell-modules/configuration-hackage2nix
and generates a Nix expression for package version specified there, using the
Cabal files from the Hackage database (available under all-cabal-hashes) and
its companion tool cabal2nix.

Unless --fast is used, it will then use the generated nix expression by
running regenerate-transitive-broken-packages.sh which updates the transitive-broken.yaml
file. Then it re-runs hackage2nix.

Related scripts are update-hackage.sh, for updating the snapshot of the
Hackage database used by hackage2nix, and update-cabal2nix-unstable.sh,
for updating the version of hackage2nix used to perform this task.

Note that this script doesn't gcroot anything, so it may be broken by an
unfortunately timed nix-store --gc.

END_HELP
}

DO_COMMIT=0
REGENERATE_TRANSITIVE=1

options=$(getopt -o "fh" -l "help,fast,do-commit" -- "$@")

eval set -- "$options"

while true; do
   case "$1" in
      --do-commit)
         DO_COMMIT=1
         ;;
      -f|--fast)
         REGENERATE_TRANSITIVE=0
         ;;
      -h|--help)
         print_help
         exit 0
         ;;
      --)
         break;;
      *)
         print_help
         exit 1
         ;;
   esac
   shift
done

HACKAGE2NIX="${HACKAGE2NIX:-hackage2nix}"

config_dir=pkgs/development/haskell-modules/configuration-hackage2nix

run_hackage2nix() {
"$HACKAGE2NIX" \
   --hackage "$unpacked_hackage" \
   --preferred-versions <(for n in "$unpacked_hackage"/*/preferred-versions; do cat "$n"; echo; done) \
   --nixpkgs "$PWD" \
   --config "$compiler_config" \
   --config "$config_dir/main.yaml" \
   --config "$config_dir/stackage.yaml" \
   --config "$config_dir/broken.yaml" \
   --config "$config_dir/transitive-broken.yaml"
}

echo "Obtaining Hackage data …"
extraction_derivation='with import ./. {}; runCommandLocal "unpacked-cabal-hashes" { } "tar xf ${all-cabal-hashes} --strip-components=1 --one-top-level=$out"'
unpacked_hackage="$(nix-build -E "$extraction_derivation" --no-out-link)"

echo "Generating compiler configuration …"
compiler_config="$(nix-build -A haskellPackages.cabal2nix-unstable.compilerConfig --no-out-link)"

echo "Running hackage2nix to regenerate pkgs/development/haskell-modules/hackage-packages.nix …"
run_hackage2nix

if [[ "$REGENERATE_TRANSITIVE" -eq 1 ]]; then

echo "Regenerating transitive-broken.yaml … (pass --fast to $self to skip this step)"

maintainers/scripts/haskell/regenerate-transitive-broken-packages.sh

echo "Running hackage2nix again to reflect changes in transitive-broken.yaml …"

run_hackage2nix

fi

nixfmt pkgs/development/haskell-modules/hackage-packages.nix

if [[ "$DO_COMMIT" -eq 1 ]]; then
git add pkgs/development/haskell-modules/configuration-hackage2nix/transitive-broken.yaml
git add pkgs/development/haskell-modules/hackage-packages.nix
git commit -F - << EOF
haskellPackages: regenerate package set based on current config

This commit has been generated by maintainers/scripts/haskell/regenerate-hackage-packages.sh
EOF
fi

echo "Regeneration of hackage-packages.nix finished."
