package exporter

import (
	"testing"
)

func TestNew(t *testing.T) {
	e := New()
	// Roots should be empty
	if len(e.roots) != 0 {
		t.Fatalf("roots expected to be %d, got %d", 0, len(e.roots))
	}
	// Set new root
	roots := []string{"/etc/ssl", "/etc/kubernetes", "/etc/origin"}
	e.SetRoots(roots)
	if len(e.roots) != 3 {
		t.Fatalf("roots expected to be %d, got %d", len(roots), len(e.roots))
	}
}

func TestIsCertFile(t *testing.T) {
	certs := []string{"/etc/ssl/ca.pem", "~/.certs/mydomain.crt", "custom-certificate.cert", "./current/dir/server.cer"}
	for _, cert := range certs {
		if !isCertFile(cert) {
			t.Fatalf("Path %s expected to return true, got false", cert)
		}
	}
	notCerts := []string{"/etc/ssl/ca.pem/dir", "~/.certs/mydomain.crt.txt", "custom-certificate", "./current/dir/server.cer-cer"}
	for _, cert := range notCerts {
		if isCertFile(cert) {
			t.Fatalf("Path %s expected to return false, got true", cert)
		}
	}
}
