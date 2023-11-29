#!/usr/bin/env bats

set -eou pipefail

load "$BATS_PLUGIN_PATH/load.bash"
load '../lib/targets'

# Uncomment the following line to debug stub failures
# export BUILDKITE_AGENT_STUB_DEBUG=/dev/tty

@test "parse_deploy_targets works for valid target" {
  run echo $(parse_deploy_targets "./tests/fixtures/deploy-types/service-c" "mid")

  assert_output "aight just-ok"
}

@test "parse_deploy_targets works for invalid target" {
  run echo $(parse_deploy_targets "./tests/fixtures/deploy-types/service-b" "invalid")

  assert_success
  assert_output "Error: invalid does not exist in config"
}

@test "fetch_deploy_targets works for valid target" {
  run echo $(fetch_deploy_targets "./tests/fixtures/deploy-types/service-c" "mid")

  assert_output "aight;mid just-ok;mid"
}
