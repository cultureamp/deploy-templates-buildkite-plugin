# Welcome to the Culture Amp Buildkite Deploy Templates Plugin

## Example

TBA: Add examples

Example allowing automatic deployment to all production accounts.
```yaml
steps:
  - plugins:
      - cultureamp/deploy-templates#v1.0.5:
          step-template: .buildkite/deploy/deploy-steps.yaml
          selector-template: .buildkite/deploy/deploy-selector.yaml
          auto-deploy-to-production: true
```

## Release Management

This project uses [semantic-release](https://github.com/semantic-release/semantic-release) for release management and will automatically release new versions per the [semantic versioning](https://semver.org/) specification. [Angular commit message conventions](https://github.com/angular/angular/blob/master/CONTRIBUTING.md#-commit-message-format) are required; the PR title will need to conform to this naming convention e.g. type of feat|fix|test etc.

A repository dispatch event configuration has been enabled for the release. This provides a `manual` trigger that can be used to trigger a manual release. Follow the [docs](https://github.com/semantic-release/semantic-release/blob/master/docs/recipes/ci-configurations/github-actions.md#trigger-semantic-release-on-demand) to use the github web app or api for more details.

## Support

This is an internal plugin used for Culture Amp CI purposes and is not designed for external use.

## Config for repos
This plugin makes use of a centralised method to pull config for repos.

Utilising Buildkite agents, an environment variable (`BUILDKITE_DEPLOY_CONFIG_S3_PATH`) is set on the agent where config is uploaded, which allows for this plugin to pull config from.

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

## Environment variable behavior
### Load order of .env files

If an .env file is found in S3, it will be loaded first.
Then if an .env file is found in the local repo it will be loaded second, overriding any vars previously loaded.

### Behavior depending on .env file contents

This plugin currently requires an `.env` file matching the STEP_ENVIRONMENT name to be present either in the configured S3 bucket, or alongside the step_template file in the repository's .buildkite folder.

If the file is not found in S3, the plugin will check for a matching file in the local repo. If there aren't matching files in either location, the plugin will return an error and prevent further deployment.

Environment files containing only empty lines, or only comments, will not be loaded.
