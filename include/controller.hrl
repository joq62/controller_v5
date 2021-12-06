-ifdef(unit_test).
-define(ControllerNodes,"test_configurations/controller.nodes").
-define(HostConfiguration,"test_configurations/host_configuration").
-define(Deployments,"test_configurations/deployments").
-define(ServiceCatalog,"test_configurations/service_catalog/service.catalog").
-define(PodSpecs,"test_configurations/pods").
-else.
-define(ControllerNodes,"configurations/controller.nodes").
-define(HostConfiguration,"configurations/host_configuration").
-define(Deployments,"configurations/deployments").
-define(ServiceCatalog,"configurations/service_catalog/service.catalog").
-define(PodSpecs,"configurations/pods").
-endif.


-define(DbaseServices,[{db_host,?HostConfiguration},
		       {db_service_catalog,?ServiceCatalog},
		       {db_deployment,?Deployments},
		       {db_pods,?PodSpecs}]).


-define(ScheduleInterval,1*30*1000).
-define(Config,{"configurations","https://github.com/joq62/configurations.git"}).
-define(TestConfig,{"test_configurations","https://github.com/joq62/test_configurations.git"}).
