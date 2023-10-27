#!/usr/bin/env bats

set -eou pipefail

load "$BATS_PLUGIN_PATH/load.bash"
load '../lib/steps'

# Uncomment the following line to debug stub failures
# export BUILDKITE_AGENT_STUB_DEBUG=/dev/tty

@test "local_env_file works for relative file" {
  file="$(local_env_file ".buildkite/template.yaml" "flamingo")"

  assert_equal "${file}" ".buildkite/flamingo.env"
}

@test "local_env_file works for simple file" {
  file="$(local_env_file "template.yaml" "flamingo")"

  assert_equal "${file}" "./flamingo.env"
}

@test "load_env_file loads into environment" {
    load_env_file "./tests/fixtures/env/basic.env"

    assert_equal "${one}" "first"
    assert_equal "${two}" "second"
    assert_equal "${three}" "third"
}

@test "load_env_file loads file with spaces in values into environment" {
    load_env_file "./tests/fixtures/env/spaces.env"

    assert_equal "${onespace}" "first one"
    assert_equal "${twospace}" "second two"
    assert_equal "${threespace}" "third three"
}

@test "load_env_file loads file containing only comments without error" {
    run load_env_file "./tests/fixtures/env/commented.env"

    assert_success
    assert_output --partial "is empty or contains only comments"
    refute_output --partial "declare -x"
}

@test "load_env_file loads file with no content without error" {
    run load_env_file "./tests/fixtures/env/empty.env"

    assert_success
    assert_output --partial "is empty or contains only comments"
    refute_output --partial "declare -x"
}

@test "Fails file_exists_and_not_empty on empty file" {
  run file_exists_and_not_empty "./tests/fixtures/env/empty.env"

  assert_failure
}

@test "Fails file_exists_and_not_empty on missing file" {
  run file_exists_and_not_empty "./tests/fixtures/env/not-here.env"

  assert_failure
}

@test "Pass file_exists_and_not_empty on useable file" {
  run file_exists_and_not_empty "./tests/fixtures/env/basic.env"

  assert_success
}

@test "Pass file_has_useable_content on useable file" {
  run file_has_useable_content "./tests/fixtures/env/basic.env"

  assert_success
}

@test "Fail file_has_useable_content on file without words" {
  run file_has_useable_content "./tests/fixtures/env/empty.env"

  assert_failure
}

@test "Fail file_has_useable_content on file that only contains comments" {
  run file_has_useable_content "./tests/fixtures/env/commented.env"

  assert_failure
}
