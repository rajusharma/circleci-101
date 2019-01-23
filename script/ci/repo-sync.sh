#!/usr/bin/env bash

project_root_dir="$(git rev-parse --show-toplevel)"
source "${project_root_dir}/script/ci/_lib"

usage() {
  echo ""
  echo "Usage: script/ci/repo-sync {base directory of charts} {DEV or PROD}"
  echo ""
  echo "    Run script/ci/repo-sync to only changed directories under {base directory of charts}"
  echo ""
  echo "Examples:"
  echo "  $ script/ci/repo-sync mercari DEV"
  echo "  $ script/ci/repo-sync mercari PROD"
}

main() {
  set -euo pipefail
  
  declare basedir="${1}"
  
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
  echo "[INFO] Helm packaging and Syncing charts which are under changed dirs"
  for dir in $(changed_chart_dirs "${basedir}"); do
    if helm dependency build "${dir}"; then
      helm package --destination "${basedir}-sync" "${dir}s"
    else
      echo "[ERROR] Problem building dependencies. Skipping packaging of '${dir}'."
      exit 1
    fi
  done
  
  
  # # Iterate all the chart folder under chart repo and package them
  # for dir in "$LOCAL_CHARTS_DIR"/*; do
  #   if helm dependency build "$dir"; then
  #     helm package --destination "$sync_dir" "$dir"
  #   else
  #     log_error "Problem building dependencies. Skipping packaging of '$dir'."
  #     exit 1
  #   fi
  # done
  # # Sync all packeged charts
  # gsutil -m rsync -d "$sync_dir" gs://"${GCS_BUCKETNAME}"
  
}

main "${@}"
