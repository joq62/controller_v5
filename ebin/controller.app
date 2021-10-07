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
{env,[{nodes,['controller@c0','controller@c2','controller@joq62-X550CA'
	     ]},
      {dir_applications,"applications"},
      {dir_logs,"logs"},
      {support_applications,[dbase_dist,bully]}]}
]}.
