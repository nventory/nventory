// Copyright © 2016 Andrew Cheung <ac1493@yp.com>
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package nvclient

import (
	"bufio"
	"errors"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"os"
	"regexp"
	"strings"

	"github.com/lestrrat/go-libxml2"
	"github.com/lestrrat/go-libxml2/clib"
	"github.com/lestrrat/go-libxml2/types"

	logger "github.com/atclate/go-logger"
)

/******************************************************
 * Client - interface for nventory client.
 *****************************************************/
type Client interface {
	GetObjects(objecttypes string, conditions Conditions, includes []string) (Result, error)
	SetObjects(objecttypes string, conditions Conditions, includes []string, set map[string]string, login string, yes bool) (string, error)
	GetAllSubsystemNames(objectType string) ([]string, error)
}

func NewNventoryClient(login string, input *bufio.Reader) *NventoryClient {
	client := &NventoryClient{
		username:           login,
		Input:              input,
		HttpClient:         NewHttpClient(),
	}
	return client
}

type NventoryClient struct {
	username       string
	server         string
	HttpClient     *HttpClient

	Input          *bufio.Reader

	subsystemNames []string
}

type Conditions map[string][]string

func (c Conditions) GetTypes() []string {
	keys := make([]string, 0, len(c))
	for k := range c {
		keys = append(keys, k)
	}
	return keys
}

func (c Conditions) GetConditionsByType(condition_type string) []string {
	return c[condition_type]
}

type Field string

func (d *NventoryClient) GetServer() string {
	return d.server
}

func (c *NventoryClient) SetServer(server string) {
	c.server = server
	c.HttpClient.SetServer(server)
}

func (f *NventoryClient) GetHttpClientFor(username string) *http.Client {
	if f.HttpClient.httpClientMap == nil {
		f.HttpClient.httpClientMap = make(map[string]*http.Client, 0)
	}

	httpClient := f.HttpClient.httpClientMap[username]
	// Check if client is already initialized.
	if httpClient == nil {
		h, err := f.HttpClient.newHttpClientFor(username, passwordCallback)
		if err != nil {
			logger.Error.Printf("Unable to initialize HTTP Client: %v\n", err)
			os.Exit(1)
		}
		f.HttpClient.httpClientMap[username] = h
		return h
	}
	f.SetServer(f.HttpClient.GetServer())
	return httpClient
}

func (f *NventoryClient) GetObjects(object_type string, conditions Conditions, includes []string) (Result, error) {
	i, err := f.GetAllSubsystemNames(object_type)
	if err != nil {
		return nil, err
	}
	includes = Intersection(i, includes)

	u := f.getSearchUrl(object_type, conditions, includes)
	logger.Debug.Println(fmt.Sprintf("URL: %v", u))

	resp, _ := f.GetHttpClientFor(f.username).Get(u)

	responseStr, err := readResponseBody(resp.Body)
	if err != nil {
		log.Fatal("Unable to read response body.")
	}

	res, err := f.getFieldValue(responseStr)
	return res, err
}

