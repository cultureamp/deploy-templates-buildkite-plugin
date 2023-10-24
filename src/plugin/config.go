package plugin

import (
	"github.com/kelseyhightower/envconfig"
)

type Config struct {
	Message string `envconfig:"MESSAGE" required:"true"`
}

type EnvironmentConfigFetcher struct {
}

const pluginEnvironmentPrefix = "MESSAGE"

func (f EnvironmentConfigFetcher) Fetch(config *Config) error {
	return envconfig.Process(pluginEnvironmentPrefix, config)
}
