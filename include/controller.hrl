-ifdef(unit_test).
-define(ControllerNodes,"test_controller.nodes").
-define(HostConfiguration,"test_configurations/host_configuration").
-define(Deployments,"test_configurations/deployments").
-define(ServiceCatalog,"test_configurations/service_catalog/service.catalog").
-else.
-define(ControllerNodes,"controller.nodes").
-define(HostConfiguration,"configurations/host_configuration").
-define(Deployments,"configurations/deployments").
-define(ServiceCatalog,"configurations/service_catalog/service.catalog").
-endif.

-define(ScheduleInterval,1*30*1000).
