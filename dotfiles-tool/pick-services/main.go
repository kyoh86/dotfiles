package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"time"

	"github.com/pelletier/go-toml/v2"
)

const docbaseAPI = "https://api.docbase.io/teams/"

var domainPattern = regexp.MustCompile(`^[a-zA-Z0-9-]+$`)
var postIDPattern = regexp.MustCompile(`^[0-9]+$`)
var inkdropIDPattern = regexp.MustCompile(`^(note|book|tag):[a-zA-Z0-9_-]+$`)

type options struct {
	service, resource, domain, id, template string
}

type credentials struct {
	Token    string `json:"token" toml:"token,omitempty"`
	BaseURL  string `json:"baseUrl" toml:"baseUrl,omitempty"`
	Username string `json:"username" toml:"username,omitempty"`
	Password string `json:"password" toml:"password,omitempty"`
}

type serviceError string

func (e serviceError) Error() string { return string(e) }

type client struct {
	baseURL     string
	credentials credentials
	http        *http.Client
}

func newClient(opts options, auth credentials) (client, error) {
	baseURL := docbaseAPI + opts.domain
	if opts.service == "inkdrop" {
		parsed, err := url.Parse(auth.BaseURL)
		if err != nil || (parsed.Scheme != "http" && parsed.Scheme != "https") ||
			parsed.Hostname() == "" || parsed.User != nil || parsed.ForceQuery || parsed.RawQuery != "" || parsed.Fragment != "" {
			return client{}, serviceError("Invalid Inkdrop base URL")
		}
		baseURL = auth.BaseURL
	}
	return client{
		baseURL:     strings.TrimRight(baseURL, "/"),
		credentials: auth,
		http: &http.Client{
			Timeout: 30 * time.Second,
			CheckRedirect: func(*http.Request, []*http.Request) error {
				return http.ErrUseLastResponse
			},
		},
	}, nil
}

func (c client) request(method, resource string, query url.Values, data, result any) error {
	endpoint := c.baseURL + "/" + resource
	if len(query) > 0 {
		endpoint += "?" + query.Encode()
	}
	var body io.Reader
	if data != nil {
		encoded, err := json.Marshal(data)
		if err != nil {
			return err
		}
		body = bytes.NewReader(encoded)
	}
	req, err := http.NewRequest(method, endpoint, body)
	if err != nil {
		return err
	}
	req.Header.Set("Accept", "application/json")
	if data != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	if c.credentials.Token != "" {
		req.Header.Set("X-DocBaseToken", c.credentials.Token)
	} else {
		req.SetBasicAuth(c.credentials.Username, c.credentials.Password)
	}
	resp, err := c.http.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return serviceError(fmt.Sprintf("HTTP %d", resp.StatusCode))
	}
	decoder := json.NewDecoder(resp.Body)
	decoder.UseNumber()
	return decoder.Decode(result)
}

func (o options) credentialPath(state string) (string, error) {
	switch o.service {
	case "docbase":
		if !domainPattern.MatchString(o.domain) {
			return "", serviceError("Invalid DocBase domain")
		}
		return filepath.Join(state, "denops-docbase", "teams", o.domain+".toml"), nil
	case "inkdrop":
		return filepath.Join(state, "denops-inkdrop", "credentials.toml"), nil
	default:
		return "", serviceError("Unknown service")
	}
}

func saveCredentials(path string, auth credentials) error {
	dir := filepath.Dir(path)
	if err := os.MkdirAll(dir, 0700); err != nil {
		return err
	}
	file, err := os.CreateTemp(dir, ".credentials-*")
	if err != nil {
		return err
	}
	defer os.Remove(file.Name())
	encodeErr := toml.NewEncoder(file).Encode(auth)
	closeErr := file.Close()
	if err := errors.Join(encodeErr, closeErr); err != nil {
		return err
	}
	return os.Rename(file.Name(), path)
}

func run(opts options, state string, input io.Reader) (any, error) {
	path, err := opts.credentialPath(state)
	if err != nil {
		return nil, err
	}
	var auth credentials
	if opts.resource == "login" {
		if err := json.NewDecoder(input).Decode(&auth); err != nil {
			return nil, err
		}
	} else {
		data, err := os.ReadFile(path)
		if errors.Is(err, os.ErrNotExist) {
			login := "DocbaseLogin"
			if opts.service == "inkdrop" {
				login = "InkdropLogin"
			}
			return nil, serviceError("Missing credentials. Run :" + login + " first.")
		}
		if err != nil {
			return nil, err
		}
		if err := toml.Unmarshal(data, &auth); err != nil {
			return nil, err
		}
	}
	c, err := newClient(opts, auth)
	if err != nil {
		return nil, err
	}
	if opts.resource == "login" {
		resource, query := "profile", url.Values(nil)
		if opts.service == "inkdrop" {
			resource, query = "notes", url.Values{"limit": {"1"}}
		}
		var result json.RawMessage
		if err := c.request(http.MethodGet, resource, query, nil, &result); err != nil {
			return nil, err
		}
		return struct{}{}, saveCredentials(path, auth)
	}
	if opts.service == "docbase" {
		return docbase(c, opts, input)
	}
	return inkdrop(c, opts, input)
}

func main() {
	if len(os.Args) < 3 {
		fmt.Fprintln(os.Stderr, "usage: pick-services SERVICE RESOURCE [--domain DOMAIN] [--id ID] [--template ID]")
		os.Exit(2)
	}
	opts := options{service: os.Args[1], resource: os.Args[2]}
	flags := flag.NewFlagSet("pick-services", flag.ExitOnError)
	flags.StringVar(&opts.domain, "domain", "wacul", "DocBase team domain")
	flags.StringVar(&opts.id, "id", "", "document ID")
	flags.StringVar(&opts.template, "template", "", "DocBase template ID")
	flags.Parse(os.Args[3:])
	state := os.Getenv("XDG_STATE_HOME")
	if state == "" {
		home, err := os.UserHomeDir()
		if err != nil {
			fmt.Fprintln(os.Stderr, "Cannot locate the home directory")
			os.Exit(1)
		}
		state = filepath.Join(home, ".local", "state")
	}
	result, err := run(opts, state, os.Stdin)
	if err == nil {
		err = json.NewEncoder(os.Stdout).Encode(result)
	}
	if err != nil {
		var detail serviceError
		if errors.As(err, &detail) {
			fmt.Fprintf(os.Stderr, "%s: %s\n", opts.service, detail)
		} else {
			fmt.Fprintf(os.Stderr, "%s: %s failed. Check credentials and service availability.\n", opts.service, opts.resource)
		}
		os.Exit(1)
	}
}
