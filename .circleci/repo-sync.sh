#!/usr/bin/env bash

set -eu

CHART_REPO="${1?Specify chart directory path}"

readonly HELM_URL=https://storage.googleapis.com/kubernetes-helm
readonly HELM_TARBALL=helm-v2.9.1-linux-amd64.tar.gz
readonly STABLE_REPO_URL=https://raju-charts.storage.googleapis.com/
readonly GCS_BUCKET_STABLE=gs://raju-charts

main() {
	# setup_helm_client
	# authenticate

	if ! sync_repo $CHART_REPO "$GCS_BUCKET_STABLE" "$STABLE_REPO_URL"; then
		log_error "Not all stable charts could be packaged and synced!"
	fi
}

setup_helm_client() {
	echo "Setting up Helm client..."

	curl --user-agent curl-ci-sync -sSL -o "$HELM_TARBALL" "$HELM_URL/$HELM_TARBALL"
	tar xzfv "$HELM_TARBALL"

	PATH="$(pwd)/linux-amd64/:$PATH"

	helm init --client-only
	helm repo add incubator "$INCUBATOR_REPO_URL"
}

authenticate() {
	echo "Authenticating with Google Cloud..."
	gcloud auth activate-service-account --key-file <(base64 --decode <<<"$SYNC_CREDS")
}

sync_repo() {
	local repo_dir="${1?Specify repo dir}"
	local bucket="${2?Specify repo bucket}"
	local repo_url="${3?Specify repo url}"
	local sync_dir="${repo_dir}-sync"
	local index_dir="${repo_dir}-index"

	echo "Syncing repo '$repo_dir'..."

	mkdir -p "$sync_dir"
	mkdir -p "$index_dir"
	if ! gsutil cp "$bucket/index.yaml" "$index_dir/index.yaml"; then
		helm repo index $index_dir --url "$repo_url"
	fi

	local exit_code=0

	for dir in "$repo_dir"/*; do
		if helm dependency build "$dir"; then
			helm package --destination "$sync_dir" "$dir"
		else
			log_error "Problem building dependencies. Skipping packaging of '$dir'."
			exit_code=1
		fi
	done

	if helm repo index --url "$repo_url" --merge "$index_dir/index.yaml" "$sync_dir"; then
		# Move updated index.yaml to sync folder so we don't push the old one again
		mv -f "$sync_dir/index.yaml" "$index_dir/index.yaml"

		gsutil -m rsync "$sync_dir" "$bucket"

		# Make sure index.yaml is synced last
		gsutil cp "$index_dir/index.yaml" "$bucket"
	else
		log_error "Exiting because unable to update index. Not safe to push update."
		exit 1
	fi

	ls -l "$sync_dir"

	return "$exit_code"
}

log_error() {
	printf '\e[31mERROR: %s\n\e[39m' "$1" >&2
}

main
