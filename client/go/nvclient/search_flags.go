package nvclient

import (
	"fmt"
	"strings"

	"github.com/spf13/cobra"
)

type SearchFlags struct {
	name     []string
	get      []string
	exactget []string
	regexget []string
	exclude  []string
	and      []string
	fields   []string
}

func (f *SearchFlags) Init(app *cobra.Command) {
	app.Flags().StringSliceVar(&f.get, "get", nil, "Specify partial name of target item")
	app.Flags().StringSliceVar(&f.exactget, "exactget", nil, "Specify exact name of target item")
	app.Flags().StringSliceVar(&f.regexget, "regexget", nil, "Specify reglar expression to search for target item")
	app.Flags().StringSliceVar(&f.exclude, "exclude", nil, "Excludes substring from potential matches from get/exactget/regexget.\n\tMultiple values for an individual field can be specified seperated by commas.")
	app.Flags().StringSliceVar(&f.and, "and", nil, "Add another condition for matching")
	app.Flags().StringSliceVar(&f.fields, "fields", nil, "Display the specified fields for selected objects. One or more fields may be specified, either by specifying this option multiple times or by seperating the field names with commas.")
	app.Flags().StringSliceVar(&f.name, "name", nil, "Specify partial name of target item")
}

func (f *SearchFlags) ToString() string {
	if f == nil {
		return ""
	} else if len(f.name) > 0 {
		return fmt.Sprintf("name=%v(%v)", strings.Join(f.name, ","), len(f.name))
	} else if len(f.get) > 0 {
		return fmt.Sprintf("get=%v(%v)", strings.Join(f.get, ","), len(f.get))
	} else if len(f.exactget) > 0 {
		return fmt.Sprintf("exactget=%v(%v)", strings.Join(f.exactget, ","), len(f.exactget))
	} else if len(f.regexget) > 0 {
		return fmt.Sprintf("regexget=%v(%v)", strings.Join(f.regexget, ","), len(f.regexget))
	}
	return ""
}

func (f *SearchFlags) IsEmpty() bool {
	if len(f.name) > 0 || len(f.get) > 0 || len(f.exactget) > 0 || len(f.regexget) > 0 || len(f.exclude) > 0 || len(f.and) > 0 {
		return false
	}
	return true
}
