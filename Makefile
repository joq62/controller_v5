all:
#	service
	rm -rf ebin/* src/*.beam *.beam test_src/*.beam test_ebin;
	rm -rf *.applications ~/*.applications *configurations;
	rm -rf  *~ */*~  erl_cra*;
#	common
#	cp ../common/src/*.app ebin;
	erlc -I include -o ebin ../../common/src/*.erl;
#	bully
	cp ../bully/src/*.app ebin;
	erlc -I include -o ebin ../bully/src/*.erl;
#	sd
	cp ../sd/src/*.app ebin;
	erlc -I include -o ebin ../sd/src/*.erl;
#	dbase_infra
	cp ../dbase_infra/src/*.app ebin;
	erlc -I include -o ebin ../dbase_infra/src/*.erl;
#	host
	cp ../host/src/*.app ebin;
	erlc -I include -o ebin ../host/src/*.erl;
#	app
	cp src/*.app ebin;
	erlc -I include -o ebin src/*.erl;
	echo Done
unit_test:
	rm -rf ebin/* src/*.beam *.beam test_src/*.beam test_ebin;
	rm -rf *.applications ~/*.applications;
	rm -rf  *~ */*~  erl_cra*;
	mkdir test_ebin;
#	common
#	cp ../common/src/*.app ebin;
	erlc -D unit_test -I include -o ebin ../../common/src/*.erl;
#	bully
	cp ../bully/src/*.app ebin;
	erlc -D unit_test -I include -o ebin ../bully/src/*.erl;
#	sd
	cp ../sd/src/*.app ebin;
	erlc -D unit_test -I include -o ebin ../sd/src/*.erl;
#	dbase_infra
	cp ../dbase_infra/src/*.app ebin;
	erlc -D unit_test -I include -o ebin ../dbase_infra/src/*.erl;
#	host
	cp ../host/src/*.app ebin;
	erlc -D unit_test -I include -o ebin ../host/src/*.erl;
#	app
	cp src/*.app ebin;
	erlc -I include -D unit_test -o ebin src/*.erl; 
#	test application
	cp test_src/*.app test_ebin;
	erlc -D unit_test -I include -o test_ebin test_src/*.erl;
	erl -pa ebin -pa test_ebin\
	    -setcookie cookie\
	    -sname test\
	    -unit_test monitor_node test\
	    -unit_test cluster_id test\
	    -unit_test cookie cookie\
	    -run unit_test start_test test_src/test.config
