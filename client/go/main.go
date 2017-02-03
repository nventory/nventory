// Copyright © 2016 NAME HERE <EMAIL ADDRESS>
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
	"bufio"
	"os"

	"github.com/atclate/nventory/client/go/cmd"
	"github.com/atclate/nventory/client/go/nvclient"
	"github.com/spf13/viper"
	"github.com/fsnotify/fsnotify"
	"fmt"
	jww "github.com/spf13/jwalterweatherman"
)

var (
	searchCommand      *nvclient.SearchCommands
	setCommand         *nvclient.SetCommands

	autoreg_password = "REPLACE_ME_WITH_AUTOREG_PASSWORD"
	defaultOpsdbServer = "http://nventory"

	driver nvclient.Driver
)

func init() {
	//jww.SetStdoutThreshold(jww.LevelTrace)

	driver = nvclient.NewNventoryDriver(bufio.NewReader(os.Stdin))
	searchCommand = nvclient.NewSearchCommand(&nvclient.SearchFlags{}, driver)

	initConfigFile()

	searchCommand.InitializeCommand(cmd.RootCmd)
	setCommand = nvclient.NewSetCommand(cmd.RootCmd, searchCommand, driver);
	SetupCli(cmd.RootCmd, driver)

}

func initConfigFile() {
	viper.SetDefault("autoreg_password", autoreg_password)
	viper.SetDefault("server", defaultOpsdbServer)

	viper.SetConfigName("nventory") // name of config file (without extension)
	viper.SetConfigType("yml")
	viper.SupportedExts = append(viper.SupportedExts, "conf")
	viper.AddConfigPath("/etc/")   // path to look for the config file in
	viper.AddConfigPath("$HOME/")  // call multiple times to add many search paths
	viper.AddConfigPath(".")               // optionally look for config in the working directory
	err := viper.ReadInConfig() // Find and read the config file
	if err != nil { // Handle errors reading the config file
		jww.DEBUG.Println(fmt.Sprintf("error reading config file: %v", err))
	}

	viper.WatchConfig()
	viper.OnConfigChange(func(e fsnotify.Event) {
		println("Config file changed:", e.Name)
	})

	// use server from config file.
	driver.SetServer(viper.GetString("server"))
	searchCommand.SetDefaultServer(viper.GetString("server"))
}

func main() {
	cmd.RootCmd.Execute()
}
