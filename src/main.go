package main

import (
	"context"
	"os"

	"github.com/cultureamp/deploy-templates-buildkite-plugin/src/buildkite"
	"github.com/cultureamp/deploy-templates-buildkite-plugin/src/plugin"
)

func main() {
	os.Setenv("MESSAGE", "works :shrug:")
	ctx := context.Background()
	agent := &buildkite.Agent{}
	fetcher := plugin.EnvironmentConfigFetcher{}
	examplePlugin := plugin.ExamplePlugin{}

	err := examplePlugin.Run(ctx, fetcher, agent)

	if err != nil {
		buildkite.LogFailuref("plugin execution failed: %s\n", err.Error())
		os.Exit(1)
	}
}