func (f *NventoryClient) SetObjects(object_type string, conditions Conditions, includes []string, set map[string]string, login string, noPrompt bool) (string, error) {
	_, err := f.GetAllSubsystemNames(object_type)
	if err != nil {
		return "Unable to get all subsystem names.", err
	}

	u := f.getSearchUrl(object_type, conditions, includes)
	logger.Debug.Println(fmt.Sprintf("Search URL: %v", u))

	resp, _ := f.GetHttpClientFor(f.username).Get(u)

	responseStr, err := readResponseBody(resp.Body)
	if err != nil {
		log.Fatal("Unable to read response body.")
	}

	res, err := GetResultsFromResponse(responseStr)

	numSuccess := 0

	switch t := res.(type) {
	case *ResultArray:
		if len(t.Array) > 0 {
			con := noPrompt || PromptUserConfirmation(fmt.Sprintf("This will update %v entry, continue?  [y/N]: ", len(t.Array)), f.Input)
			if con {
				for _, item := range t.Array {
					switch t2 := item.(type) {
					case *ResultMap:
						idVal := t2.Get("id")
						if idVal == nil {

						} else if id, ok := idVal.(*ResultValue); ok && id.Value != "" {
							logger.Debug.Printf("Set: %v", set)
							values := url.Values{}
							for k, v := range set {
								re, err := regexp.Compile(`[.+]`)
								if err == nil && re.Match([]byte(k)) {
									values.Set(k, v)
								} else {
									values.Set(t2.ID()+"["+k+"]", v)
								}
							}

							u := f.getSetUrl(object_type, id.Value, values.Encode())
							logger.Debug.Printf("Set URL: %v\n", u)

							req, err := http.NewRequest("PUT", u, nil)
							if err != nil {
								logger.Error.Println("Error creating PUT request for url: " + u)
							} else {
								logger.Debug.Printf("PUT Request: %v", req)
								isRedirect := true
								err = nil
								client := f.GetHttpClientFor(login)
								for isRedirect && err == nil {
									logger.Debug.Printf("%v url: %V\n", req.Method, req.URL)
									req, _ = http.NewRequest(req.Method, req.URL.String(), nil)
									resp, err = client.Do(req)
									isRedirect = isRedirectResponse(resp)
									if isRedirect {
										logger.Debug.Printf("Redirecting to %v from %v\n", getHeaderLocation(resp), req.URL.String())
										u, err := url.Parse(getHeaderLocation(resp))
										if err == nil {
											req.URL = u
										}
									}
								}

								if err != nil {
									logger.Error.Printf("Error requesting PUT request for url: %v\nError: %v\n", u, err)
								} else {
									body, err := readResponseBody(resp.Body)
									if err == nil {
										logger.Debug.Printf("Success Response Body:\n%v\n", body)
										numSuccess++
									} else {
										logger.Error.Printf("Error: %v", err)
									}
								}
							}
						}
					}
				}
			} else {
				return fmt.Sprintln("Cancelled"), nil
			}
			msg := fmt.Sprintf("%v out of %v update(s) succeeded.\n", numSuccess, len(t.Array))
			if numSuccess != len(t.Array) {
				err = errors.New(fmt.Sprintf("%v out of %v update(s) failed.\n", len(t.Array)-numSuccess, len(t.Array)))
			}
			return msg, err
		}
	}

	name := ""
	if conditions[""] != nil {
		name = conditions[""][0]
	}
	if set["name"] == "" || len(set["name"]) == 0 {
		set["name"] = name
	} else {
		name = set["name"]
	}

	con := noPrompt || PromptUserConfirmation(fmt.Sprintf("This will create new entry (%v), continue?  [y/N]: ", name), f.Input)
	if con {
		logger.Debug.Printf("Set: %v", set)
		values := url.Values{}
		for k, v := range set {
			re, err := regexp.Compile(`[.+]`)
			if err == nil && re.Match([]byte(k)) {
				values.Set(k, v)
			} else {
				values.Set(singularize(object_type)+"["+k+"]", v)
			}
		}

		u := f.getCreateUrl(object_type, values.Encode())
		logger.Debug.Printf("Create URL: %v\n", u)

		req, err := http.NewRequest("POST", u, nil)
		if err != nil {
			logger.Error.Println("Error creating POST request for url: " + u)
		} else {
			logger.Debug.Printf("POST Request: %v", req)
			isRedirect := true
			err = nil
			for isRedirect && err == nil {
				req, _ = http.NewRequest(req.Method, req.URL.String(), nil)
				resp, err = f.GetHttpClientFor(login).Do(req)
				logger.Debug.Printf("Response from %v:\n%v\n", req.URL.String(), resp)
				isRedirect = isRedirectResponse(resp)
				if isRedirect {
					logger.Debug.Printf("Redirecting to %v from %v\n", getHeaderLocation(resp), req.URL.String())
					u, err := url.Parse(getHeaderLocation(resp))
					if err == nil {
						req.URL = u
					}
				}
			}

			if err != nil {
				logger.Error.Printf("Error requesting PUT request for url: %v\nError: %v\n", u, err)
			} else {
				body, err := readResponseBody(resp.Body)
				if err == nil {
					logger.Debug.Printf("Success Response Body:\n%v\n", body)
					return fmt.Sprintf("Successfully created node (%v)\n", name), err
				} else {
					msg := fmt.Sprintf("Error: %v", err)
					return msg, errors.New(msg)
				}
			}
		}
	}

	return fmt.Sprintf("No update was ran.\n"), err
}

func singularize(plural string) string {
	if singular := regexp.MustCompile(`(.*s)es$`).FindAllStringSubmatch(plural, -1); len(singular) > 0 {
		// ip_address(es), status(es)
		return singular[0][1]
	}
	if singular := regexp.MustCompile(`(.*)s$`).FindAllStringSubmatch(plural, -1); len(singular) > 0 {
		// node(s), vip(s)
		return singular[0][1]
	}
	return plural
}

func (f *NventoryClient) GetAllFields(object_type string, command map[string][]string, includes []string, flags []string) (Result, error) {
	fields, err := f.GetAllSubsystemNames(object_type)
	if err != nil {
		return nil, err
	}
	u := f.getSearchUrl(object_type, command, fields)

	resp, _ := f.GetHttpClientFor(f.username).Get(u)
	f.SetServer(f.HttpClient.GetServer())

	logger.Debug.Println(fmt.Sprintf("URL: %v", u))

	responseStr, err := readResponseBody(resp.Body)
	if err != nil {
		log.Fatal("Unable to read response body.")
	}

	return GetResultsFromResponse(responseStr)
}

