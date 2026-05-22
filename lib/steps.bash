#!/usr/bin/env bash

# Writes the steps based on a step template

function write_steps() {
  template="${1}"
  local raw_var_names="${2}"
  local selected_environments="${3}"
  local group_label="${4:-}"

  if [[ -n "${group_label}" ]]; then
    write_grouped_steps "${template}" "${raw_var_names}" "${selected_environments}" "${group_label}"
    return
  fi

  # this is passed as a newline-delimited string, as passing arrays is ... not really a thing
  local var_names
  readarray -t var_names <<<"${raw_var_names}"

  if [[ -n "${selected_environments}" ]]; then
    while IFS=$'\n' read -r selection; do
      if [[ -z ${selection} ]]; then
        continue
      fi

      IFS=';' read -ra step_vars <<<"${selection}"

      # for each selected environment, write the template with the required variable names
      (
        local step_env=""

        msg="--- Writing template \"${template}\""

        # the first item is always called "STEP_ENVIRONMENT"
        if [[ ${#step_vars[@]} -gt 0 ]]; then
          step_env="${step_vars[0]}"
          step_env="$(printf '%s' "${step_env}")" # trim trailing space

          msg+=" for environment \"${step_env}\""
        fi
        export STEP_ENVIRONMENT="${step_env}"

        echo "${msg}"
        echo "Environment setup:"
        echo "STEP_ENVIRONMENT=\"${STEP_ENVIRONMENT}\""

        # output > 1 as named in step-var-names, making up a default if needed
        for ((i = 1; i < ${#step_vars[@]}; ++i)); do
          val="$(printf '%s' "${step_vars[${i}]}")" # trim trailing space

          nm_idx=${i}-1
          var_name="step_var_${i}"
          if [[ ${#var_names[@]} -gt ${nm_idx} && -n "${var_names[${nm_idx}]}" ]]; then
            var_name="${var_names[${nm_idx}]}"
          fi

          echo "${var_name^^}=\"${val}\""
          export "${var_name^^}"="${val}"
        done

        # Find env file based on the location of the template
        if [[ -n "${BUILDKITE_DEPLOY_CONFIG_S3_PATH:-}" ]]; then
          download_and_load_env_file "${BUILDKITE_DEPLOY_CONFIG_S3_PATH}" "${STEP_ENVIRONMENT}"
        else
          echo "=> BUILDKITE_DEPLOY_CONFIG_S3_PATH is not set, skipping .env file download."
        fi

        # Load local env file
        local env_file
        env_file="$(local_env_file "${template}" "${step_env}")"

        if file_exists_and_not_empty "${env_file}"; then
          echo "=> loading local ${env_file} into environment..."
          load_env_file "${env_file}"
        fi

        buildkite-agent pipeline upload "${template}"
      )
    done <<<"${selected_environments}"
  fi
}

# Exports a variable and tracks its name for later use with envsubst
function track_export() {
  local var_name="${1}"
  local var_value="${2}"
  export "${var_name}"="${var_value}"
  _ENVSUBST_VARS+=" \${${var_name}}"
}

# Like load_env_file, but also tracks exported variable names in _ENVSUBST_VARS
function load_env_file_tracked() {
  local env_file="${1}"

  if ! file_has_useable_content "${env_file}"; then
    echo "Warning: ${env_file} is empty or contains only comments." >&2
    return
  fi

  # Extract variable names before loading
  local var_names_list=""
  if grep -q '^export \w' "${env_file}"; then
    var_names_list="$(grep '^export ' "${env_file}" | sed 's/^export \([A-Za-z_][A-Za-z_0-9]*\).*/\1/')"
  else
    var_names_list="$(grep -v '^[[:space:]]*#' "${env_file}" | grep '=' | sed 's/^\([A-Za-z_][A-Za-z_0-9]*\)=.*/\1/' || true)"
  fi

  load_env_file "${env_file}"

  while IFS= read -r name; do
    if [[ -n "${name}" ]]; then
      _ENVSUBST_VARS+=" \${${name}}"
    fi
  done <<<"${var_names_list}"
}

# Renders a step template for a single environment using envsubst.
# Per-environment variables are substituted; all others are left intact.
# Rendered YAML is written to stdout; diagnostic messages go to stderr.
function render_template_for_env() {
  local template="${1}"
  local raw_var_names="${2}"
  local selection="${3}"

  local var_names
  readarray -t var_names <<<"${raw_var_names}"

  IFS=';' read -ra step_vars <<<"${selection}"

  _ENVSUBST_VARS=""
  local step_env=""

  local msg="--- Writing template \"${template}\""

  if [[ ${#step_vars[@]} -gt 0 ]]; then
    step_env="${step_vars[0]}"
    step_env="$(printf '%s' "${step_env}")"
    msg+=" for environment \"${step_env}\""
  fi

  track_export "STEP_ENVIRONMENT" "${step_env}"

  echo "${msg}" >&2
  echo "Environment setup:" >&2
  echo "STEP_ENVIRONMENT=\"${STEP_ENVIRONMENT}\"" >&2

  for ((i = 1; i < ${#step_vars[@]}; ++i)); do
    val="$(printf '%s' "${step_vars[${i}]}")"

    nm_idx=${i}-1
    var_name="step_var_${i}"
    if [[ ${#var_names[@]} -gt ${nm_idx} && -n "${var_names[${nm_idx}]}" ]]; then
      var_name="${var_names[${nm_idx}]}"
    fi

    echo "${var_name^^}=\"${val}\"" >&2
    track_export "${var_name^^}" "${val}"
  done

  if [[ -n "${BUILDKITE_DEPLOY_CONFIG_S3_PATH:-}" ]]; then
    download_and_load_env_file "${BUILDKITE_DEPLOY_CONFIG_S3_PATH}" "${STEP_ENVIRONMENT}" "load_env_file_tracked" >&2
  else
    echo "=> BUILDKITE_DEPLOY_CONFIG_S3_PATH is not set, skipping .env file download." >&2
  fi

  local env_file
  env_file="$(local_env_file "${template}" "${step_env}")"

  if file_exists_and_not_empty "${env_file}"; then
    echo "=> loading local ${env_file} into environment..." >&2
    load_env_file_tracked "${env_file}"
  fi

  envsubst "${_ENVSUBST_VARS}" < "${template}"
}

# Renders steps for all environments and wraps them in a Buildkite group step.
function write_grouped_steps() {
  local template="${1}"
  local raw_var_names="${2}"
  local selected_environments="${3}"
  local group_label="${4}"

  local combined_steps=""

  if [[ -n "${selected_environments}" ]]; then
    while IFS=$'\n' read -r selection; do
      if [[ -z ${selection} ]]; then
        continue
      fi

      local rendered
      rendered="$(render_template_for_env "${template}" "${raw_var_names}" "${selection}")"

      local indented
      indented="$(echo "${rendered}" | sed '/^steps:[[:space:]]*$/d' | sed 's/^/    /')"
      combined_steps+="${indented}"$'\n'

    done <<<"${selected_environments}"
  fi

  if [[ -n "${combined_steps}" ]]; then
    local tmp_file
    tmp_file="$(mktemp /tmp/grouped-steps.XXXXXX)"

    {
      echo "steps:"
      echo "  - group: \"${group_label}\""
      echo "    steps:"
      printf '%s' "${combined_steps}"
    } > "${tmp_file}"

    if ! head -1 "${tmp_file}" | grep -q '^steps:' || \
       ! grep -q '  - group:' "${tmp_file}" || \
       ! grep -q '    steps:' "${tmp_file}" || \
       ! sed -n '/^    steps:$/,$ p' "${tmp_file}" | tail -n +2 | grep -q '[^[:space:]]'; then
      1>&2 echo "+++ ❌ Step templates plugin error"
      1>&2 echo "Generated grouped YAML is malformed:"
      1>&2 cat "${tmp_file}"
      rm -f "${tmp_file}"
      exit 1
    fi

    buildkite-agent pipeline upload "${tmp_file}"
    rm -f "${tmp_file}"
  fi
}

# Generate the filename for the env file based on template location.
function local_env_file() {
  local template="${1}"
  local step_env="${2}"

  local dir
  dir="$(dirname "${template}")"

  echo "${dir}/${step_env}.env"
}

# Load environment variables from a file.
# The file should contain export statements or simple variable assignments.
# Comments starting with '#' are ignored.
function load_env_file() {
  # Extract the file path from the function parameter
  local env_file="${1}"

  if ! file_has_useable_content "${env_file}"; then
    echo "Warning: ${env_file} is empty or contains only comments."
    return
  fi

  # Check if the file contains export statements
  if grep -q '^export \w' "${env_file}"; then
    source "${env_file}" >/dev/null 2>&1
  else
    # This only handles simple cases; values with spaces and multiple lines
    # should use the `export` syntax.
    local vars
    vars="$(grep -v '^#' "${env_file}")"

    #shellcheck disable=SC2046
    export $(xargs <<<"${vars}")
  fi
}

# Download and load environment files from configured S3 bucket
function download_and_load_env_file() {
  local s3_bucket_path="${1}/environments"
  local step_environment="${2}"
  local load_fn="${3:-load_env_file}"
  
  echo "BUCKET: ${s3_bucket_path}"
  echo "ENV: ${step_environment}"
  
  local env_config_file="${s3_bucket_path}/${step_environment}.env"
  
  echo "S3 PATH: ${env_config_file}"

  set +e
  echo "=> Downloading .env file from S3..."
  aws s3 cp "${env_config_file}" .
  local aws_cp_exit_code=$?
  set -e

  # If the AWS S3 copy was unsuccessful, check for a matching local file 
  if [[ ${aws_cp_exit_code} -ne 0 ]]; then
    local local_env_file
    local_env_file="$(local_env_file "${template}" "${step_environment}")"
    
    # Check if the local file exists, is empty, or contains only comments
    if ! (file_exists_and_not_empty "${local_env_file}" && file_has_useable_content "${local_env_file}"); then
      echo "Unable to locate a useable env file locally or access the default env file from S3. See FAQs for guidance - https://cultureamp.atlassian.net/wiki/spaces/PST/pages/2960916852/Central+SRE+Support+FAQs"
      exit 42
    fi

    echo "Local env file exists, loading that instead..."
    return
  fi

  echo "loading central config ${env_config_file} into environment..."
  "${load_fn}" "${step_environment}.env"
}

# Check if the file exists and is not empty
function file_exists_and_not_empty() {
  local env_file="${1}"

  [[ -f "${env_file}" && -s "${env_file}" ]]
}

# Check if an environment file contains useable content (not only empty lines or comments)
function file_has_useable_content() {
  local env_file="${1}"

  [[ $(wc -l <"${env_file}" || true) -gt 0 && ! $(grep -c '^[^#]' "${env_file}" || true) -eq 0 ]]
}
