#!/usr/bin/env bash

# Generates the targets a step template will deploy to,
# based on service level config stored in s3

function fetch_deploy_config() {
  local service_name="${1}"

  if [[ -z "${RUNNING_TESTS_YO:-}" ]]; then
    echo "Downloading deploy config for ${service_name}..."
    download_deploy_types_file "${service_name}"
  else
    echo "=> RUNNING_TESTS_YO is set, skipping types file download."
  fi
}

# Download and load environment files from configured S3 bucket
function download_deploy_types_file() {
  local service_name="${1}"

  # Find env file based on the location of the template
  if [[ -z "${BUILDKITE_DEPLOY_CONFIG_S3_PATH:-}" ]]; then
    echo "=> BUILDKITE_DEPLOY_CONFIG_S3_PATH is not set, unable to download deploy type configuration"
    exit 42
  fi

  local deploy_types_file="${BUILDKITE_DEPLOY_CONFIG_S3_PATH}/types/${service_name}"
  
  echo "S3 PATH: ${deploy_types_file}"

  set +e
  echo "=> Downloading deploy types file from S3..."
  aws s3 cp "${deploy_types_file}" .
  local aws_cp_exit_code=$?
  set -e

  # If the AWS S3 copy was unsuccessful, return error
  if [[ ${aws_cp_exit_code} -ne 0 ]]; then
    echo "Error: failed to download ${deploy_types_file} from S3"
    return 42
  fi
}

function fetch_deploy_targets {
  local file=$1
  local deploy_type=$2

  deploy_targets="$(parse_deploy_targets "${file}" "${deploy_type}")"

  local targets
  readarray -t targets <<<"${deploy_targets}"

  for target in "${targets[@]}"
  do
    target_config+=( "${target};${deploy_type}" )
  done

  # config for each target separated by a new line
  local IFS=$'\n'
  echo "${target_config[*]}"
}

function parse_deploy_targets {
  local file=$1
  local deploy_type=$2

  parsed_targets=$(jq -r "try .${deploy_type}[] catch 0" "${file}")

  if [[ ${parsed_targets} == 0 ]]; then
    echo "Error: ${deploy_type} does not exist in config"
    return 42
  fi
  echo "${parsed_targets}"
}
