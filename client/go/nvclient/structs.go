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
	"strings"
	"github.com/lestrrat/go-libxml2"
	"github.com/lestrrat/go-libxml2/clib"
	"github.com/lestrrat/go-libxml2/types"
	"github.com/atclate/go-logger"
	"os"
)

/*******
 * Result classes for parsing xml and json
  *******/

type Result interface {
	Result()
	ID() string
	SetID(id string)
}

func (r *ResultArray) Result() {}
func (r *ResultMap) Result()   {}
func (r *ResultValue) Result() {}

type ResultArray struct {
	Array []Result
	Name  string
}

func (r *ResultArray) ID() string {
	return r.Name
}
func (r *ResultArray) SetID(id string) {
	r.Name = id
}

type ResultMap struct {
	Map   map[string]Result
	order []string
	Name  string
}

func (r *ResultMap) ID() string {
	return r.Name
}
func (r *ResultMap) SetID(id string) {
	r.Name = id
}
func (r *ResultMap) Add(key string, value Result) {
	if r.Map == nil {
		r.Map = make(map[string]Result, 0)
	}
	r.Map[key] = value

	found := false
	for _, k := range r.GetOrder() {
		if k == key {
			found = true
		}
	}
	if !found {
		r.order = append(r.GetOrder(), key)
	}
}
func (r *ResultMap) Get(key string) Result {
	return r.Map[key]
}

func (r *ResultMap) GetOrder() []string {
	if r.order == nil {
		r.order = make([]string, 0)
	}
	return r.order
}

type ResultValue struct {
	Value string
	Name  string
}

func (r *ResultValue) ID() string {
	return r.Name
}
func (r *ResultValue) SetID(id string) {
	r.Name = id
}

func Compare(r1, r2 Result) bool {
	switch t1 := r1.(type) {
	case *ResultMap:
		switch t2 := r2.(type) {
		case *ResultMap:
			if len(t1.GetOrder()) != len(t2.GetOrder()) {
				return false
			} else {
				if t1.Get("name") != nil {
					if Compare(t1.Get("name"), t2.Get("name")) {
						return true
					} else {
						return false
					}
				}
				for _, k1 := range t1.GetOrder() {
					i1 := t1.Get(k1)
					i2 := t2.Get(k1)
					if i2 == nil {
						return false
					} else if !Compare(i1, i2) {
						return false
					}
				}
				return true
			}
		default:
			return false
		}
	case *ResultArray:
		switch t2 := r2.(type) {
		case *ResultArray:
			if len(t1.Array) != len(t2.Array) {
				return false
			} else {
				for _, i1 := range t1.Array {
					found := false
					for _, i2 := range t2.Array {
						if Compare(i1, i2) {
							found = true
						}
					}
					if !found {
						return false
					}
				}
				return true
			}
		default:
			return false

		}
	case *ResultValue:
		switch t2 := r2.(type) {
		case *ResultValue:
			if t1.Value == t2.Value {
				return true
			}
		default:
			return false
		}
	}
	return false
}

func GetResultsFromResponse(response string) (Result, error) {

	d, err := libxml2.ParseString(response)
	if err != nil {
		logger.Error.Fatal("Unable to parse response as xml:\n%v", response)
		os.Exit(1)
	}

	root, err := d.DocumentElement()
	if err != nil {
		return nil, err
	}

	result, err := getResultFromDom(root)
	return result, err
}

func getResultFromDom(node types.Node) (Result, error) {
	rootChildren, err := node.ChildNodes()

	if err != nil {
		return nil, err
	}

	var isArray bool
	var isNil bool
	e, ok := node.(types.Element)
	if ok {
		attr, err := e.GetAttribute("type")
		isArray = (err == nil) && (attr.Value() == "array")

		attr, err = e.GetAttribute("nil")
		isNil = (err == nil) && (attr.Value() == "true")
	}
	if isNil {
		if isArray {
			return nil, nil
		}
		return &ResultValue{Name: node.NodeName(), Value: ""}, nil
	}

	if isArray {
		// Convert this node to array node
		arr := &ResultArray{Array: make([]Result, 0), Name: node.NodeName()}
		for _, n := range rootChildren {
			switch n.NodeType() {
			case clib.ElementNode:
				arrChild, _ := getResultFromDom(n)
				arr.Array = append(arr.Array, arrChild)
			}
		}
		return arr, nil
	}

	result := &ResultMap{Name: node.NodeName()}
	// Looping through each element in search (e.g. <node>)
	for _, n := range rootChildren {
		switch n.NodeType() {
		case clib.ElementNode:
			// traverse down to parse.
			r, _ := getResultFromDom(n)
			result.Add(n.NodeName(), r)
		case clib.TextNode:
			// ignore
			if len(rootChildren) == 1 {
				return &ResultValue{Value: n.NodeValue()}, nil
			}
		default:
		}
	}
	return result, nil
}

