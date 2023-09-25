# Welcome to the Culture Amp Buildkite Deploy Templates Plugin

## Example

TBA: Add examples

```yaml
steps:
  - plugins:
      - cultureamp/deploy-templates#v1.0.0:

```

## Release Management

This project uses [semantic-release](https://github.com/semantic-release/semantic-release) for release management and will automatically release new versions per the [semantic versioning](https://semver.org/) specification. [Angular commit message conventions](https://github.com/angular/angular/blob/master/CONTRIBUTING.md#-commit-message-format) are required; the PR title will need to conform to this naming convention e.g. type of feat|fix|test etc.

A repository dispatch event configuration has been enabled for the release. This provides a `manual` trigger that can be used to trigger a manual release. Follow the [docs](https://github.com/semantic-release/semantic-release/blob/master/docs/recipes/ci-configurations/github-actions.md#trigger-semantic-release-on-demand) to use the github web app or api for more details.

## Support

This is an internal plugin used for Culture Amp CI purposes and is not designed for external use.

## Config for repos
This plugin makes use of a centralised method to pull config for repos.

Utilising Buildkite agents, an environment variable (`BUILDKITE_DEPLOY_TEMPLATE_BUCKET`) is set on the agent where config is uploaded, which allows for this plugin to pull config from.

To see the associated code, see [here](https://github.com/cultureamp/deploy-templates-buildkite-plugin/blob/551dd75523334bf41709d84dcc2503ae477ef048/lib/steps.bash#L56)
