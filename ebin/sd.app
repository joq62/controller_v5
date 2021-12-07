%% This is the application resource file (.app file) for the 'base'
%% application.
{application, sd,
[{description, "Sd application and cluster" },
{vsn, "1.0.0" },
{modules, 
	  [sd,sd_sup,sd_app,sd_server]},
{registered,[sd]},
{applications, [kernel,stdlib]},
{mod, {sd_app,[]}},
{start_phases, []},
{git_path,"https://github.com/joq62/sd.git"}]}.
