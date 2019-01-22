#!/usr/bin/env bash

set -euo pipefail

LOCAL_CHARTS_DIR="${1?Specify chart directory path}"
GCS_BUCKETNAME="${2?Specify GCS bucket name}"

readonly HELM_URL=https://storage.googleapis.com/kubernetes-helm
readonly HELM_TARBALL=helm-v2.12.1-linux-amd64.tar.gz

main() {
	setup_helm_client
	authenticate

	echo "Syncing repo '$LOCAL_CHARTS_DIR'..."

	# Temporary directory to store the packaged charts which will be synced
	local sync_dir="${LOCAL_CHARTS_DIR}-sync"
	mkdir -p $sync_dir

	# Iterate all the chart folder under chart repo and package them
	for dir in "$LOCAL_CHARTS_DIR"/*; do
		if helm dependency build "$dir"; then
			helm package --destination "$sync_dir" "$dir"
		else
			log_error "Problem building dependencies. Skipping packaging of '$dir'."
			exit 1
		fi
	done
	# Sync all packeged charts
	gsutil -m rsync -d "$sync_dir" gs://"${GCS_BUCKETNAME}"

}

setup_helm_client() {
	echo "Setting up Helm client..."

	curl --user-agent curl-ci-sync -sSL -o "$HELM_TARBALL" "$HELM_URL/$HELM_TARBALL"
	tar xzfv "$HELM_TARBALL"

	PATH="$(pwd)/linux-amd64/:$PATH"
	helm init --client-only
}

authenticate() {
	echo "Authenticating with Google Cloud..."
	gcloud auth activate-service-account --key-file <(base64 --decode <<<"$CHARTMUSEUM_SERVICE_ACCOUNT_KEY")
}

log_error() {
	printf '\e[31mERROR: %s\n\e[39m' "$1" >&2
}

main
