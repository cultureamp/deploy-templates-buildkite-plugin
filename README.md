# Welcome to the Culture Amp Buildkite Deploy Templates Plugin

Allows deploy steps to be injected into the pipeline based on a common template, using centralized deploy target configuration.

This plugin aims to extend the functionality from the [step-templates plugin](https://github.com/cultureamp/step-templates-buildkite-plugin), with a focus on centralizing and automating deployment config.

## How it works

TODO: explanation on template and selector usage alongside plugin...

## Environment variable behavior

### Load order of .env files

If an .env file is found in S3, it will be loaded first.
Then if an .env file is found in the local repo it will be loaded second, overriding any vars previously loaded.

### Behavior depending on .env file contents

This plugin currently requires an `.env` file matching the STEP_ENVIRONMENT name to be present either in the configured S3 bucket, or alongside the step_template file in the repository's .buildkite folder.

If the file is not found in S3, the plugin will check for a matching file in the local repo. If there aren't matching files in either location, the plugin will return an error and prevent further deployment.

Environment files containing only empty lines, or only comments, will not be loaded.

## Plugin Properties

### `step-template` (Type: string, Required)

The template to render for each selected/specified environment. The selected
environment will be presented as `STEP_ENVIRONMENT`, and additional variables
will be given as `STEP_VAR_1` to `STEP_VAR_n` unless named otherwise by
`step-var-names`.

Note that if there a files alongside this YAML file named `STEP_ENVIRONMENT.env`
the key/value pairs specified therein will be present for the template as
environment variables.

### `step-var-names` (Type: string[], Optional, Default: undefined)

The selector can have semi-colon separated values: this names the second
and subsequent values and avoids the default `STEP_VAR_n` name. The supplied
names are uppercased.

Thus if the names were `["type", "region"]`, and the value was
`staging;preprod;us-west-1`, the step template would receive the following
environment:

```env
STEP_ENVIRONMENT=staging
TYPE=preprod
REGION=us-west-1
```

> **Note:** When utilizing `auto-deploy-to-production`, `step-var-names` property cannot be used. `FARM` will instead be statically set for use in the template

### `auto-selections` (Type: string[], Optional, Default: undefined)

A list of environment pre-selections that will be rendered immediately by the plugin
using the values specified (semi-colon separated).

When a template is rendered as an auto-selection, the value of the standard
Buildkite variable `BUILDKITE_PIPELINE_DEFAULT_BRANCH` will be copied to an
environment variable named `AUTO_SELECTION_DEFAULT_BRANCH`. This allows steps
rendered for auto-selections to use branch filters that work differently. For
example, a step definition like:

```yaml
steps:
  - label: "Deploy to ${STEP_ENVIRONMENT} (${REGION})"
    command: "bin/ci_deploy"
    branches: "${AUTO_SELECTION_DEFAULT_BRANCH:-*}"
```

When output as an auto-selection, it will only run on the default branch. When
output from a selector, it will run on any branch.

### `selector-template` (Type: string, Optional, Default: undefined)

A template containing the available environment specified as a Buildkite pipeline
`block` step that supplies a set of `fields` for selection. The selection may be
optional.

> **Note:** The value for `key:` has to be unique per pipeline, as it is used as
the name of the metadata key that the selections are read from. If you use have
a pipeline with multiple block steps that have options, each of them has to be
assigned a different value.

### `auto-deploy-to-production` (Type: boolean, Optional, Default: false)

Whether this deploy-template should be automatically deployed to the service's production accounts.

When enabling this property, it is assumed that the service has had it's deploy
target configuration added to the central S3 bucket. The Buildkite pipeline slug
is used to fetch the config from S3. The resulting deploy targets are then
automatically deployed.

This option will also statically set the `FARM` variable to `production` for each target. This value
can be overridden on a per target basis by adding `FARM` into a local .env file named after the target.

> **Note:** When utilizing `auto-deploy-to-production`, the `auto-selections` and `step-var-names` properties cannot be used.

## Examples

The `deploy-templates` plugin is completely backwards compatible with the `step-templates` plugin, and can be used with the same configuration:

```yaml
steps:
  - plugins:
      - cultureamp/deploy-templates:
          step-template: deploy-steps.yml
          step-var-names: ["type", "region"]
          auto-selections:
            - "production-us;production;us-west-1"
            - "production-eu;production;eu-west-2"
          selector-template: deploy-selector.yml
```

The plugin can be configured to allow automatic deployment to all production accounts, with manual deploy options used from the `selector-template`.

```yaml
steps:
  - plugins:
      - cultureamp/deploy-templates:
          step-template: .buildkite/deploy/deploy-steps.yaml
          selector-template: .buildkite/deploy/deploy-selector.yaml
          auto-deploy-to-production: true
```

The plugin can be configured to allow automatic deployment to all production accounts, with no manual deploy options.

```yaml
steps:
  - plugins:
      - cultureamp/deploy-templates:
          step-template: .buildkite/deploy/deploy-steps.yaml
          auto-deploy-to-production: true
```

## Developing

This repository tests its functionality using the BATS testing framework for
Bash. Be sure to add tests for any new functionality. Using the tests can
significantly speed development time when compared to testing in a real
pipeline, and it's a big win for maintenance.

To run the tests:

```shell
pnpm test
```

Running the linter:

```shell
pnpm lint
```

### Centralized configuration

This plugin makes use of a centralized method to pull config for repos.

Utilizing Buildkite agents, an environment variable (`BUILDKITE_DEPLOY_CONFIG_S3_PATH`) is set on the agent where config is uploaded, which allows for this plugin to pull config from.

The expected structure at this path is:

    .${BUILDKITE_DEPLOY_CONFIG_S3_PATH}
    ├── ...
    ├── environments
    │   ├── so-fast.env
    |   └── ...
    ├── types
    │   ├── speedy
    |   └── ...
    └── ...

To see the associated code, see [here](https://github.com/cultureamp/deploy-templates-buildkite-plugin/blob/551dd75523334bf41709d84dcc2503ae477ef048/lib/steps.bash#L56)

### Release Management

This project uses [semantic-release](https://github.com/semantic-release/semantic-release) for release management and will automatically release new versions per the [semantic versioning](https://semver.org/) specification. [Angular commit message conventions](https://github.com/angular/angular/blob/master/CONTRIBUTING.md#-commit-message-format) are required; the PR title will need to conform to this naming convention e.g. type of feat|fix|test etc.

A repository dispatch event configuration has been enabled for the release. This provides a `manual` trigger that can be used to trigger a manual release. Follow the [docs](https://github.com/semantic-release/semantic-release/blob/master/docs/recipes/ci-configurations/github-actions.md#trigger-semantic-release-on-demand) to use the github web app or api for more details.

## Support

This is an internal plugin used for Culture Amp CI purposes and is not designed for external use.
