#!/usr/bin/env bash
set -euo pipefail

validate_mod_version() {
  [[ -n "${MOD_VALIDATION_OFF:-}" ]] && {
    echo 'MOD_VALIDATION_OFF is set, skipping module version validation'
    return
  }

  url="https://api.github.com/repos/dominodatalab/terraform-aws-eks/tags"

  local curl_cmd=("curl" "-s")

  # In case of rate limiting and a `GITHUB_TOKEN` is available
  [[ -n "${GITHUB_TOKEN:-}" ]] && curl_cmd+=("-H" "Authorization: token ${GITHUB_TOKEN}")

  while [[ -n "${url:-}" ]]; do

    response=$("${curl_cmd[@]}" -I "$url")
    if [[ $? -ne 0 ]]; then
      echo "Error fetching tags from $url"
      exit 1
    fi

    local tag_array=()
    mapfile -t tag_array <<<$("${curl_cmd[@]}" "$url" | jq -r '.[].name | select(test("^v\\d+\\.\\d+\\.\\d+(-\\d+)?$"))')

    for tag in "${tag_array[@]}"; do
      [[ "$MOD_VERSION" == "$tag" ]] && return
    done
    url=$(echo "$response" | grep -i 'rel="next"' | sed -n 's/.*<\([^>]*\)>; rel="next".*/\1/p' || echo "")

  done

  echo "Error: The MOD_VERSION $MOD_VERSION is not a suitable tag for the modules source."
  exit 1
}

set_module_version() {
  for dir in "${MOD_DIRS[@]}"; do
    file="${dir}/main.tf"
    echo "Setting module source on: $file"

    IFS=' ' read -ra MODS <<<"${COMP_MODS[$(basename "$dir")]}"
    for mod in "${MODS[@]}"; do
      mod_add=${MOD_ADD[$mod]-"$mod"}
      MOD_SOURCE=github.com/dominodatalab/terraform-aws-eks.git//modules/"${mod_add}"?ref="${MOD_VERSION}"
      echo "Setting module source to ref: ${MOD_SOURCE} on ${dir}"
      hcledit attribute set "module.${mod}.source" "\"${MOD_SOURCE}\"" -u -f "$file"
    done
  done
}

MOD_VERSION="$1"
[ -z "${MOD_VERSION// /}" ] && { echo "Provide a module version in the format $(vX.X.X), ie $(v3.0.0)" && exit 1; }

SH_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")"
source "${SH_DIR}/meta.sh"

validate_mod_version
set_module_version
