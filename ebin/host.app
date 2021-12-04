%% This is the application resource file (.app file) for the 'base'
%% application.
{application, host,
[{description, "Host application and cluster" },
{vsn, "0.1.0" },
{modules, 
	  [host,host_sup,host_app,host_server]},
{registered,[host]},
{applications, [kernel,stdlib]},
{mod, {host_app,[]}},
{start_phases, []},
{git_path,"https://github.com/joq62/host.git"}
]}.
