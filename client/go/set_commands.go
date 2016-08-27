package main

import (
	"fmt"

	"github.com/spf13/cobra"
)

type SetValueFlags struct {
	value []string
}

func (f *SetValueFlags) ToString() string {
	return fmt.Sprintf("set=(%v)", f.value)
}

type SetCommands struct {
	destFlags     *SearchFlags
	setValueFlags *SetValueFlags
	searchCommand *SearchCommands
}

func (c *SetCommands) GetSearchFlags() *SearchFlags {
	return c.destFlags
}

func (sc *SetCommands) SetByCommand(f Driver) (string, error) {
	flagMap := getMapFromSearchCommands(sc)

	fs := getSetFromFlags(sc.setValueFlags.value)

	includes := make(map[string][]string, 0)
	i, _ := f.GetAllSubsystemNames(searchCommand.objectType)
	includes["include"] = i
	return f.Set(searchCommand.objectType, flagMap, includes, fs)
}

func (f *SetCommands) Init(dest *SearchFlags, set *SetValueFlags, searchCommand *SearchCommands, app *cobra.Command) {
	f.destFlags = dest
	f.setValueFlags = set
	f.searchCommand = searchCommand

	app.Flags().StringSliceVar(&f.setValueFlags.value, "set", nil, "Update fields in objects selected via get/exactget, may be specified multiple times to update multiple fields.")
}
