#!/usr/bin/env bats

set -eou pipefail

load "$BATS_PLUGIN_PATH/load.bash"
load '../lib/steps'

# Uncomment the following line to debug stub failures
# export BUILDKITE_AGENT_STUB_DEBUG=/dev/tty

@test "Successfully download_and_load_env_file" {
  # simple mock for succeeding aws function
  function aws() {
    return 0
  }

  download_and_load_env_file "mah-s3-bucket" "./tests/fixtures/env/basic"

  assert_equal "${one}" "first"
  assert_equal "${two}" "second"
  assert_equal "${three}" "third"
}

@test "Fail to download_and_load_env_file, fallback to local" {
  # simple mock for failing aws function
  function aws() {
    return 1
  }

  # Env vars for local file check
  template="./tests/fixtures/env/template.yaml"

  run download_and_load_env_file "mah-s3-bucket" "basic"

  assert_output --partial "Local env file exists, loading that instead..."
  assert_success
}

@test "Fail to download_and_load_env_file, no local file" {
  # simple mock for failing aws function
  function aws() {
    return 1
  }

  # Env vars for local file check
  template="./tests/fixtures/env/template.yaml"

  run download_and_load_env_file "mah-s3-bucket" "oh-bother"

  assert_output --partial "Unable to locate a useable env file locally or access the default env file from S3"
  assert_failure
}
