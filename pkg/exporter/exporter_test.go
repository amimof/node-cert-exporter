package exporter

import (
	"bytes"
	"encoding/pem"
	"strings"
	"testing"
)

const testCert = `
-----BEGIN CERTIFICATE-----
MIICAjCCAWugAwIBAgIUQYz6rBI0tJm0mQwuHVZJQey5sc8wDQYJKoZIhvcNAQEL
BQAwEzERMA8GA1UEAwwIdGVzdC5jb20wHhcNMjAwNTA3MTMzMDI4WhcNMjEwNTA3
MTMzMDI4WjATMREwDwYDVQQDDAh0ZXN0LmNvbTCBnzANBgkqhkiG9w0BAQEFAAOB
jQAwgYkCgYEA20I4FBxqE75KODcqagOPZn04qZsj6rFGgCNG34EzCQ3FyZRvdYSy
5mhLYQPyCOGETRAAaC95h5K1v0sZQISOascpY1syKmkWWRstCmR/B7vfW+vme4z8
JHKk3jxruOYW+SYtH7G2FpMISuMAs9qxZj1jsPPXhwqwkpq+OLVBH7MCAwEAAaNT
MFEwHQYDVR0OBBYEFDc1dv0t3hdSPlVo0rDfQ/9Ze8rIMB8GA1UdIwQYMBaAFDc1
dv0t3hdSPlVo0rDfQ/9Ze8rIMA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZIhvcNAQEL
BQADgYEAofnkXC6WYoYisMXJE6XOfxhAbrRTQswWKfo5EW2T3BnjICrplBlG3paq
U388DQASqCKiadA6QFdkDx5N8JAMbswLK1JrcdgdDx/+zrzIo4Pbm1oM6SXwfhcH
p1yLjQp67exL1tdjQeOZgFDe55oSygFAkUD1rnKNolUxsMYkPPc=
-----END CERTIFICATE-----
`
const testKey = `
-----BEGIN PRIVATE KEY-----
MIICdwIBADANBgkqhkiG9w0BAQEFAASCAmEwggJdAgEAAoGBANtCOBQcahO+Sjg3
KmoDj2Z9OKmbI+qxRoAjRt+BMwkNxcmUb3WEsuZoS2ED8gjhhE0QAGgveYeStb9L
GUCEjmrHKWNbMippFlkbLQpkfwe731vr5nuM/CRypN48a7jmFvkmLR+xthaTCErj
ALPasWY9Y7Dz14cKsJKavji1QR+zAgMBAAECgYBw0b/9SSmkAxQ5nNksN6y/9csE
Kpnul01Jfd1oABj8naOaN9CqTZ+oQx4WS2ts+m2TIZq0AUmtYuY2CjRyKEMG5kle
kW0AOAgvN6xrIhE6iaX0xQeZleiJ1Ag0RAHrVqT6CztEq7cXv+1Dhf6kbBY/7MHP
ySJlQ4g9nPK2KkJ1wQJBAPpEMSLUEDbMnHdiT/4U4CDKhgFI1fpCwFWlKShzZuzd
KHa6NVwvEyB4ZuWj4dbM0TxVoX8KUtNYY48iyp/YxiMCQQDgSCrdl4bp8Cm+5XGr
gnVCj5oWjXEepkM1G/IFVQwsVE3h7BtGyVoWxfn68n2rFSb7D0VZPjz2Te0z9gSw
97ExAkEA+OsadCm4dsjMV3HRXkYlJnhJEL4BFgmOg6DibvlZRf4yYOSUbjvkKkeX
EJEP7zWIZxpEprb96nffjl5satCRQQJAZ0FSWspUFoe28Gf5uRhKm+Y47oEXvyCU
eHLxLXtGK3J0mLp2pFQ24Z0rxVi2enk2hQc2yitZLZwaxH1TE5Y1QQJBAI0nFg+C
8VbocETPOgR8RGeONRRsC9IGR3r1ZaSQhJGaq+isqEryczW2zIaDUbSGrbpZQNBo
raQ6DbqHFLX6/O8=
-----END PRIVATE KEY-----
`

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
	certs := []string{"/etc/ssl/ca.pem", "~/.certs/mydomain.crt", "custom-certificate.cert", "./current/dir/server.cer", "/data/cert.pfx"}
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

func TestGetFirstCertBlock(t *testing.T) {
	tables := []struct {
		pem    []byte
		result []byte
	}{
		{[]byte(testKey), nil},
		{[]byte(testCert), []byte(testCert)},
		{[]byte(strings.Join([]string{testCert, testKey}, "\n")), []byte(testCert)},
		{[]byte(strings.Join([]string{testKey, testCert}, "\n")), []byte(testCert)},
		{[]byte(strings.Join([]string{testKey, testCert, testKey}, "\n")), []byte(testCert)},
		{[]byte(strings.Join([]string{testKey, testKey, testCert}, "\n")), []byte(testCert)},
	}

	for _, table := range tables {
		res := getFirstCertBlock(table.pem)
		expected, _ := pem.Decode(table.result)

		if (table.result == nil && res != nil) ||
			(table.result != nil && !bytes.Equal(expected.Bytes, res)) {
			t.Errorf("getFirstCertBlock did not return expected result")
		}
	}
}
