package service

import (
	"bytes"
	"io"
	"net/http"
	"testing"
)

func TestCopyRequest(t *testing.T) {
	req, err := http.NewRequest("GET", "http://localhost:8080/test?test=123", nil)
	req.Body = io.NopCloser(bytes.NewReader([]byte("test")))
	if err != nil {
		t.Fatal(err)
	}

	buffer, err := copyRequest(req, "123", "/test")
	if err != nil {
		t.Fatal(err)
	}

	str := buffer.String()
	if str != "GET /test?test=123 HTTP/1.1\r\nHost: localhost:8080\r\nUser-Agent: Go-http-client/1.1\r\nContent-Length: 4\r\nDify-Hook-Id: 123\r\nDify-Hook-Url: http://localhost:8080/e/123/test\r\n\r\ntest" {
		t.Fatal("request body is not equal, ", str)
	}
}
