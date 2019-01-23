#!/usr/bin/env bash

project_root_dir="$(git rev-parse --show-toplevel)"
source "${project_root_dir}/script/ci/_lib"

usage() {
  echo ""
  echo "Usage: script/ci/chart-sync {base directory of charts} {CI env name in which helm repo password is saved}"
  echo ""
  echo ""
  echo "Examples:"
  echo "  $ script/ci/chart-sync mercari CHARTMUSEUM_PASSWORD_DEV"
  echo "  $ script/ci/chart-sync mercari CHARTMUSEUM_PASSWORD_PROD"
}

main() {
  set -euo pipefail
  
  declare -r basedir="${1}"
  declare -r passwordkey="${2}"
  
  # Basic validations before taking any actions
  if ! validate_arguments "${@}"; then
    usage
    exit 1
  fi
  validate_basedir "${basedir}"
  exit_if_there_is_no_change "${basedir}"
  if is_branch_behind_master; then
    echo "[DEBUG] Stopped because local branch is older than remote one" >&2
    return 0
  fi
  
  show_changed_dirs "${basedir}"
  # Temporary sync directory from which all the changed charts will be pushed to remote helm repo
  mkdir -p "${basedir}-sync"
  echo "[INFO] Packaging the modified helm charts"
  for dir in $(changed_chart_dirs "${basedir}"); do
    if [ -d "${dir}" ]; then
      if helm dependency build "${dir}"; then
        helm package --destination "${basedir}-sync" "${dir}"
      else
        echo "[ERROR] Problem building dependencies. Skipping packaging of '${dir}'."
        exit 1
      fi
    fi
  done
  
  echo "[INFO] Syncing the modified helm charts"
  for file in "${basedir}-sync"/*; do
    echo $file
    # curl --data-binary @${file} https://mercari:$(eval echo \$${passwordkey})@chartmuseum.dev.citadelapps.com/api/charts
  done
  
}

main "${@}"
