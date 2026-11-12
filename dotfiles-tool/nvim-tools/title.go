package main

import (
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"

	"golang.org/x/net/html"
	"golang.org/x/net/html/charset"
)

func fetchTitle(address string) (string, error) {
	parsed, err := url.Parse(address)
	if err != nil || (parsed.Scheme != "http" && parsed.Scheme != "https") || parsed.Host == "" {
		return "", fmt.Errorf("expected an HTTP or HTTPS URL")
	}
	client := http.Client{Timeout: 10 * time.Second}
	response, err := client.Get(parsed.String())
	if err != nil {
		return "", err
	}
	defer response.Body.Close()
	if response.StatusCode < 200 || response.StatusCode >= 300 {
		return "", fmt.Errorf("HTTP %d", response.StatusCode)
	}
	reader, err := charset.NewReader(io.LimitReader(response.Body, 2<<20), response.Header.Get("Content-Type"))
	if err != nil {
		return "", err
	}
	tokenizer := html.NewTokenizer(reader)
	for {
		switch tokenizer.Next() {
		case html.ErrorToken:
			if tokenizer.Err() == io.EOF {
				return "", nil
			}
			return "", tokenizer.Err()
		case html.StartTagToken:
			tag, _ := tokenizer.TagName()
			if string(tag) == "title" && tokenizer.Next() == html.TextToken {
				return strings.Join(strings.Fields(string(tokenizer.Text())), " "), nil
			}
		}
	}
}
