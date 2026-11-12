package main

import (
	"encoding/json"
	"io"
	"net/http"
	"net/url"
	"slices"
	"strconv"
	"strings"
)

type noteFields struct {
	Title string `json:"title"`
	Body  string `json:"body"`
}

type noteMetadata struct {
	BookID string   `json:"bookId"`
	Tags   []string `json:"tags"`
	Status string   `json:"status"`
}

type noteDocument struct {
	Fields   noteFields   `json:"fields"`
	Metadata noteMetadata `json:"metadata"`
}

func inkdrop(c client, opts options, input io.Reader) (any, error) {
	switch opts.resource {
	case "notes", "books", "tags":
		return inkdropCandidates(c, opts.resource)
	case "read", "write", "metadata":
		return inkdropDocument(c, opts, input)
	default:
		return nil, serviceError("Unknown Inkdrop operation")
	}
}

func inkdropCandidates(c client, resource string) ([]json.RawMessage, error) {
	items := []json.RawMessage{}
	if resource != "notes" {
		err := c.request(http.MethodGet, resource, nil, nil, &items)
		return items, err
	}
	for {
		query := url.Values{
			"limit": {"100"}, "skip": {strconv.Itoa(len(items))},
			"sort": {"updatedAt"}, "descending": {"true"},
		}
		var batch []json.RawMessage
		if err := c.request(http.MethodGet, resource, query, nil, &batch); err != nil {
			return nil, err
		}
		items = append(items, batch...)
		if len(batch) < 100 {
			return items, nil
		}
	}
}

func inkdropDocument(c client, opts options, input io.Reader) (noteDocument, error) {
	if !strings.HasPrefix(opts.id, "note:") || !inkdropIDPattern.MatchString(opts.id) {
		return noteDocument{}, serviceError("Invalid Inkdrop note ID")
	}
	// Keep fields outside the editor's model when sending the document back.
	var note map[string]any
	if err := c.request(http.MethodGet, opts.id, nil, nil, &note); err != nil {
		return noteDocument{}, err
	}
	revision, _ := note["_rev"].(string)
	if note["_id"] != opts.id || revision == "" {
		return noteDocument{}, serviceError("Inkdrop note is missing or is read-only")
	}
	title, _ := note["title"].(string)
	body, _ := note["body"].(string)
	fields := noteFields{Title: title, Body: body}
	if opts.resource != "read" {
		var payload struct {
			Fields   noteFields
			Original noteFields
			Action   string
			Value    string
		}
		if err := json.NewDecoder(input).Decode(&payload); err != nil {
			return noteDocument{}, err
		}
		if opts.resource == "write" {
			if fields != payload.Original {
				return noteDocument{}, serviceError("Inkdrop note changed remotely. Save a copy of your edits before reloading.")
			}
			fields = payload.Fields
			note["title"], note["body"] = fields.Title, fields.Body
		} else if err := changeNoteMetadata(note, payload.Action, payload.Value); err != nil {
			return noteDocument{}, err
		}
		var saved struct {
			OK bool
			ID string
		}
		if err := c.request(http.MethodPost, "notes", nil, note, &saved); err != nil {
			return noteDocument{}, err
		}
		if !saved.OK || saved.ID != opts.id {
			return noteDocument{}, serviceError("Inkdrop did not confirm the write")
		}
	}
	book, _ := note["bookId"].(string)
	status, _ := note["status"].(string)
	if status == "" {
		status = "none"
	}
	return noteDocument{Fields: fields, Metadata: noteMetadata{BookID: book, Status: status, Tags: noteTags(note)}}, nil
}

func noteTags(note map[string]any) []string {
	if tags, ok := note["tags"].([]string); ok {
		return tags
	}
	tags := []string{}
	if raw, ok := note["tags"].([]any); ok {
		for _, tag := range raw {
			if name, ok := tag.(string); ok {
				tags = append(tags, name)
			}
		}
	}
	return tags
}

func changeNoteMetadata(note map[string]any, action, value string) error {
	switch action {
	case "book":
		if strings.HasPrefix(value, "book:") && inkdropIDPattern.MatchString(value) {
			note["bookId"] = value
			return nil
		}
	case "status":
		if slices.Contains([]string{"none", "active", "onHold", "completed", "dropped"}, value) {
			note["status"] = value
			return nil
		}
	case "add_tag", "remove_tag":
		if strings.HasPrefix(value, "tag:") && inkdropIDPattern.MatchString(value) {
			tags := slices.DeleteFunc(noteTags(note), func(tag string) bool { return tag == value })
			if action == "add_tag" {
				tags = append(tags, value)
			}
			note["tags"] = tags
			return nil
		}
	}
	return serviceError("Invalid Inkdrop metadata change")
}
