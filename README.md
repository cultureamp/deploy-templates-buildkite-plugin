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

See property description from [step-templates plugin](https://github.com/cultureamp/step-templates-buildkite-plugin?tab=readme-ov-file#step-template-required-string).

### `step-var-names` (Type: string[], Optional, Default: undefined)

> **Note:** When utilizing `auto-deploy-to-production`, `step-var-names` property cannot be used. `FARM` will instead be statically set for use in the template

See property description from [step-templates plugin](https://github.com/cultureamp/step-templates-buildkite-plugin?tab=readme-ov-file#step-var-names-required-string).

### `auto-selections` (Type: string[], Optional, Default: undefined)

> **Note:** When utilizing `auto-selections`, the `auto-deploy-to-production` property cannot be used.

See property description from [step-templates plugin](https://github.com/cultureamp/step-templates-buildkite-plugin?tab=readme-ov-file#auto-selections-optional-string).

### `selector-template` (Type: string, Optional, Default: undefined)

See property description from [step-templates plugin](https://github.com/cultureamp/step-templates-buildkite-plugin?tab=readme-ov-file#selector-template-optional-string
).

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
