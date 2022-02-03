all:
#	service
	rm -rf ebin/* src/*.beam *.beam test_src/*.beam test_ebin;
	rm -rf dbase myadd mydivi sd leader loader service;
	rm -rf host;
	rm -rf appl_specs host_specs service_specs;
	rm -rf  *~ */*~  erl_cra*;
#	application
	cp src/*.app ebin;
	erlc -I ../infra/log_server/include -I include -o ebin src/*.erl;
	echo Done
unit_test:
	rm -rf ebin/* src/*.beam *.beam test_src/*.beam test_ebin;
	rm -rf host dbase myadd mydivi sd leader loader service;
	rm -rf  *~ */*~  erl_cra*;
	rm -rf appl_specs host_specs service_specs;
	mkdir test_ebin;
#	common
#	cp ../common/src/*.app ebin;
#	erlc -D unit_test -I ../infra/log_server/include -o test_ebin ../common/src/*.erl;
#	sd
	cp ../sd/src/*.app ebin;
	erlc -D unit_test -I ../infra/log_server/include -o ebin ../sd/src/*.erl;
#	loader
	cp ../loader/src/*.app ebin;
	erlc -D unit_test -I ../infra/log_server/include -I ../loader/include -o ebin ../loader/src/*.erl;
#	host
	cp ../host/src/*.app ebin;
	erlc -D unit_test -I ../infra/log_server/include -I ../loader/include -o ebin ../host/src/*.erl;
#	Target application
	cp src/*.app ebin;
	erlc -D unit_test -I ../infra/log_server/include -I include -o ebin src/*.erl;
#	test application
	cp test_src/*.app test_ebin;
	erlc -D unit_test -I ../infra/log_server/include -I ../loader/include -I include -o test_ebin test_src/*.erl;
	erl -pa ebin -pa test_ebin\
	    -setcookie cookie_test\
	    -sname test\
	    -unit_test monitor_node test\
	    -unit_test cluster_id test\
	    -unit_test cookie cookie_test\
	    -run unit_test start_test test_src/test.config
