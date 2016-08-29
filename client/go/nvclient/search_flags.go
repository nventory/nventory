package nvclient

import (
	"fmt"
	"strings"

	"github.com/spf13/cobra"
)

type SearchFlags struct {
	Name     []string
	Get      []string
	Exactget []string
	Regexget []string
	Exclude  []string
	And      []string
	Fields   []string
}

func (f *SearchFlags) Init(app *cobra.Command) {
	app.Flags().StringSliceVar(&f.Get, "get", nil, "Specify partial name of target item")
	app.Flags().StringSliceVar(&f.Exactget, "exactget", nil, "Specify exact name of target item")
	app.Flags().StringSliceVar(&f.Regexget, "regexget", nil, "Specify reglar expression to search for target item")
	app.Flags().StringSliceVar(&f.Exclude, "exclude", nil, "Excludes substring from potential matches from get/exactget/regexget.\n\tMultiple values for an individual field can be specified seperated by commas.")
	app.Flags().StringSliceVar(&f.And, "and", nil, "Add another condition for matching")
	app.Flags().StringSliceVar(&f.Fields, "fields", nil, "Display the specified fields for selected objects. One or more fields may be specified, either by specifying this option multiple times or by seperating the field names with commas.")
	app.Flags().StringSliceVar(&f.Name, "name", nil, "Specify partial name of target item")
}

func (f *SearchFlags) ToString() string {
	if f == nil {
		return ""
	} else if len(f.Name) > 0 {
		return fmt.Sprintf("name=%v(%v)", strings.Join(f.Name, ","), len(f.Name))
	} else if len(f.Get) > 0 {
		return fmt.Sprintf("get=%v(%v)", strings.Join(f.Get, ","), len(f.Get))
	} else if len(f.Exactget) > 0 {
		return fmt.Sprintf("exactget=%v(%v)", strings.Join(f.Exactget, ","), len(f.Exactget))
	} else if len(f.Regexget) > 0 {
		return fmt.Sprintf("regexget=%v(%v)", strings.Join(f.Regexget, ","), len(f.Regexget))
	}
	return ""
}

func (f *SearchFlags) IsEmpty() bool {
	if len(f.Name) > 0 || len(f.Get) > 0 || len(f.Exactget) > 0 || len(f.Regexget) > 0 || len(f.Exclude) > 0 || len(f.And) > 0 {
		return false
	}
	return true
}
