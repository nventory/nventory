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
	"log"
	"regexp"

	"errors"

	"github.com/lestrrat/go-libxml2"
	_ "github.com/lestrrat/go-libxml2/xpath"
)

type SearchShortcut struct {
	Name         string
	OriginalName string
}

type SearchShortcuts map[string]string

func (ss SearchShortcuts) Replace(name string) string {
	if ss[name] != "" {
		return ss[name]
	}
	return name
}

var (
	search_shortcuts SearchShortcuts
)

func init() {
	ResetShortcuts()
}

func ResetShortcuts() {
	search_shortcuts = map[string]string{
		"hw":          "hardware_profile[name]",
		"hwmanuf":     "hardware_profile[manufacturer]",
		"hwmodel":     "hardware_profile[model]",
		"ip":          "ip_addresses[address]",
		"ips":         "ip_addresses[address]",
		"mac":         "network_interfaces[hardware_address]",
		"macs":        "network_interfaces[hardware_address]",
		"nic":         "network_interfaces[name]",
		"nics":        "network_interfaces[name]",
		"switch_name": "network_interfaces[switch_port][producer][name]",
		"node_group":  "node_group[name]",
		"node_groups": "node_groups[name]",
		"os":          "operating_system[name]",
		"osvendor":    "operating_system[vendor]",
		"osvariant":   "operating_system[variant]",
		"osver":       "operating_system[version_number]",
		"osversion":   "operating_system[version_number]",
		"osarch":      "operating_system[architecture]",
		"serial":      "serial_number",
		"status":      "status[name]",
	}
}

// Reads response to allfields.xml and saves all shortcuts denoted by ()
// Returns all field names
func (ss SearchShortcuts) SaveFieldShortcuts(response, xpath, nodeName string, f ...string) ([]string, error) {
	ResetShortcuts()

	d, err := libxml2.ParseString(response)
	if err != nil {
		log.Fatal("Unable to parse response as xml:\n%v", response)
	}
	xPathResult, err := d.Find(xpath)

	var result = make([]string, 0)
	var found = false
	var iter = xPathResult.NodeIter()
	for iter.Next() {
		found = true
		childNodes, _ := iter.Node().ChildNodes()
		for _, node := range childNodes {
			if node.NodeName() == nodeName {
				if m := regexp.MustCompile(`^(.*) \((.*)\)`).FindAllStringSubmatch(node.NodeValue(), -1); len(m) > 0 {
					// shortcut found
					search_shortcuts[m[0][2]] = m[0][1]
					result = append(result, m[0][1])
				} else {
					result = append(result, node.NodeValue())
				}
			}
		}
	}
	if !found {
		return result, errors.New("No matching objects\n")
	}
	return result, nil
}
