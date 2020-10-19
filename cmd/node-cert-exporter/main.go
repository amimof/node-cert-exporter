package main

import (
	"flag"
	"fmt"
	"net/http"

	"github.com/amimof/node-cert-exporter/pkg/exporter"
	"github.com/golang/glog"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"github.com/prometheus/common/version"
	"github.com/spf13/pflag"
)

// VERSION is generated during compile as is never to be set here
var VERSION string

// COMMIT is the Git commit hash and is generated during compile as is never to be set here
var COMMIT string

// BRANCH is the Git branch name and is generated during compile as is never to be set here
var BRANCH string

// GOVERSION is the Go version used to compile and is generated during compile as is never to be set here
var GOVERSION string

var (
	host         string
	port         int
	listen       string
	paths        []string
	excludePaths []string
	includeGlobs []string
	excludeGlobs []string
)

func init() {
	prometheus.MustRegister(version.NewCollector("prometheus_cert_exporter"))
	pflag.StringVar(&listen, "listen", ":9117", "Address to listen on for metrics and telemetry. Defaults to :9117")
	pflag.StringSliceVar(&paths, "path", []string{"."}, "List of paths to search for SSL certificates. Defaults to current directory.")
	pflag.StringSliceVar(&excludePaths, "exclude-path", []string{}, "List of paths to exclute from searching for SSL certificates.")
	pflag.StringSliceVar(&includeGlobs, "include-glob", []string{}, "List files matching a pattern to include. This flag can be used multple times.")
	pflag.StringSliceVar(&excludeGlobs, "exclude-glob", []string{}, "List files matching a pattern to exclude. This flag can be used multple times.")
}

func main() {

	// Request app version
	showver := pflag.Bool("version", false, "Print version")

	// parse the CLI flags
	pflag.CommandLine.AddGoFlagSet(flag.CommandLine)
	pflag.Parse()

	// Show version if requested
	if *showver {
		fmt.Printf("Version: %s\nCommit: %s\nBranch: %s\nGoVersion: %s\n", VERSION, COMMIT, BRANCH, GOVERSION)
		return
	}

	e := exporter.New()
	e.SetRoots(paths)
	e.SetExcludeRoots(excludePaths)
	e.IncludeGlobs(includeGlobs)
	e.ExcludeGlobs(excludeGlobs)

	prometheus.MustRegister(e)

	glog.V(2).Infof("Listening on %s", listen)
	http.Handle("/metrics", promhttp.Handler())

	glog.Fatal(http.ListenAndServe(listen, nil))
}
