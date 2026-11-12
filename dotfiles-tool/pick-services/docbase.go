package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"regexp"
	"slices"
	"strconv"
	"time"
)

type docbaseGroup struct {
	Name string `json:"name"`
	ID   int    `json:"id"`
}

type docbasePost struct {
	ID    int    `json:"id"`
	Title string `json:"title"`
	Body  string `json:"body"`
	Scope string `json:"scope"`
	Draft bool   `json:"draft"`
	Tags  []struct {
		Name string `json:"name"`
	} `json:"tags"`
	Groups []docbaseGroup `json:"groups"`
}

type postFields struct {
	Title  string   `json:"title"`
	Body   string   `json:"body"`
	Scope  string   `json:"scope"`
	Draft  bool     `json:"draft"`
	Tags   []string `json:"tags"`
	Groups []string `json:"groups"`
}

type postDocument struct {
	ID     string     `json:"id,omitempty"`
	Fields postFields `json:"fields"`
}

func (p docbasePost) fields() postFields {
	fields := postFields{Title: p.Title, Body: p.Body, Scope: p.Scope, Draft: p.Draft, Tags: []string{}, Groups: []string{}}
	if fields.Scope == "" {
		fields.Scope = "private"
	}
	for _, tag := range p.Tags {
		fields.Tags = append(fields.Tags, tag.Name)
	}
	for _, group := range p.Groups {
		fields.Groups = append(fields.Groups, group.Name)
	}
	return fields
}

func (p postFields) changes(from postFields) map[string]any {
	changed := map[string]any{}
	if p.Title != from.Title {
		changed["title"] = p.Title
	}
	if p.Body != from.Body {
		changed["body"] = p.Body
	}
	if p.Scope != from.Scope {
		changed["scope"] = p.Scope
	}
	if p.Draft != from.Draft {
		changed["draft"] = p.Draft
	}
	if !slices.Equal(p.Tags, from.Tags) {
		changed["tags"] = p.Tags
	}
	if !slices.Equal(p.Groups, from.Groups) {
		changed["groups"] = p.Groups
	}
	return changed
}

func docbase(c client, opts options, input io.Reader) (any, error) {
	switch opts.resource {
	case "posts", "templates":
		return docbaseCandidates(c, opts.resource)
	case "read", "write":
		for _, id := range []string{opts.id, opts.template} {
			if id != "" && !postIDPattern.MatchString(id) {
				return nil, serviceError("Invalid DocBase post ID")
			}
		}
	default:
		return nil, serviceError("Unknown DocBase operation")
	}
	if opts.resource == "read" {
		return readPost(c, opts)
	}
	return writePost(c, opts.id, input)
}

func docbaseCandidates(c client, resource string) ([]json.RawMessage, error) {
	filter := "desc:changed_at"
	if resource == "templates" {
		filter = "tag:template"
	}
	posts := []json.RawMessage{}
	for page := 1; ; page++ {
		var response struct {
			Posts []json.RawMessage `json:"posts"`
			Meta  struct {
				NextPage string `json:"next_page"`
			} `json:"meta"`
		}
		query := url.Values{"q": {filter}, "page": {strconv.Itoa(page)}, "per_page": {"100"}}
		if err := c.request(http.MethodGet, "posts", query, nil, &response); err != nil {
			return nil, err
		}
		posts = append(posts, response.Posts...)
		if len(response.Posts) == 0 || response.Meta.NextPage == "" {
			return posts, nil
		}
	}
}

func readPost(c client, opts options) (postDocument, error) {
	id := opts.id
	if opts.template != "" {
		id = opts.template
	}
	if id == "" {
		return postDocument{Fields: postFields{Scope: "private", Draft: true, Tags: []string{}, Groups: []string{}}}, nil
	}
	var post docbasePost
	if err := c.request(http.MethodGet, "posts/"+id, nil, nil, &post); err != nil {
		return postDocument{}, err
	}
	fields := post.fields()
	if opts.template != "" {
		fields.Tags = slices.DeleteFunc(fields.Tags, func(tag string) bool { return tag == "template" })
		if err := expandTemplate(c, &fields, time.Now()); err != nil {
			return postDocument{}, err
		}
	}
	return postDocument{Fields: fields}, nil
}

