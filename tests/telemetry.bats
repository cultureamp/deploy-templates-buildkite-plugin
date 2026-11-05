#!/usr/bin/env bats

load "$BATS_PLUGIN_PATH/load.bash"

setup() {
  export unstub_path="$PATH"
  export PATH="$BATS_TEST_DIRNAME/fixtures/bin:$PATH"
  unset BUILDKITE_PLUGINS STUB_META_DATA_SET_FAIL

  export BUILDKITE_PLUGIN_DEPLOY_TEMPLATES_AUTO_SELECTIONS_0="auto-one"
  export BUILDKITE_PIPELINE_DEFAULT_BRANCH="main"

  cat > "/tmp/aqua-template.yaml" <<'TMPL'
steps:
  - label: "deploy ${STEP_ENVIRONMENT}"
    plugins:
      - cultureamp/ecs-deploy#v1.11.2:
          command: deploy
TMPL
  cat > "/tmp/plain-template.yaml" <<'TMPL'
steps:
  - label: "deploy ${STEP_ENVIRONMENT}"
TMPL
}

teardown() {
  export PATH="$unstub_path"
  rm -f /tmp/aqua-template.yaml /tmp/plain-template.yaml
}

@test "Tags an Aqua build with the system and ecs-deploy version" {
  export BUILDKITE_PLUGIN_DEPLOY_TEMPLATES_STEP_TEMPLATE="/tmp/aqua-template.yaml"

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "stubargs():meta-data set dd_tags.deploy.plugin deploy-templates"
  assert_output --partial "stubargs():meta-data set dd_tags.deploy.system aqua"
  assert_output --partial "stubargs():meta-data set dd_tags.ecs_deploy.version v1.11.2"
}

@test "Tags a non-Aqua build with the plugin only" {
  export BUILDKITE_PLUGIN_DEPLOY_TEMPLATES_STEP_TEMPLATE="/tmp/plain-template.yaml"

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "stubargs():meta-data set dd_tags.deploy.plugin deploy-templates"
  refute_output --partial "dd_tags.deploy.system"
  refute_output --partial "dd_tags.ecs_deploy.version"
}

@test "Tags the deploy-templates version from BUILDKITE_PLUGINS" {
  export BUILDKITE_PLUGIN_DEPLOY_TEMPLATES_STEP_TEMPLATE="/tmp/plain-template.yaml"
  export BUILDKITE_PLUGINS='[{"github.com/cultureamp/deploy-templates-buildkite-plugin#v1.3.1":{"auto-selections":["auto-one"]}}]'

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "stubargs():meta-data set dd_tags.deploy_templates.version v1.3.1"
}

@test "Skips the version tag when BUILDKITE_PLUGINS has no deploy-templates reference" {
  export BUILDKITE_PLUGIN_DEPLOY_TEMPLATES_STEP_TEMPLATE="/tmp/plain-template.yaml"
  export BUILDKITE_PLUGINS='[{"github.com/buildkite-plugins/docker-compose-buildkite-plugin#v4.15.0":{}}]'

  run "$PWD/hooks/command"

  assert_success
  refute_output --partial "dd_tags.deploy_templates.version"
}

@test "Still uploads steps when setting meta-data fails" {
  export BUILDKITE_PLUGIN_DEPLOY_TEMPLATES_STEP_TEMPLATE="/tmp/aqua-template.yaml"
  export STUB_META_DATA_SET_FAIL=1

  run "$PWD/hooks/command"

  assert_success
  assert_output --partial "Could not set Datadog tag dd_tags.deploy.plugin"
  assert_output --partial "stubenv(auto-one): STEP_ENVIRONMENT=auto-one"
}
