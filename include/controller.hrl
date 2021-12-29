-ifdef(unit_test).
-define(ControllerNodes,"test_configurations/controller.nodes").
-define(DeploymentSpec,"test_configurations/deployment.spec").
-define(HostConfiguration,"test_configurations/host_configuration").
-define(Deployments,"test_configurations/deployments").
-define(ServiceCatalog,"test_configurations/service_catalog/service.catalog").
-define(PodSpecs,"test_configurations/pods").
-define(DbaseServices,"test_configurations/dbase.spec").
-else.
-define(ControllerNodes,"configurations/controller.nodes").
-define(DeploymentSpec,"configurations/deployment.spec").
-define(HostConfiguration,"configurations/host_configuration").
-define(Deployments,"configurations/deployments").
-define(ServiceCatalog,"configurations/service_catalog/service.catalog").
-define(PodSpecs,"configurations/pods").
-define(DbaseServices,"configurations/dbase.spec").
-endif.



-define(ScheduleInterval,1*60*1000).
-define(Config,{"configurations","https://github.com/joq62/configurations.git"}).
-define(TestConfig,{"test_configurations","https://github.com/joq62/test_configurations.git"}).
