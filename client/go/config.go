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

package main

import (
	"fmt"
	"io/ioutil"
	"os"

	"path/filepath"

	logger "github.com/atclate/go-logger"
	"github.com/spf13/cobra"
	"github.com/atclate/nventory/client/go/nvclient"
)

/******************************************************************************
SetupCli:
	Initializes cobra command (app) with
 *****************************************************************************/
func SetupCli(app *cobra.Command, driver nvclient.Driver) {

	app.Run = func(cmd *cobra.Command, args []string) { println("Running dummy command. Please overwrite.") }

	app.PreRun = func(cmd *cobra.Command, args []string) {
		if searchCommand.IsDebug() {
			logger.InitLogger(ioutil.Discard, os.Stdout, os.Stdout, os.Stderr, os.Stdout)
			logger.Debug.Println("Debug logging turned on!")
		} else {
			logger.InitLogger(ioutil.Discard, os.Stdout, os.Stdout, os.Stderr, ioutil.Discard)
		}

		driver.SetServer(searchCommand.GetServer())
		logger.Debug.Printf("Using %v as server (%v)\n", driver.GetServer(), searchCommand.GetServer())

		app.Run = func(cmd *cobra.Command, args []string) {
			if searchCommand.IsShowVersion() {
				fmt.Printf("%v version %v\n", filepath.Base(os.Args[0]), searchCommand.GetVersion())
				os.Exit(0)
			}

			var err = nvclient.AssignIfStringSliceFlagNotExists(searchCommand.GetSearchFlags(), 0)
			if err != nil {
				fmt.Print(app.UsageString())
				os.Exit(1)
			}

			if setCommand.GetSetValueFlags() != nil && len(setCommand.GetSetValueFlags().GetValues()) > 0 {
				logger.Debug.Printf("Set option is specified. Changing action to set instead of search.\n")
				res, err := setCommand.SetByCommand(driver)
				if err != nil {
					fmt.Println(err)
					os.Exit(1)
				} else {
					fmt.Print(res)
				}
			} else {
				// Check if --allfields is called.
				if searchCommand.IsAllFields() {
					val, err := nvclient.GetAllFieldsByCommand(driver, searchCommand)
					if err == nil {
						fmt.Print(nvclient.PrintResults(val))
					} else {
						logger.Error.Println("Error:", err)
						os.Exit(1)
					}
					return
				}

				val, err := nvclient.SearchByCommand(driver, searchCommand)
				if err == nil {
					fmt.Print(nvclient.PrintResultsFilterByFields(val, searchCommand.GetFieldsArray()))
				} else {
					logger.Error.Println("Error:", err)
				}
			}
		}
	}
}
