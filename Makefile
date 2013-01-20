PIDFILE=./db/data/mongod.lock

# npm modules related commands
node_modules:
	@echo "Making sure deps are installed"
	@npm install .

deletemodules: 
	@echo "Deleting node modules"
	@rm -fr node_modules

publish: lib node_modules
	npm publish .

# DB related commands
startdb:
	@mkdir -p ./db/log
	@mkdir -p ./db/data
	@if [ -f ${PIDFILE} ]; then \
		echo "Already Started DB"; \
	else \
		echo "Starting DB"; \
		mongod --fork --logpath ./db/log/mongodb.log --logappend -dbpath ./db/data > /dev/null; \
	fi

stopdb:
	@if [ -f ${PIDFILE} ]; then \
		echo "Stopping DB"; \
		kill -TERM `cat ${PIDFILE}`; \
		rm -f ${PIDFILE}; \
	else \
		echo "Already stopped."; \
	fi

statusdb:
	@if [ -f ${PIDFILE} ]; then \
		echo "running"; \
	else \
		echo "notrunning"; \
	fi

deletedb: stopdb
	@echo "Deleting db data"
	@rm -fr ./db/data/*

fixture: startdb
	@`npm bin`/coffee load_fixtures.coffee

# App related commands
run: startdb node_modules
	@`npm bin`/coffee server.coffee


# App related commands
run-dev: startdb node_modules
	#coffee server.coffee
	@`npm bin`/supervisor server.coffee


clean: deletedb deletemodules
	rm -fr node_modules
	rm -fr lib

tests: startdb node_modules lib
	@npm test





