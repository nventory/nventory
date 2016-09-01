package nvclient

import (
	"fmt"
	"io/ioutil"
	"os"

	"errors"
	"path/filepath"
	"strings"

	logger "github.com/atclate/go-logger"
	"github.com/kardianos/osext"
	"github.com/spf13/cobra"
)

var (
	dst           SearchFlags
	setValueFlags SetValueFlags

	searchCommand      SearchCommands
	setCommand         SetCommands
	defaultOpsdbServer = "http://opsdb"
)

func SetupCli(app *cobra.Command, driver Driver) {

	searchCommand.Init(&dst, app)
	setCommand.Init(&dst, &setValueFlags, &searchCommand, app)

	// Get version from VERSION file.
	filename, err := osext.ExecutableFolder()
	if err == nil {
		ver, err := getVersionFromVersionFile(filepath.Join(filename, "VERSION"))
		if err == nil {
			searchCommand.version = ver
		}
	}

	app.Run = func(cmd *cobra.Command, args []string) { println("Running dummy command. Please overwrite.") }

	app.PreRun = func(cmd *cobra.Command, args []string) {
		if searchCommand.debug {
			logger.InitLogger(ioutil.Discard, os.Stdout, os.Stdout, os.Stderr, os.Stdout)
			logger.Debug.Println("Debug logging turned on!")
		} else {
			logger.InitLogger(ioutil.Discard, os.Stdout, os.Stdout, os.Stderr, ioutil.Discard)
		}

		driver.SetServer(searchCommand.server)
		logger.Debug.Printf("Using %v as server (%v)\n", driver.GetServer(), searchCommand.server)

		app.Run = func(cmd *cobra.Command, args []string) {
			if searchCommand.showVersion {
				fmt.Printf("%v version %v\n", filepath.Base(os.Args[0]), searchCommand.version)
				os.Exit(0)
			}

			var err = AssignIfStringSliceFlagNotExists(setCommand.destFlags, 0)
			if err != nil {
				fmt.Print(app.UsageString())
				os.Exit(1)
			}

			if setCommand.setValueFlags.value != nil && len(setCommand.setValueFlags.value) > 0 {
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
				if searchCommand.allFields {
					val, err := GetAllFieldsByCommand(driver, &searchCommand)
					if err == nil {
						fmt.Print(PrintResults(val))
					} else {
						logger.Error.Println("Error:", err)
						os.Exit(1)
					}
					return
				}

				val, err := SearchByCommand(driver, &searchCommand)
				if err == nil {
					fmt.Print(PrintResultsFilterByFields(val, searchCommand.GetFieldsArray()))
				} else {
					logger.Error.Println("Error:", err)
				}
			}
		}
	}
}

func SearchByCommand(f Driver, sc SearchableCommand) (Result, error) {
	flagMap := sc.GetFlagMap()

	fs := sc.GetFieldsArray()

	i, _ := f.GetAllSubsystemNames(sc.GetObjectType())
	return f.Search(sc.GetObjectType(), flagMap, intersection(i, fs), fs)
}

func SetByCommand(f Driver, sc *SetCommands) (string, error) {
	flagMap := sc.GetFlagMap()

	fs := getSetFromFlags(sc)

	i, _ := f.GetAllSubsystemNames(sc.objectType)
	return f.Set(sc.objectType, flagMap, i, fs)
}

// Get all the fields of a node
func GetAllFieldsByCommand(f Driver, sc *SearchCommands) (Result, error) {
	flagMap := sc.GetFlagMap()

	fs := sc.GetFieldsArray()

	includes, _ := f.GetAllSubsystemNames(sc.objectType)

	return f.GetAllFields(sc.objectType, flagMap, includes, fs)
}

type SearchableCommand interface {
	GetSearchFlags() *SearchFlags
	GetFlagMap() map[string][]string
	GetFieldsArray() []string
	GetObjectType() string
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
