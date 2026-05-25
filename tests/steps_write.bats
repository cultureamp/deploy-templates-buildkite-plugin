#!/usr/bin/env bats

load "$BATS_PLUGIN_PATH/load.bash"
load '../lib/steps'

# Uncomment the following line to debug stub failures
export BUILDKITE_AGENT_STUB_DEBUG=/dev/tty

setup() {
  export unstub_path="$PATH"
  export PATH="$BATS_TEST_DIRNAME/fixtures/bin:$PATH"

  mkdir /tmp/steps 2>&1 | true
  cat > /tmp/steps/c.env <<<'
file_arg=loaded
'

  cat > /tmp/steps/template.yaml <<'TMPL'
steps:
  - label: "deploy ${STEP_ENVIRONMENT}"
    key: deploy-${STEP_ENVIRONMENT}
    env:
      COMMIT: ${BUILDKITE_COMMIT}
TMPL
}

teardown() {
  export PATH="$unstub_path"
  [ -d "/tmp/steps" ] && rm -rf /tmp/steps
}

@test "write_steps runs template for each env" {
  local template="/tmp/steps/template.yaml"

  run write_steps "$template" "" $'a\nb\nc'
  assert_success

  assert_output --partial "stubargs(a):pipeline upload /tmp/steps/template.yaml"
  assert_output --partial "stubargs(b):pipeline upload /tmp/steps/template.yaml"
  assert_output --partial "stubargs(c):pipeline upload /tmp/steps/template.yaml"
}

@test "write_steps creates arguments with default names for each env" {
  local template="/tmp/steps/template.yaml"

  run write_steps "$template" "" $'a;aa\nb\nc;c1;c2;c3'
  assert_success

  assert_output --partial "stubenv(a): STEP_VAR_1=aa"
  assert_output --partial "stubenv(c): STEP_VAR_1=c1"
  assert_output --partial "stubenv(c): STEP_VAR_2=c2"
  assert_output --partial "stubenv(c): STEP_VAR_3=c3"
  refute_output --partial "stubenv(c): STEP_VAR_4"
}

@test "write_steps creates arguments with specified names" {
  local template="/tmp/steps/template.yaml"

  run write_steps "$template" $'named_1\nnamed_2' $'a;aa\nb\nc;c1;c2;c3'
  assert_success

  # named vars should exist where names supplied
  assert_output --partial "stubnamed(a): NAMED_1=aa"
  assert_output --partial "stubnamed(c): NAMED_1=c1"
  assert_output --partial "stubnamed(c): NAMED_2=c2"
  assert_output --partial "stubenv(c): STEP_VAR_3=c3"

  # no unexpected args
  refute_output --partial "stubnamed(c): STEP_VAR_4"

  # default vars should not be present
  refute_output --partial "stubenv(a): STEP_VAR_1=aa"
  refute_output --partial "stubenv(c): STEP_VAR_1=c1"
  refute_output --partial "stubenv(c): STEP_VAR_2=c2"
}

@test "write_steps with group-label wraps steps in a group" {
  local template="/tmp/steps/template.yaml"

  run write_steps "$template" "" $'env-a\nenv-b' ":rocket: Deploy"
  assert_success

  refute_output --partial "malformed"
  assert_output --partial 'stubgrouped:pipeline upload'
  assert_output --partial 'group: ":rocket: Deploy"'
  assert_output --partial 'label: "deploy env-a"'
  assert_output --partial 'label: "deploy env-b"'
  assert_output --partial 'key: deploy-env-a'
  assert_output --partial 'key: deploy-env-b'
}

@test "write_steps with group-label preserves Buildkite runtime variables" {
  local template="/tmp/steps/template.yaml"

  run write_steps "$template" "" $'env-a' "My Group"
  assert_success

  refute_output --partial "malformed"
  assert_output --partial 'COMMIT: ${BUILDKITE_COMMIT}'
}

@test "write_steps with group-label does single pipeline upload" {
  local template="/tmp/steps/template.yaml"

  run write_steps "$template" "" $'env-a\nenv-b\nenv-c' "My Group"
  assert_success

  # Grouped mode: single upload (stubgrouped), not per-env uploads (stubargs)
  refute_output --partial "stubargs("
  assert_output --partial "stubgrouped:pipeline upload"
}

@test "write_steps with group-label substitutes step-var-names per env" {
  local template="/tmp/steps/template.yaml"
  cat > "$template" <<'TMPL'
steps:
  - label: "deploy ${STEP_ENVIRONMENT} to ${FARM}"
TMPL

  run write_steps "$template" $'farm' $'env-a;production\nenv-b;staging' "My Group"
  assert_success

  assert_output --partial 'label: "deploy env-a to production"'
  assert_output --partial 'label: "deploy env-b to staging"'
}

@test "write_steps with group-label substitutes variables with default syntax" {
  cat > /tmp/steps/template-defaults.yaml <<'TMPL'
steps:
  - label: "deploy ${STEP_ENVIRONMENT}"
    agents:
      queue: infrastructure-${DEPLOYMENT_TYPE:-unrestricted}
    branches: ${AUTO_SELECTION_DEFAULT_BRANCH:-${ALLOWED_BRANCHES}}
TMPL

  cat > /tmp/steps/env-a.env <<'ENV'
export DEPLOYMENT_TYPE="restricted"
export ALLOWED_BRANCHES="main"
ENV

  run write_steps "/tmp/steps/template-defaults.yaml" "" $'env-a' "My Group"
  assert_success

  assert_output --partial 'queue: infrastructure-restricted'
  refute_output --partial 'unrestricted'
}

@test "write_steps with group-label preserves defaults for unset variables" {
  cat > /tmp/steps/template-defaults2.yaml <<'TMPL'
steps:
  - label: "deploy ${STEP_ENVIRONMENT}"
    agents:
      queue: infrastructure-${DEPLOYMENT_TYPE:-unrestricted}
TMPL

  run write_steps "/tmp/steps/template-defaults2.yaml" "" $'env-x' "My Group"
  assert_success

  # DEPLOYMENT_TYPE is not set for env-x, so the full ${...:-...} must survive
  # for the Buildkite agent to resolve at runtime
  assert_output --partial 'infrastructure-${DEPLOYMENT_TYPE:-unrestricted}'
}

@test "write_steps with group-label rejects malformed output from empty template" {
  cat > /tmp/steps/empty-template.yaml <<'TMPL'
TMPL

  run write_steps "/tmp/steps/empty-template.yaml" "" $'env-a' "My Group"
  assert_failure

  assert_output --partial "Step templates plugin error"
  assert_output --partial "malformed"
}

@test "write_steps without group-label maintains existing behavior" {
  local template="/tmp/steps/template.yaml"

  run write_steps "$template" "" $'a\nb'
  assert_success

  assert_output --partial "stubargs(a):pipeline upload /tmp/steps/template.yaml"
  assert_output --partial "stubargs(b):pipeline upload /tmp/steps/template.yaml"
  refute_output --partial "stubgrouped"
}
