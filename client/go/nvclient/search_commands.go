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
	_ "strings"

	"errors"
	"strings"
	"io/ioutil"

	"github.com/spf13/cobra"
	"github.com/kardianos/osext"
	"path/filepath"
)


var defaultOpsdbServer = "http://opsdb"

/******************************************************************************
SetCommands:
	Stores all commands and flags related to searching a value.
 *****************************************************************************/

type SearchCommands struct {
	searchFlags    *SearchFlags
	nodeGroupNodes bool
	nodeGroup      bool

	debug        bool
	dryRun       bool
	yes          bool
	register     bool
	noSwitchport bool
	noStorage    bool
	allFields    bool
	username     string
	server       string
	objectType   string

	withAliases   bool
	showtags      bool
	showVersion   bool
	version       string

	driver Driver
}

func (c *SearchCommands) GetSearchFlags() *SearchFlags { return c.searchFlags }
func (c *SearchCommands) IsNodeGroupNodes() bool       { return c.nodeGroupNodes }
func (c *SearchCommands) IsNodeGroup() bool            { return c.nodeGroup }
func (c *SearchCommands) IsDebug() bool                { return c.debug }
func (c *SearchCommands) IsDryRun() bool               { return c.dryRun }
func (c *SearchCommands) IsYes() bool                  { return c.yes }
func (c *SearchCommands) IsRegister() bool             { return c.register }
func (c *SearchCommands) IsNoSwitchport() bool         { return c.noSwitchport }
func (c *SearchCommands) IsNoStorage() bool            { return c.noStorage }
func (c *SearchCommands) IsAllFields() bool            { return c.allFields }
func (c *SearchCommands) GetUsername() string          { return c.username }
func (c *SearchCommands) GetServer() string            { return c.server }
func (c *SearchCommands) IsWithAliases() bool          { return c.withAliases }
func (c *SearchCommands) IsShowTags() bool             { return c.showtags}
func (c *SearchCommands) IsShowVersion() bool          { return c.showVersion}
func (c *SearchCommands) GetVersion() string           { return c.version}

func NewSearchCommand(searchFlags *SearchFlags, driver Driver) *SearchCommands {
	sc := &SearchCommands{searchFlags: searchFlags, driver: driver}
	return sc
}

func (sc *SearchCommands) GetFlagMap() map[string][]string {
	flagMap := make(map[string][]string, 0)
	if sc.GetSearchFlags() != nil {
		flagMap[""] = append(sc.GetSearchFlags().Get, sc.GetSearchFlags().Name...)
		flagMap["exact_"] = sc.GetSearchFlags().Exactget
		flagMap["regex_"] = sc.GetSearchFlags().Regexget
		flagMap["exclude_"] = sc.GetSearchFlags().Exclude
		flagMap["and_"] = sc.GetSearchFlags().And
	}
	return flagMap
}

func (sc *SearchCommands) GetFieldsArray() []string {
	fs := make([]string, 0)
	for _, ss := range sc.searchFlags.Fields {
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

func (c *SearchCommands) GetObjectType() string {
	return c.objectType
}

func (c *SearchCommands) GetDriver() Driver {
	return c.driver
}

func (c *SearchCommands) SetDriver(d Driver) {
	c.driver = d
}

func (f *SearchCommands) InitializeCommand(app *cobra.Command) {
	f.searchFlags.Init(app)

	app.PersistentFlags().BoolVar(&f.debug, "debug", false, "debug output")
	app.PersistentFlags().BoolVar(&f.dryRun, "dry-run", false, "Test run without modifying opsdb")
	app.PersistentFlags().BoolVar(&f.yes, "yes", false, "Don't prompt for set confirmation")

	app.Flags().BoolVar(&f.register, "register", false, "Gather as much information as possible about the local machine and register that information into the nVentory database.")
	app.Flags().BoolVar(&f.noSwitchport, "no-switchport", false, "Skip switch port detection")
	app.Flags().BoolVar(&f.noStorage, "no-storage", false, "Skip storage detection")

	app.PersistentFlags().StringVar(&f.username, "username", "", "Username to use when authenticating to the server.\n\t If not specified defaults to the current user.")
	app.PersistentFlags().StringVar(&f.server, "server", defaultOpsdbServer, "Specify nventory server if different than the default")

	app.PersistentFlags().StringVar(&f.objectType, "objecttype", "nodes", "Object type of search.")
	app.PersistentFlags().BoolVar(&f.withAliases, "withaliases", false, "When searching by name, search aliases as well. (doesn't work with exactget nor regexget)")
	app.PersistentFlags().BoolVar(&f.showtags, "showtags", false, "Lists all tags the node(s) belongs to")
	app.Flags().BoolVar(&f.allFields, "allfields", false, "Display all fields for selected objects. One or more fields may be specified to be excluded from the query, seperate multiple fields with commas.")
	app.PersistentFlags().BoolVar(&f.showVersion, "version", false, "print the version")
	f.version = "0.0.0"

	app.Flags().BoolVar(&f.nodeGroupNodes, "get_nodegroup_nodes", false, "Display all the members of the given node group including virtuals")
	// Aliases: []string{"ngn", "getnodegroupnodes"},
	app.Flags().BoolVar(&f.nodeGroup, "nodegroup", false, "Display all the members of the given node group including virtuals")
	// Aliases: []string{"ng"},
	app.Flags().BoolVar(&f.nodeGroupNodes, "nodegroupexpanded", false, "Display all the members of the given node group including virtuals")
	// Aliases: []string{"nge"},

	// Get version from VERSION file.
	filename, err := osext.ExecutableFolder()
	if err == nil {
		ver, err := getVersionFromVersionFile(filepath.Join(filename, "VERSION"))
		if err == nil {
			f.version = ver
		}
	}
}


func getVersionFromVersionFile(filename string) (string, error) {
	b, err := ioutil.ReadFile(filename)
	if err != nil {
		return "", err
	} else {
		rep := strings.TrimSpace(string(b))
		split := strings.Split(rep, " ")
		if len(split) > 1 {
			return split[1], nil
		} else if len(split[0]) > 0 {
			return split[0], nil
		}
		return "", errors.New("No version found.")
	}
}
