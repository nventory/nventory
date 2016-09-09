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
	"fmt"
	"log"
	"net/url"
	"os/user"
	"strings"
	"regexp"


	logger "github.com/atclate/go-logger"

	"bufio"
)

const autoreg = "autoreg"

var autoreg_password = "REPLACE_ME_WITH_AUTOREG_PASSWORD"

type NventoryDriver struct {
	server         string
	input          *bufio.Reader
	nventoryClient *NventoryClient
}

func NewNventoryDriver(input *bufio.Reader) *NventoryDriver {
	return &NventoryDriver{
		input: input,
		nventoryClient: NewNventoryClient(autoreg, input),
	}
}

func (d *NventoryDriver) SetServer(s string) {
	d.server = s
	d.nventoryClient.SetServer(s)
}

func (d *NventoryDriver) GetServer() string {
	return d.server
}

func (sc *SetCommands) GetSetFromFlags() map[string]string {
	fs := make(map[string]string, 0)
	for _, ss := range sc.setValueFlags.value {
		for _, s := range strings.Split(ss, ",") {
			splits := strings.Split(s, "=")
			if len(splits) == 2 {
				fs[splits[0]] = splits[1]
			} else {
				log.Fatalf("= required in set flags. (%v doesn't contain '='", s)
			}
		}
	}
	return fs
}

func (f *NventoryDriver) Search(object_type string, conditions map[string][]string, includes []string, fields []string) (Result, error) {
	logger.Debug.Println("searching %v in nventory for %v", object_type, fields)
	return f.nventoryClient.GetObjects(object_type, conditions, includes)
}

func (f *NventoryDriver) Set(object_type string, conditions map[string][]string, includes []string, set map[string]string, npPrompt bool) (string, error) {
	logger.Debug.Println("setting %v in nventory to %v", object_type, set)
	u, _ := user.Current()
	return f.nventoryClient.SetObjects("nodes", conditions, includes, set, u.Username, npPrompt)
}

func (f *NventoryDriver) GetAllSubsystemNames(objectType string) ([]string, error) {
	logger.Debug.Println("searching in nventory for all subsystemnames with search subcommand ", objectType)
	return f.nventoryClient.GetAllSubsystemNames(objectType)
}

func (f *NventoryDriver) GetAllFields(object_type string, command map[string][]string, includes []string, flags []string) (Result, error) {

	client := f.nventoryClient.GetHttpClientFor(autoreg)

	fields, err := f.GetAllSubsystemNames(object_type)
	if err != nil {
		return nil, err
	}
	u := getSearchUrl(f.GetServer(), object_type, command, fields)

	resp, _ := client.Get(u)

	logger.Debug.Println(fmt.Sprintf("URL: %v", u))

	responseStr, err := readResponseBody(resp.Body)
	if err != nil {
		log.Fatal("Unable to read response body.")
	}

	return GetResultsFromResponse(responseStr)
}

func Intersection(allSubsystemNames []string, fields []string) []string {
	result := make([]string, 0)
	for _, name := range allSubsystemNames {
		for _, inc := range fields {
			if strings.Contains(name, inc) || strings.Contains(inc, name) {
				result = append(result, inc)
			}
		}
	}
	return result
}

func getSearchUrl(hostname string, object_type string, searchCommand map[string][]string, includes []string) string {
	// start organizing commands issued
	values := url.Values{}
	for k, v := range searchCommand {
		values = mergeMapOfStringArrays(values, Separate(v, k))
	}

	for _, f := range includes {
		values := make([]string, 0)
		var fieldsRegex = regexp.MustCompile(`([^[]+)\[.+\]`)
		if fieldsRegex.MatchString(f) {
			// field[subfield]
			fieldName := fieldsRegex.FindAllStringSubmatch(f, -1)
			val := []string{""}
			if strings.Contains(f, "[tags]") {
				val = append(val, "tags")
			}
			values = append(values, fmt.Sprintf("includes[%v]=%v", fieldName[0][1], val))
		} else {
			// field
			values = append(values, fmt.Sprintf("includes[%v]=", f))
		}
	}

	return fmt.Sprintf("%v/%v.xml?%v", hostname, object_type, values.Encode())
}

func mergeMapOfStringArrays(a map[string][]string, b map[string][]string) map[string][]string {
	result := make(map[string][]string)
	for k, v := range a {
		result[k] = v
	}
	for k, v := range b {
		result[k] = append(result[k], v...)
	}
	return result
}

func Separate(hashStrings []string, prefix string) map[string][]string {
	hash := make(map[string][]string)
	// name[key]=value1,map[key]=value2
	for _, val := range hashStrings {
		values := strings.Split(val, ",")
		// name[key]=value
		for _, value := range values {
			pair := strings.Split(value, "=")
			key := ""
			value := ""
			if len(pair) == 2 {
				key = fmt.Sprintf("%v%v", prefix, search_shortcuts.Replace(pair[0]))
				value = pair[1]
			} else if len(pair) == 1 {
				key = "name"
				value = pair[0]
			} else {
				break
			}

			hash[key] = []string{value}
		}
	}
	return hash
}