func PrintResultsFilterByFields(r Result, fields []string) string {
	result := ""
	if r == nil {
		return "No matching objects\n"
	}
	if len(fields) == 0 {
		// Just print the names, no fields specified
		switch t := r.(type) {
		case *ResultArray:
			if len(t.Array) == 0 {
				return "No matching objects\n"
			}
			for _, elm := range t.Array {
				switch ct := elm.(type) {
				case *ResultMap:
					dt, ok := ct.Get("name").(*ResultValue)
					if ok {
						result += dt.Value + "\n"
					} else {
						result += ct.Name + "\n"
					}
				}
			}
		case *ResultMap:
			result += t.Name + "\n"
		}
	} else {
		// Fields specified, print name, plus fields specified.
		// Just print the names, no fields specified
		switch t := r.(type) {
		case *ResultArray:
			if len(t.Array) == 0 {
				return "No matching objects\n"
			}
			for _, elm := range t.Array {
				switch ct := elm.(type) {
				case *ResultMap:
					dt, ok := ct.Get("name").(*ResultValue)
					if ok {
						result += dt.Value + ":\n"
					}
					result += PrintResultsFilterByFieldsRecursive(ct, "", fields) + "\n"
				}
			}
		case *ResultMap:
			dt, ok := t.Get("name").(*ResultValue)
			if ok {
				result += dt.Value + "\n"
			}
		}
	}
	return result
}

func PrintResultsFilterByFieldsRecursive(r Result, parent string, fields []string) string {
	result := ""
	// Just print the names, no fields specified
	switch t := r.(type) {
	case *ResultArray:
		if shouldPrint(parent, fields) {
			fields = append(fields, combineName(parent, "name"))
		}
		for _, elm := range t.Array {
			switch elm.(type) {
			case *ResultArray:
				result += PrintResultsFilterByFieldsRecursive(elm, parent, fields)
			case *ResultMap:
				result += PrintResultsFilterByFieldsRecursive(elm, parent, fields)
			default:
				result += PrintResultsFilterByFieldsRecursive(elm, parent, fields)
			}
		}
	case *ResultMap:
		for _, k := range t.GetOrder() {
			v := t.Get(k)
			switch ct := v.(type) {
			case *ResultValue:
				name := combineName(parent, k)
				if shouldPrint(name, fields) || shouldPrint(k, fields) {
					result += name + ": " + PrintResultsFilterByFieldsRecursive(ct, parent, fields) + "\n"
				}
			default:
				name := combineName(parent, k)
				result += PrintResultsFilterByFieldsRecursive(ct, name, fields)
			}
		}
	case *ResultValue:
		result += t.Value
	}
	return result
}

func combineName(parent, name string) string {
	if len(parent) == 0 {
		return name
	} else {
		return parent + "[" + name + "]"
	}
}

func shouldPrint(name string, fields []string) bool {
	if len(fields) == 0 {
		return true
	} else {
		for _, f := range fields {
			if !strings.Contains(name, "[") && strings.Contains(name, f) {
				return true
			} else if name == f {
				return true
			} else if f == "*" {
				return true
			}
		}
	}
	return false
}

func DebugPrintResults(r Result, parent string) string {
	result := "(" + r.ID() + ")"
	switch r := r.(type) {
	case *ResultMap:
		result = "Map: " + result
		if len(r.GetOrder()) == 0 {
		} else {
			for _, k := range r.GetOrder() {
				v := r.Get(k)
				if v == nil {
					result += combineName(parent, k) + ":\n"
				} else {
					result += DebugPrintResults(v, combineName(parent, k))
				}
			}
		}
	case *ResultArray:
		result = "Array: " + result
		for _, v := range r.Array {
			result += DebugPrintResults(v, parent)
		}
	case *ResultValue:
		result = "Value: " + result
		result += parent + ": " + r.Value + "\n"
	}
	return result
}

func PrintResults(r Result) string {
	result := ""
	switch r := r.(type) {
	case *ResultMap:
		//result += r.Name
		if len(r.GetOrder()) == 0 {
			result += "\n"
		} else {
			result += ":\n"
			for _, k := range r.GetOrder() {
				v := r.Get(k)
				result += k + ": " + PrintResultsRecursive(v, k) + "\n"
			}
		}
	case *ResultArray:
		for _, v := range r.Array {
			m, ok := v.(*ResultMap)
			if ok {
				name := m.Get("name")
				n, ok := name.(*ResultValue)
				if ok {
					result += n.Value + ":\n"
				}
			}
			result += PrintResultsRecursive(v, "") + "\n"
		}
	case *ResultValue:
		result += r.Value
	}
	return result
}
func PrintResultsRecursive(r Result, parent string) string {
	result := ""
	switch r := r.(type) {
	case *ResultMap:
		//result += r.Name
		if len(r.GetOrder()) == 0 {
		} else {
			for _, k := range r.GetOrder() {
				v := r.Get(k)
				if v == nil {
					result += combineName(parent, k) + ":\n"
				} else {
					result += PrintResultsRecursive(v, combineName(parent, k))
				}
			}
		}
	case *ResultArray:
		for _, v := range r.Array {
			result += PrintResultsRecursive(v, parent)
		}
	case *ResultValue:
		result += parent + ": " + r.Value + "\n"
	}
	return result
}
