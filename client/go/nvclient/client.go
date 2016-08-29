package nvclient

import (
	"bufio"
	"errors"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"regexp"
	"strings"

	"github.com/lestrrat/go-libxml2"
	"github.com/lestrrat/go-libxml2/clib"
	"github.com/lestrrat/go-libxml2/types"

	logger "github.com/atclate/go-logger"
)

type Client interface {
	GetObjects(objecttypes string, conditions map[string][]string, includes map[string][]string) (Result, error)
	SetObjects(objecttypes string, conditions map[string][]string, includes map[string][]string, set map[string]string, login string) (string, error)
	GetAllSubsystemNames(objectType string) ([]string, error)
}

func NewNvClient(host string, login string, httpClientCallback func(username string) *http.Client, input *bufio.Reader) Client {
	client := &NvClient{
		server:             host,
		username:           login,
		HttpClientCallback: httpClientCallback,
	}
	client.Input = input
	return client
}

type NvClient struct {
	username           string
	server             string
	HttpClientCallback func(username string) *http.Client

	Input *bufio.Reader

	redirflag      bool
	numRedirects   int
	subsystemNames []string
}

func (d *NvClient) GetServer() string {
	return d.server
}

func (f *NvClient) GetObjects(object_type string, conditions map[string][]string, includes map[string][]string) (Result, error) {
	i, err := f.GetAllSubsystemNames(object_type)
	if err != nil {
		return nil, err
	}
	includes["include"] = intersection(i, includes["include"])

	u := f.getSearchUrl(object_type, conditions, includes)
	logger.Debug.Println(fmt.Sprintf("URL: %v", u))

	resp, _ := f.HttpClientCallback(f.username).Get(u)

	responseStr, err := readResponseBody(resp.Body)
	if err != nil {
		log.Fatal("Unable to read response body.")
	}

	res, err := f.getFieldValue(responseStr)
	return res, err
}

func (f *NvClient) SetObjects(object_type string, conditions map[string][]string, includes map[string][]string, set map[string]string, login string) (string, error) {
	_, err := f.GetAllSubsystemNames(object_type)
	if err != nil {
		return "Unable to get all subsystem names.", err
	}

	u := f.getSearchUrl(object_type, conditions, includes)
	logger.Debug.Println(fmt.Sprintf("Search URL: %v", u))

	resp, _ := f.HttpClientCallback(f.username).Get(u)

	responseStr, err := readResponseBody(resp.Body)
	if err != nil {
		log.Fatal("Unable to read response body.")
	}

	res, err := GetResultsFromResponse(responseStr)

	numSuccess := 0

	switch t := res.(type) {
	case *ResultArray:
		if len(t.Array) > 0 {
			con := PromptUserConfirmation(fmt.Sprintf("This will update %v entry, continue?  [y/N]: ", len(t.Array)), f.Input)
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
								fmt.Println("Error creating PUT request for url: " + u)
							} else {
								logger.Debug.Printf("PUT Request: %v", req)
								isRedirect := true
								err = nil
								client := f.HttpClientCallback(login)
								for isRedirect && err == nil {
									fmt.Printf("%v url: %V\n", req.Method, req.URL)
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
									fmt.Printf("Error requesting PUT request for url: %v\nError: %v\n", u, err)
								} else {
									body, err := readResponseBody(resp.Body)
									if err == nil {
										logger.Debug.Printf("Success Response Body:\n%v\n", body)
										numSuccess++
									} else {
										fmt.Printf("Error: %v", err)
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

	con := PromptUserConfirmation(fmt.Sprintf("This will create new entry (%v), continue?  [y/N]: ", name), f.Input)
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
			fmt.Println("Error creating POST request for url: " + u)
		} else {
			logger.Debug.Printf("POST Request: %v", req)
			isRedirect := true
			err = nil
			for isRedirect && err == nil {
				req, _ = http.NewRequest(req.Method, req.URL.String(), nil)
				resp, err = f.HttpClientCallback(login).Do(req)
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
				fmt.Printf("Error requesting PUT request for url: %v\nError: %v\n", u, err)
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

func (f *NvClient) GetAllFields(object_type string, command map[string][]string, includes map[string][]string, flags []string) (Result, error) {
	fields, err := f.GetAllSubsystemNames(object_type)
	if err != nil {
		return nil, err
	}
	m := make(map[string][]string, 0)
	m["include"] = fields
	u := f.getSearchUrl(object_type, command, includes)

	resp, _ := f.HttpClientCallback(f.username).Get(u)

	logger.Debug.Println(fmt.Sprintf("URL: %v", u))

	responseStr, err := readResponseBody(resp.Body)
	if err != nil {
		log.Fatal("Unable to read response body.")
	}

	return GetResultsFromResponse(responseStr)
}

func (f *NvClient) GetAllSubsystemNames(objectType string) ([]string, error) {
	var err error
	if len(f.subsystemNames) == 0 {
		// query http://opsdb.wc1.example.com/nodes/field_names.xml
		u := fmt.Sprintf("%v/%v/field_names.xml", f.GetServer(), objectType)

		// store search_shortcuts
		resp, err := f.HttpClientCallback(f.username).Get(u)
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

func (f *NvClient) getSubsystemNamesFromResponse(response string) ([]string, error) {
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

func (f *NvClient) getSearchUrl(object_type string, searchCommand map[string][]string, includes map[string][]string) string {
	// start organizing commands issued
	values := url.Values{}
	for k, v := range searchCommand {
		values = mergeMapOfStringArrays(values, separate(v, k))
	}

	for k, v := range includes {
		m := make(map[string][]string, 0)
		for _, f := range v {

			var fieldsRegex = regexp.MustCompile(`([^[]+)\[.+\]`)
			if fieldsRegex.MatchString(f) {
				// field[subfield]
				fieldName := fieldsRegex.FindAllStringSubmatch(f, -1)
				val := []string{""}
				if strings.Contains(f, "[tags]") {
					val = append(val, "tags")
				}
				m[k+"["+fieldName[0][1]+"]"] = val
			} else {
				// field
				m[k+"["+f+"]"] = []string{""}
			}
		}
		values = mergeMapOfStringArrays(values, m)
	}

	return fmt.Sprintf("%v/%v.xml?%v", f.GetServer(), object_type, values.Encode())
}

func (f *NvClient) getSetUrl(object_type string, id string, query string) string {
	return fmt.Sprintf("%v/%v/%v.xml?%v", f.GetServer(), object_type, id, query)
}

func (f *NvClient) getCreateUrl(object_type string, query string) string {
	return fmt.Sprintf("%v/%v.xml?%v", f.GetServer(), object_type, query)
}

func (f *NvClient) getFieldValue(response string) (Result, error) {
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
