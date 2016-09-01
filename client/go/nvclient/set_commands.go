package nvclient

import (
	"fmt"
	"strings"

	"github.com/spf13/cobra"
)

type SetValueFlags struct {
	value []string
}

func (f *SetValueFlags) ToString() string {
	return fmt.Sprintf("set=(%v)", f.value)
}

func (f *SetValueFlags) GetValues() []string {
	return f.value
}

type SetCommands struct {
	destFlags     *SearchFlags
	setValueFlags *SetValueFlags
	searchCommand *SearchCommands
	objectType    string
}

func (c *SetCommands) GetSearchFlags() *SearchFlags {
	return c.destFlags
}

func (c *SetCommands) GetSetValueFlags() *SetValueFlags {
	return c.setValueFlags
}

func (c *SetCommands) GetSearchCommands() *SearchCommands {
	return c.searchCommand
}

func (c *SetCommands) GetObjectType() string {
	return c.objectType
}

func (sc *SetCommands) GetFlagMap() map[string][]string {
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

func (sc *SetCommands) GetFieldsArray() []string {
	fs := make([]string, 0)
	for _, ss := range sc.destFlags.Fields {
		fs = append(fs, strings.Split(ss, ",")...)
	}
	return fs
}

func (sc *SetCommands) SetByCommand(f Driver) (string, error) {
	flagMap := sc.GetFlagMap()

	fs := getSetFromFlags(sc)

	i, _ := f.GetAllSubsystemNames(searchCommand.objectType)
	return f.Set(searchCommand.objectType, flagMap, i, fs)
}

func (f *SetCommands) Init(dest *SearchFlags, set *SetValueFlags, searchCommand *SearchCommands, app *cobra.Command) {
	f.destFlags = dest
	f.setValueFlags = set
	f.searchCommand = searchCommand

	app.Flags().StringSliceVar(&f.setValueFlags.value, "set", nil, "Update fields in objects selected via get/exactget, may be specified multiple times to update multiple fields.")
}
