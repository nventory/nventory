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

type Driver interface {
	//	Returns results search command.

	// Search:
	//	conditions:	flags like --get name=opsdb,id=1234 (map key is "get", value is slice of values comma delimited
	//	includes:	extra fields to include in search to opsdb
	//	fields:	fields to display to user
	Search(object_type string, conditions map[string][]string, includes []string, fields []string) (Result, error)
	// GetAllFields:	Returns all fields
	//	command:	flags like --get name=opsdb,id=1234 (map key is "get", value is slice of values comma delimited
	//	includes:	extra fields to include in search to opsdb
	//	flags:		fields to display to user
	GetAllFields(object_type string, command map[string][]string, includes []string, flags []string) (Result, error)

	// Set:
	//	conditions:	flags like --get name=opsdb,id=1234 (map key is "get", value is slice of values comma delimited
	//	includes:	extra fields to include in search to opsdb
	//	set:		fields to set and its value
	Set(object_type string, conditions map[string][]string, includes []string, set map[string]string, noPrompt bool) (string, error)

	GetAllSubsystemNames(objectType string) ([]string, error)

	SetServer(s string)
	GetServer() string
}
