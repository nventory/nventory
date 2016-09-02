package nvclient

import (
	"fmt"
	"strings"

	"github.com/spf13/cobra"
)

/******************************************************************************
SetCommands:
	Stores all commands and flags related to searching and setting a value.
 *****************************************************************************/

type SetCommands struct {
	setValueFlags *SetValueFlags // cli flag (--set) for setting a value
	searchCommand *SearchCommands // misc cli flags related to searching

	driver Driver
}

func NewSetCommand(cmd *cobra.Command, sc *SearchCommands, driver Driver) *SetCommands {
	set := &SetCommands{
		setValueFlags: &SetValueFlags{}, // cli flag (--set) for setting a value
		searchCommand: sc, // misc cli flags related to searching
		driver: driver,
	}
	set.Init(cmd)
	return set
}

func (c *SetCommands) GetSearchFlags() *SearchFlags {
	return c.searchCommand.GetSearchFlags()
}

func (c *SetCommands) GetSetValueFlags() *SetValueFlags {
	return c.setValueFlags
}

func (c *SetCommands) GetSearchCommands() *SearchCommands {
	return c.searchCommand
}

func (c *SetCommands) GetObjectType() string {
	return c.searchCommand.GetObjectType()
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
	for _, ss := range sc.GetSearchFlags().Fields {
		fs = append(fs, strings.Split(ss, ",")...)
	}
	return fs
}

func (sc *SetCommands) SetByCommand(f Driver) (string, error) {
	flagMap := sc.GetFlagMap()

	fs := sc.GetSetFromFlags()

	i, _ := f.GetAllSubsystemNames(sc.GetObjectType())
	return f.Set(sc.GetObjectType(), flagMap, i, fs)
}

func (f *SetCommands) Init(app *cobra.Command) {
	app.Flags().StringSliceVar(&f.setValueFlags.value, "set", nil, "Update fields in objects selected via get/exactget, may be specified multiple times to update multiple fields.")
}





/******************************************************************************
SetValueFlags:
	Stores '=' separated key value pairs the user specified.
Example:
	value: []string{"name=new.name", "physical_memory=1024"}
 *****************************************************************************/
type SetValueFlags struct {
	value []string
}

func (f *SetValueFlags) ToString() string {
	return fmt.Sprintf("set=(%v)", f.value)
}

func (f *SetValueFlags) GetValues() []string {
	return f.value
}
