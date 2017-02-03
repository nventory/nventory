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
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"strings"

	"flag"

	"github.com/howeyc/gopass"
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

func AssignIfStringSliceFlagNotExists(flags *SearchFlags, index int) error {
	if flags.IsEmpty() {
		if len(flag.Arg(index)) > 0 {
			flags.Name = append(flags.Name, flag.Arg(index))
			return nil
		}
		return errors.New(fmt.Sprintf("Argument not found. Please specify a flag or argument number %v\n", index))

	}
	return nil
}

func PromptUserLogin(user string, f *bufio.Reader) (u, p string, err error) {
	if user != "" {
		print("Login: ")
		if user == autoreg {
			response, err := readLine(f)
			if err != nil {
				return "", "", errors.New("Failed reading user input.")
			}
			user = response
		} else {
			println(user)
		}
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


func SearchByCommand(f Driver, sc SearchableCommand) (Result, error) {
	flagMap := sc.GetFlagMap()

	fs := sc.GetFieldsArray()

	i, _ := f.GetAllSubsystemNames(sc.GetObjectType())
	return f.Search(sc.GetObjectType(), flagMap, Intersection(i, fs), fs)
}

func SetByCommand(f Driver, sc *SetCommands) (string, error) {
	flagMap := sc.GetFlagMap()

	fs := sc.GetSetFromFlags()

	i, _ := f.GetAllSubsystemNames(sc.GetObjectType())
	return f.Set(sc.GetObjectType(), flagMap, i, fs, sc.GetSearchCommands().IsYes())
}

// Get all the fields of a node
func GetAllFieldsByCommand(f Driver, sc *SearchCommands) (Result, error) {
	flagMap := sc.GetFlagMap()

	fs := sc.GetFieldsArray()

	includes, _ := f.GetAllSubsystemNames(sc.GetObjectType())

	return f.GetAllFields(sc.GetObjectType(), flagMap, includes, fs)
}

type SearchableCommand interface {
	GetSearchFlags() *SearchFlags
	GetFlagMap() map[string][]string
	GetFieldsArray() []string
	GetObjectType() string
}
