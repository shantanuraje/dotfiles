# DISABLED: Custom Gemini CLI Package Definition
# 
# This custom package definition has been disabled due to build issues.
# We are now using the gemini-cli package from nixpkgs instead.
#
# To re-enable this custom package:
# 1. Uncomment the package definition below
# 2. Update the hashes using the get-gemini-hashes.sh script
# 3. Update the laptop-samsung.nix to use the custom package again
#
# Original package definition preserved for reference but commented out.

# { lib, buildNpmPackage, fetchFromGitHub, nodejs }:
# 
# buildNpmPackage rec {
#   pname = "gemini-cli";
#   version = "1.0.0";
#   
#   src = fetchFromGitHub {
#     owner = "google-gemini";
#     repo = "gemini-cli";
#     rev = "main";
#     hash = "sha256-BHw6LEtRubSlcUDAcrGB5i1HlAJTuX3PW3aT8+3NA28=";
#   };
#   
#   npmDepsHash = "sha256-tzVmMiHP24qKDJZYHLmGZpFZ2Y4uExassO3v3syrl2s=";
#   
#   buildInputs = [ nodejs ];
#   makeCacheWritable = true;
#   npmFlags = [ "--legacy-peer-deps" "--offline" "--cache-max" "0" ];
#   
#   dontFixup = false;
#   preFixup = ''
#     find $out -type l -exec test ! -e {} \; -delete || true
#   '';
#   
#   meta = with lib; {
#     description = "A command-line AI workflow tool by Google";
#     homepage = "https://github.com/google-gemini/gemini-cli";
#     license = licenses.asl20;
#     platforms = platforms.all;
#     mainProgram = "gemini";
#   };
# }