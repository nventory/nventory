package nvclient

import (
	"bufio"
	"fmt"
	"log"

	"github.com/lestrrat/go-libxml2"
	"github.com/lestrrat/go-libxml2/clib"
	"github.com/lestrrat/go-libxml2/types"
)

func PromptUserConfirmation(message string, f *bufio.Reader) bool {
	fmt.Print(message)
	response, err := readLine(f)
	if err != nil {
		return false
	}
	r := []rune(response)
	if len(r) > 0 {
		if r[0] == 'y' || r[0] == 'Y' {
			return true
		} else {
			return false
		}
	}
	return PromptUserConfirmation(message, f)
}

func readLine(f *bufio.Reader) (string, error) {
	line, prefix, err := f.ReadLine()
	for prefix && err == nil {
		var l []byte
		l, prefix, err = f.ReadLine()
		line = append(line, l...)
	}
	return string(line), err
}

func GetResultFromDom(node types.Node) (Result, error) {
	rootChildren, err := node.ChildNodes()

	if err != nil {
		return nil, err
	}

	var isArray bool
	var isNil bool
	e, ok := node.(types.Element)
	if ok {
		attr, err := e.GetAttribute("type")
		if err == nil && attr.Value() == "array" {
			isArray = true
		}
		attr, err = e.GetAttribute("nil")
		if err == nil && attr.Value() == "true" {
			isNil = true
		}
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
				arrChild, _ := GetResultFromDom(n)
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
			r, _ := GetResultFromDom(n)
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

func GetResultsFromResponse(response string) (Result, error) {

	d, err := libxml2.ParseString(response)
	if err != nil {
		log.Fatal("Unable to parse response as xml:\n%v", response)
	}

	root, err := d.DocumentElement()
	if err != nil {
		return nil, err
	}

	result, err := GetResultFromDom(root)
	return result, err
}
