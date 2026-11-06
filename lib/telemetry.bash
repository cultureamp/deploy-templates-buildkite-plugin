#!/usr/bin/env bash

# Datadog CI Visibility turns build meta-data keyed "dd_tags.*" into span tags.
# A failed tag must never fail a deploy, so errors only warn.
function set_dd_tag() {
  local key="dd_tags.${1}"
  local value="${2}"

  if ! buildkite-agent meta-data set "${key}" "${value}"; then
    1>&2 echo "Warning: Could not set Datadog tag ${key}; continuing."
  fi
}

# Tags the build with the deploy plugin and, when the template runs ecs-deploy,
# marks it as Aqua with the ecs-deploy version. "deploy.system" is never
# cleared, so a build that runs this plugin more than once stays marked Aqua.
function tag_build_for_datadog() {
  local template="${1}"

  set_dd_tag "deploy.plugin" "deploy-templates"

  local plugin_ref
  plugin_ref="$(printf '%s' "${BUILDKITE_PLUGINS:-}" | grep -oE 'deploy-templates(-buildkite-plugin)?#v[^"]+' | head -n1 || true)"
  if [[ -n "${plugin_ref}" ]]; then
    set_dd_tag "deploy_templates.version" "${plugin_ref#*#}"
  fi

  local ecs_deploy_ref
  ecs_deploy_ref="$(grep -oE 'cultureamp/ecs-deploy(-buildkite-plugin)?#v[0-9][0-9.]*' "${template}" | head -n1 || true)"
  if [[ -n "${ecs_deploy_ref}" ]]; then
    set_dd_tag "deploy.system" "aqua"
    set_dd_tag "deploy.ecs_deploy_ref" "${ecs_deploy_ref#*#}"
  fi
}
