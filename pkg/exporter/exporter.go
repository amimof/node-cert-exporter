package exporter

import (
	"crypto/x509"
	"encoding/pem"
	"io/ioutil"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/golang/glog"
	"github.com/prometheus/client_golang/prometheus"
)

var (
	extensions  = []string{".pem", ".crt", ".cert", ".cer", ".pfx"}
	hostname, _ = os.Hostname()
	nodename    = os.Getenv("NODE_NAME")
)

func isCertFile(p string) bool {
	for _, e := range extensions {
		if filepath.Ext(p) == e {
			return true
		}
	}
	return false
}

func (e *Exporter) isExcluded(s string) bool {
	for _, v := range e.excludeGlobs {
		exclude, _ := filepath.Match(v, s)
		return exclude
	}
	return false
}

func getFirstCertBlock(data []byte) []byte {
	for block, rest := pem.Decode(data); block != nil; block, rest = pem.Decode(rest) {
		if block.Type == "CERTIFICATE" {
			return block.Bytes
		}
	}
	return nil
}

// Exporter implements prometheus.Collector interface
type Exporter struct {
	mux           sync.Mutex
	includeGlobs  []string
	excludeGlobs  []string
	roots         []string
	exRoots       []string
	includeLabels []string
	certExpiry    *prometheus.GaugeVec
	certFailed    *prometheus.GaugeVec
}

// IncludeGlobs sets the list of file globs the exporter uses to match certificate files for scraping
func (e *Exporter) IncludeGlobs(g []string) {
	e.includeGlobs = g
}

// ExcludeGlobs sets the list of file globs the exporter uses to exclude matched certificate files from being scraped
func (e *Exporter) ExcludeGlobs(g []string) {
	e.excludeGlobs = g
}

// SetRoots sets the list of file paths that the exporter should search for certificates in
func (e *Exporter) SetRoots(p []string) {
	e.roots = p
}

// SetExcludeRoots sets the list of file paths that the exporter should exclude search for certificates in
func (e *Exporter) SetExcludeRoots(p []string) {
	e.exRoots = p
}

// Collect satisfies prometheus.Collector interface
func (e *Exporter) Collect(ch chan<- prometheus.Metric) {
	e.mux.Lock()
	defer e.mux.Unlock()
	e.Scrape(ch)
}

// Describe satisfies prometheus.Collector interface
func (e *Exporter) Describe(ch chan<- *prometheus.Desc) {
	ch <- e.certExpiry.WithLabelValues(e.includeLabels...).Desc()
}

// Scrape iterates over the list of file paths (set by SetRoot) and parses any found x509 certificates.
// Certificates are parsed and the fields are mapped to prometheus labels which attached to a Gauge.
// Scrape will create a new time series for each certificate file with its associated labels. The value
// of the series equals the expiry of the certificate in seconds.
func (e *Exporter) Scrape(ch chan<- prometheus.Metric) {
	paths := []string{}

	// Find x509 cert files in root and exclude those defined in exroot and put full path to files in paths array
	for _, root := range e.roots {
		exPaths := e.exRoots
		err := filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
			for _, exPath := range exPaths {
				if strings.Contains(filepath.Dir(path), exPath) || path == exPath {
					return nil
				}
			}

			if err != nil {
				glog.Warningf("Couldn't open %s: %s", path, err.Error())
				ch <- e.certFailed.With(prometheus.Labels{"path": path, "hostname": hostname, "nodename": nodename})
				return nil
			}
			if isCertFile(path) {
				paths = append(paths, path)
			}
			return nil
		})
		if err != nil {
			glog.Warningf("Error looking for certificates in %s: %s", root, err)
			continue
		}
	}

	// Loop through globs and excluded globs and put full path into paths array
	for _, iglobs := range e.includeGlobs {
		matches, err := filepath.Glob(iglobs)
		if err != nil {
			glog.Warningf("%s", err)
			continue
		}
		for _, match := range matches {
			paths = append(paths, match)
		}
	}

	// Read files defined in paths from fs and try to parse a x509 certificate from them.
	for _, path := range paths {
		if e.isExcluded(path) {
			continue
		}
		data, err := ioutil.ReadFile(path)
		if err != nil {
			glog.Warningf("Couldn't read %s: %s", path, err.Error())
			ch <- e.certFailed.With(prometheus.Labels{"path": path, "hostname": hostname, "nodename": nodename})
			continue
		}
		block := getFirstCertBlock(data)
		if len(block) == 0 {
			glog.Warningf("Couldn't find a CERTIFICATE block in %s", path)
			ch <- e.certFailed.With(prometheus.Labels{"path": path, "hostname": hostname, "nodename": nodename})
			continue
		}
		cert, err := x509.ParseCertificate(block)
		if err != nil {
			glog.Warningf("Couldn't parse %s: %s", path, err.Error())
			ch <- e.certFailed.With(prometheus.Labels{"path": path, "hostname": hostname, "nodename": nodename})
			continue
		}

		defaultPromLabels := prometheus.Labels{
			"path":            path,
			"issuer":          cert.Issuer.String(),
			"alg":             cert.SignatureAlgorithm.String(),
			"version":         strconv.Itoa(cert.Version),
			"subject":         cert.Subject.String(),
			"dns_names":       strings.Join(cert.DNSNames, ","),
			"email_addresses": strings.Join(cert.EmailAddresses, ","),
			"hostname":        hostname,
			"nodename":        nodename,
		}
		var promLabels = make(prometheus.Labels)
		for _, l := range e.includeLabels {
			if val, ok := defaultPromLabels[l]; ok {
				promLabels[l] = val
			}
		}

		since := time.Until(cert.NotAfter)
		e.certExpiry.With(promLabels).Set(since.Seconds())
		ch <- e.certExpiry.With(promLabels)
	}

}

// New creates an instance of Exporter and returns it
func New(includeLabels ...string) *Exporter {
	defaultPromLabels := []string{"path", "issuer", "alg", "version", "subject", "dns_names", "email_addresses", "hostname", "nodename"}
	promLabels := []string{}

	if len(includeLabels) == 0 {
		promLabels = defaultPromLabels
	} else {
		for _, i := range includeLabels {
			for _, f := range defaultPromLabels {
				if i == f {
					promLabels = append(promLabels, i)
				}
			}
		}
	}
	return &Exporter{
		includeLabels: promLabels,
		certExpiry: prometheus.NewGaugeVec(prometheus.GaugeOpts{
			Namespace: "ssl_certificate",
			Subsystem: "expiry",
			Name:      "seconds",
			Help:      "Number of seconds until certificate expires",
		},
			promLabels),
		certFailed: prometheus.NewGaugeVec(prometheus.GaugeOpts{
			Namespace: "ssl_certificate",
			Subsystem: "expiry",
			Name:      "failed",
			Help:      "files that were failed to process",
		},
			[]string{"path", "hostname", "nodename"}),
	}
}