func (f *NventoryClient) GetAllSubsystemNames(objectType string) ([]string, error) {
	var err error
	if len(f.subsystemNames) == 0 {
		// query http://opsdb.wc1.example.com/nodes/field_names.xml
		u := fmt.Sprintf("%v/%v/field_names.xml", f.GetServer(), objectType)

		// store search_shortcuts
		resp, err := f.GetHttpClientFor(f.username).Get(u)
		if err != nil {
			return f.subsystemNames, err
		}
		responseStr, err := readResponseBody(resp.Body)
		if err != nil {
			log.Fatal("Unable to read response body.")
		}
		search_shortcuts.SaveFieldShortcuts(responseStr, "/field_names", "field_name", []string{}...)
		f.subsystemNames, err = f.getSubsystemNamesFromResponse(responseStr)
	}
	return f.subsystemNames, err
}

func (f *NventoryClient) getSubsystemNamesFromResponse(response string) ([]string, error) {
	ResetShortcuts()

	d, err := libxml2.ParseString(response)
	if err != nil {
		log.Fatal("Unable to parse response as xml:\n%v", response)
	}
	xPathResult, err := d.Find("/field_names")

	set := make(map[string]uint8)
	result := make([]string, 0)
	var found = false
	var iter = xPathResult.NodeIter()
	for iter.Next() {
		found = true
		childNodes, _ := iter.Node().ChildNodes()
		for _, node := range childNodes {
			if node.NodeName() == "field_name" {
				if m := regexp.MustCompile(`^(.*)\[.*\]`).FindAllStringSubmatch(node.NodeValue(), -1); len(m) > 0 {
					// shortcut found
					set[m[0][1]] = 1
				}
			}
		}
	}
	for k := range set {
		result = append(result, k)
	}
	if !found {
		return result, errors.New("No matching objects\n")
	}
	return result, nil
}

func (f *NventoryClient) getSearchUrl(object_type string, searchCommand Conditions, includes []string) string {
	// start organizing commands issued
	values := url.Values{}
	for k, v := range searchCommand {
		values = mergeMapOfStringArrays(values, Separate(v, k))
	}

	for _, f := range includes {
		m := make([]string, 0)

		var fieldsRegex = regexp.MustCompile(`([^[]+)\[.+\]`)
		if fieldsRegex.MatchString(f) {
			// field[subfield]
			fieldName := fieldsRegex.FindAllStringSubmatch(f, -1)
			val := []string{""}
			if strings.Contains(f, "[tags]") {
				val = append(val, "tags")
			}
			m = append(m, fmt.Sprintf("includes[%v]=%v", fieldName[0][1], val))
		} else {
			// field
			m = append(m, fmt.Sprintf("includes[%v]=", f))
		}
	}

	return fmt.Sprintf("%v/%v.xml?%v", f.GetServer(), object_type, values.Encode())
}

func (f *NventoryClient) getSetUrl(object_type string, id string, query string) string {
	return fmt.Sprintf("%v/%v/%v.xml?%v", f.GetServer(), object_type, id, query)
}

func (f *NventoryClient) getCreateUrl(object_type string, query string) string {
	return fmt.Sprintf("%v/%v.xml?%v", f.GetServer(), object_type, query)
}

func (f *NventoryClient) getFieldValue(response string) (Result, error) {
	return GetResultsFromResponse(response)
}

func getChildFieldValue(node types.Node, parent string, fields []string) map[string]string {
	result := make(map[string]string, 0)
	if node.NodeType() == clib.TextNode {
	} else {
		// Non-text child node
		nl, err := node.ChildNodes()
		if len(nl) == 0 && err == nil {
			x := node.(types.Element)
			if attr, err := x.GetAttribute("type"); err == nil && attr.Value() == "array" {
				return result
			}
			// No more child
			fieldName := ""
			if parent == "" {
				fieldName = node.NodeName()
			} else {
				fieldName = parent + "[" + node.NodeName() + "]"
			}
			if addFieldExists(fieldName, fields) {
				result[fieldName] = node.NodeValue()
			}
		} else if len(nl) == 1 && nl.First().NodeType() == clib.TextNode {
			fieldName := ""
			// Only text child left
			if parent == "" {
				fieldName = node.NodeName()
			} else {
				fieldName = parent + "[" + node.NodeName() + "]"
			}
			if addFieldExists(fieldName, fields) {
				result[fieldName] = node.NodeValue()
			}
		} else {
			// Have child nodes.
			for _, n := range nl {
				if strings.Contains(parent, node.NodeName()) {
					result = mergeMapOfStrings(result, getChildFieldValue(n, parent, fields))
				} else if parent == "" {
					result = mergeMapOfStrings(result, getChildFieldValue(n, node.NodeName(), fields))
				} else {
					result = mergeMapOfStrings(result, getChildFieldValue(n, parent+"["+node.NodeName()+"]", fields))
				}
			}
		}
	}
	return result
}

func addFieldExists(field string, filter []string) bool {
	for _, f := range filter {
		if f == field || f == "*" {
			return true
		}
	}
	return false
}

func mergeMapOfStrings(a map[string]string, b map[string]string) map[string]string {
	result := make(map[string]string)
	for k, v := range a {
		result[k] = v
	}
	for k, v := range b {
		result[k] = v
	}
	return result
}
