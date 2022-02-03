%% This is the application resource file (.app file) for the 'base'
%% application.
{application, controller,
[{description, "Controller application and cluster" },
{vsn, "1.0.0" },
{modules, 
	  [controller,lib_controller,controller_sup,controller_app]},
{registered,[controller]},
{applications, [kernel,stdlib]},
{mod, {controller_app,[]}},
{start_phases, []},
{git_path,"https://github.com/joq62/controller.git"},
{constraints,[]}
]}.
