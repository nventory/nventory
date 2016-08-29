package nvclient

import (
	_ "strings"

	"github.com/spf13/cobra"
)

type SearchCommands struct {
	destFlags      *SearchFlags
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
	newOpsDB      bool
	showtags      bool
	showQueryJson bool
	showVersion   bool
}

func (c *SearchCommands) GetSearchFlags() *SearchFlags {
	return c.destFlags
}

func (f *SearchCommands) Init(dest *SearchFlags, app *cobra.Command) {
	f.destFlags = dest
	dest.Init(app)

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
	app.PersistentFlags().BoolVar(&f.showQueryJson, "showQueryJson", false, "Display json used to query newapi. (--newapi automatically changed to true)")
	//app.PersistentFlags().MarkHidden("showQueryJson")
	app.Flags().BoolVar(&f.allFields, "allfields", false, "Display all fields for selected objects. One or more fields may be specified to be excluded from the query, seperate multiple fields with commas.")
	app.PersistentFlags().BoolVar(&f.showVersion, "version", false, "print the version")

	app.Flags().BoolVar(&f.nodeGroupNodes, "get_nodegroup_nodes", false, "Display all the members of the given node group including virtuals")
	// Aliases: []string{"ngn", "getnodegroupnodes"},
	app.Flags().BoolVar(&f.nodeGroup, "nodegroup", false, "Display all the members of the given node group including virtuals")
	// Aliases: []string{"ng"},
	app.Flags().BoolVar(&f.nodeGroupNodes, "nodegroupexpanded", false, "Display all the members of the given node group including virtuals")
	// Aliases: []string{"nge"},
}