func writePost(c client, id string, input io.Reader) (postDocument, error) {
	var payload struct {
		Fields   postFields
		Original postFields
	}
	if err := json.NewDecoder(input).Decode(&payload); err != nil {
		return postDocument{}, err
	}
	fields := payload.Fields
	resource, method := "posts", http.MethodPost
	data := map[string]any{"title": fields.Title, "body": fields.Body, "scope": fields.Scope,
		"draft": fields.Draft, "tags": fields.Tags, "groups": fields.Groups}
	if id != "" {
		resource, method = "posts/"+id, http.MethodPatch
		var current docbasePost
		if err := c.request(http.MethodGet, resource, nil, nil, &current); err != nil {
			return postDocument{}, err
		}
		remote := current.fields()
		if len(remote.changes(payload.Original)) != 0 {
			return postDocument{}, serviceError("DocBase post changed remotely. Save a copy of your edits before reloading.")
		}
		data = fields.changes(remote)
		if len(data) == 0 {
			return postDocument{ID: id, Fields: remote}, nil
		}
	}
	_, groupsChanged := data["groups"]
	_, scopeChanged := data["scope"]
	delete(data, "groups")
	if fields.Scope == "group" && (groupsChanged || scopeChanged) {
		var groups []docbaseGroup
		if err := c.request(http.MethodGet, "groups", url.Values{"per_page": {"200"}}, nil, &groups); err != nil {
			return postDocument{}, err
		}
		ids := make(map[string]int, len(groups))
		for _, group := range groups {
			ids[group.Name] = group.ID
		}
		selected := make([]int, 0, len(fields.Groups))
		for _, name := range fields.Groups {
			group, ok := ids[name]
			if !ok {
				return postDocument{}, serviceError("DocBase group scope requires valid group names")
			}
			selected = append(selected, group)
		}
		if len(selected) == 0 {
			return postDocument{}, serviceError("DocBase group scope requires valid group names")
		}
		data["scope"], data["groups"] = "group", selected
	}
	data["notice"] = false
	var saved docbasePost
	if err := c.request(method, resource, nil, data, &saved); err != nil {
		return postDocument{}, err
	}
	if saved.ID == 0 {
		return postDocument{}, serviceError("DocBase did not return a post ID")
	}
	return postDocument{ID: strconv.Itoa(saved.ID), Fields: saved.fields()}, nil
}

var templateVariable = regexp.MustCompile(`%\{([a-zA-Z_]+)(?::([+-]\d+)([ymdw]))?\}`)

func expandTemplate(c client, fields *postFields, now time.Time) error {
	var profile map[string]any
	var profileErr error
	expand := func(match string) string {
		parts := templateVariable.FindStringSubmatch(match)
		key, amount, unit := parts[1], parts[2], parts[3]
		profileKey := map[string]string{"name": "name", "me": "name", "id": "id", "avatar": "profile_image_url", "icon": "profile_image_url"}[key]
		if profileKey != "" && amount == "" {
			if profile == nil && profileErr == nil {
				profileErr = c.request(http.MethodGet, "profile", nil, nil, &profile)
			}
			if value, ok := profile[profileKey]; ok {
				return fmt.Sprint(value)
			}
			return match
		}
		date := now
		n, _ := strconv.Atoi(amount)
		switch unit {
		case "y":
			date = date.AddDate(n, 0, 0)
		case "m":
			date = date.AddDate(0, n, 0)
		case "d":
			date = date.AddDate(0, 0, n)
		case "w":
			date = date.AddDate(0, 0, n*7)
		}
		weekday := int(date.Weekday())
		values := map[string]any{
			"year": date.Year() % 100, "Year": date.Year(), "month": int(date.Month()), "Month": int(date.Month()),
			"monthname": date.Month(), "Monthname": date.Month(), "day": date.Day(),
			"week": weekday, "Week": weekday, "weekday": weekday, "Weekday": weekday,
			"week_en": date.Format("Mon"), "beginning_of_week": date.AddDate(0, 0, -weekday).Format("Mon Jan 02 2006"),
			"hour": now.Hour(), "hours": now.Hour(), "minute": now.Minute(), "minutes": now.Minute(),
			"second": now.Second(), "seconds": now.Second(), "emoji": "👍",
		}
		if value, ok := values[key]; ok {
			return fmt.Sprint(value)
		}
		return match
	}
	fields.Title = templateVariable.ReplaceAllStringFunc(fields.Title, expand)
	fields.Body = templateVariable.ReplaceAllStringFunc(fields.Body, expand)
	return profileErr
}
