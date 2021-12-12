%% This is the application resource file (.app file) for the 'base'
%% application.
{application, logger_infra,
[{description, "Logger_Infra application and cluster" },
{vsn, "0.1.0" },
{modules, 
	  [logger_infra,logger_infra_sup,logger_infra_server]},
{registered,[logger_infra]},
{applications, [kernel,stdlib]},
{mod, {logger_infra_app,[]}},
{start_phases, []},
{git_path,"https://github.com/joq62/logger_infra.git"}
]}.
