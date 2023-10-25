package plugin_test

import (
	"os"
	"testing"

	"github.com/cultureamp/deploy-templates-buildkite-plugin/src/plugin"

	"github.com/stretchr/testify/assert"
)

func TestFailOnMissingEnvironment(t *testing.T) {
	var config plugin.Config
	fetcher := plugin.EnvironmentConfigFetcher{}

	t.Setenv("MESSAGE", "")
	os.Unsetenv("MESSAGE")

	err := fetcher.Fetch(&config)

	assert.NotNil(t, err, "fetch should error")
}

func TestFetchConfigFromEnvironment(t *testing.T) {
	var config plugin.Config
	fetcher := plugin.EnvironmentConfigFetcher{}

	t.Setenv("MESSAGE", "test-message")

	err := fetcher.Fetch(&config)

	assert.Nil(t, err, "fetch should not error")
	assert.Equal(t, config.Message, "test-message", "fetched message should match environment")
}
