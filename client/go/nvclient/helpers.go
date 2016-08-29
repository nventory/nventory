package nvclient

import (
	"bufio"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"net/http"
	"strings"

	"flag"

	"github.com/howeyc/gopass"
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

func AssignIfStringSliceFlagNotExists(flags *SearchFlags, index int) error {
	if flags.IsEmpty() {
		if len(flag.Arg(index)) > 0 {
			flags.name = append(flags.name, flag.Arg(index))
			return nil
		}
		return errors.New(fmt.Sprintf("Argument not found. Please specify a flag or argument number %v\n", index))

	}
	return nil
}

func PromptUserConfirmaion(message string, f *bufio.Reader) bool {
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
	return PromptUserConfirmaion(message, f)
}

func PromptUserLogin(user string, f *bufio.Reader) (u, p string, err error) {
	if user != "" && user == autoreg {
		print("Login: ")
		response, err := readLine(f)
		if err != nil {
			return "", "", errors.New("Failed reading user input.")
		}
		user = response
	}
	// User typed something in for username
	print("Password: ")
	passwdarr, err := gopass.GetPasswd()
	return user, string(passwdarr), err
}

func serializeJSON(a interface{}) (string, error) {
	b, err := json.Marshal(a)
	if err != nil {
		return "", err
	}
	return string(b), nil
}

func deserializeJSONCookie(s string, m *http.Cookie) error {
	err := json.Unmarshal([]byte(s), m)
	return err
}

func readResponseBody(body io.ReadCloser) (string, error) {
	//defer body.Close()
	contents, err := ioutil.ReadAll(body)
	if err != nil {
		return "", err
	}
	return string(contents), nil
}
func getFieldsFromFlags(sc *SearchCommands) []string {
	fs := make([]string, 0)
	for _, ss := range sc.destFlags.fields {
		fs = append(fs, strings.Split(ss, ",")...)
	}
	if sc.showtags == true {
		if sc.objectType == "nodes" {
			fs = append(fs, "node_groups[name]")
			fs = append(fs, "node_groups[tags][name]")
		} else if sc.objectType == "node_groups" {
			fs = append(fs, "tags[name]")
		} else {
			log.Fatalf("--showtags can only be used when searching objecttype nodes or node_groups. object type = %v\n", sc.objectType)
		}
	}
	return fs
}

type ExprResult struct {
	Value string
}

func isRedirectResponse(resp *http.Response) bool {
	if resp == nil {
		return false
	}
	return isRedirect(resp.StatusCode)
}

func isRedirect(returnCode int) bool {
	if returnCode >= 300 && returnCode < 400 {
		return true
	}
	return false
}

func handleResponseError(err error) error {
	// return true - error happened
	// false - no error
	if strings.Contains(fmt.Sprintf("%v", err), "No redirect.") {
		// If we're redirected only, return nil
		return nil
	}
	return err
}

func getHeaderLocation(resp *http.Response) string {
	if resp != nil && resp.Header["Location"] != nil {
		return resp.Header["Location"][0]
	}
	return ""
}
