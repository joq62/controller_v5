%% This is the application resource file (.app file) for the 'base'
%% application.
{application, controller,
[{description, "Controller application and cluster" },
{vsn, "0.1.0" },
{modules, 
	  [controller,controller_sup,controller_server]},
{registered,[controller]},
{applications, [kernel,stdlib]},
{mod, {controller,[]}},
{start_phases, []},
{git_path,"https://github.com/joq62/controller.git"},
{env,[{service_catalog,[{dir,"service_catalog"},
	                {filename,"service.catalog"},
			{git_path,"https://github.com/joq62/service_catalog.git"}]}]}
]}.
