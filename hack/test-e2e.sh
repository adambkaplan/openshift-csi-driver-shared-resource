#! /bin/bash

set -e
set -o pipefail

# Run e2e tests, with options to deploy the CSI driver directly
# Environment variables used for configuration:
#
# TEST_SUITE: test suite to run. Defaults to "normal", can also be "disruptive" and "slow"
# TEST_TIMEOUT: timeout for tests. Defauls to 30m, can be any parsable duration.
# TEST_SKIP_DEPLOY: if true, skip deployment of the driver and its prerequisites (namespace, service account, etc.)

suite=${TEST_SUITE:-"normal"}
timeout=${TEST_TIMEOUT:-"30m"}
skipDeploy=${TEST_SKIP_DEPLOY:-"false"}

function run () {
    echo "$@" >&2
    "$@"
}

function deploy() {
    echo "Deploying CSI driver prerequisites"
    run oc apply -f "deploy/0000_10_projectedresource.crd.yaml"
    run oc apply -f "deploy/00-namespace.yaml"
    run oc apply -f "deploy/01-service-account.yaml"
    run oc apply -f "deploy/02-cluster-role.yaml"
    run oc apply -f "deploy/03-cluster-role-binding.yaml"
    run oc apply -f "deploy/csi-hostpath-driverinfo.yaml"
}

function test() {
    echo "Running e2e suite ${suite} with SKIP_DEPLOY=${skipDeploy}."
    KUBERNETES_CONFIG=${KUBECONFIG} SKIP_DEPLOY=${skipDeploy} go test -race -count 1 -tags "${suite}" -timeout "${timeout}" -v "./test/e2e/..."
}

if [[ ${skipDeploy} == "false" ]]; then {
    deploy
} fi

test