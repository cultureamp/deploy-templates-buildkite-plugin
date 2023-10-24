package main

import (
	"context"
	"os"

	"github.com/cultureamp/examplego/buildkite"
	"github.com/cultureamp/examplego/plugin"
)

func main() {
	os.Setenv("BUILDKITE_PLUGIN_EXAMPLE_GO", "works :shrug:")
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
