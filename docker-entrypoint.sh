#!/bin/sh

cmd=
for i; do
	cmd="$cmd '$i'"
done

dbPath=/data/db

# pre-check a few factors to see if it's even worth bothering with initdb
shouldPerformInitdb=
if [ "$MONGO_INITDB_ROOT_USERNAME" ] && [ "$MONGO_INITDB_ROOT_PASSWORD" ]; then
	# if we have a username/password, let's set "--auth"
	cmd="$cmd --auth"
	shouldPerformInitdb='true'
elif [ "$MONGO_INITDB_ROOT_USERNAME" ] || [ "$MONGO_INITDB_ROOT_PASSWORD" ]; then
	cat >&2 <<-'EOF'

		error: missing 'MONGO_INITDB_ROOT_USERNAME' or 'MONGO_INITDB_ROOT_PASSWORD'
		       both must be specified for a user to be created

	EOF
	exit 1
fi

if [ -z "$shouldPerformInitdb" ]; then
	# if we've got any /docker-entrypoint-initdb.d/* files to parse later, we should initdb
	for f in /docker-entrypoint-initdb.d/*; do
		case "$f" in
			*.sh|*.js) # this should match the set of files we check for below
				shouldPerformInitdb="$f"
				break
				;;
		esac
	done
fi

# check for a few known paths (to determine whether we've already initialized and should thus skip our initdb scripts)
if [ -n "$shouldPerformInitdb" ]; then
	for path in \
		"$dbPath/WiredTiger" \
		"$dbPath/journal" \
		"$dbPath/local.0" \
		"$dbPath/storage.bson" \
	; do
		if [ -e "$path" ]; then
			shouldPerformInitdb=
			break
		fi
	done
fi

# init db
if [ -n "$shouldPerformInitdb" ]; then

	mongod_cmd="mongod"

	if stat "/proc/$$/fd/1" > /dev/null && [ -w "/proc/$$/fd/1" ]; then
		# https://github.com/mongodb/mongo/blob/38c0eb538d0fd390c6cb9ce9ae9894153f6e8ef5/src/mongo/db/initialize_server_global_state.cpp#L237-L251
		# https://github.com/docker-library/mongo/issues/164#issuecomment-293965668
		mongod_cmd="$mongod_cmd --logpath /proc/$$/fd/1"
	else
		initdbLogPath=$dbPath"/docker-initdb.log"
		echo >&2 "warning: initdb logs cannot write to '/proc/$$/fd/1', so they are in '$initdbLogPath' instead"
		mongod_cmd="$mongod_cmd --logpath $initdbLogPath"
	fi
	mongod_cmd="$mongod_cmd --logappend"

	pidfile="/tmp/docker-entrypoint-temp-mongod.pid"
	rm -f "$pidfile"
	mongod_cmd="$mongod_cmd --pidfilepath $pidfile"

	# start mongod
	# init db or set password
	$mongod_cmd --fork

	mongo_cmd="mongo --quiet"

	# set mongodb password
	if [ "$MONGO_INITDB_ROOT_USERNAME" ] && [ "$MONGO_INITDB_ROOT_PASSWORD" ]; then
		rootAuthDatabase='admin'

		user_pwd="db.createUser({
			user: '$MONGO_INITDB_ROOT_USERNAME',
			pwd: '$MONGO_INITDB_ROOT_PASSWORD',
			roles: [ { role: 'root', db: '$rootAuthDatabase' } ]
		})"

		$mongo_cmd $rootAuthDatabase <<-EOJS
			$user_pwd
		EOJS
	fi

	# run init db     *.sh *.js
	for f in /docker-entrypoint-initdb.d/*; do
		case "$f" in
			*.sh) echo "$0: running $f"; . "$f" ;;
			*.js) echo "$0: running $f"; $mongo_cmd $f; echo ;;
			*)    echo "$0: ignoring $f" ;;
		esac
		echo
	done

	# shutdown mongod
	mongod --pidfilepath "$pidfile" --shutdown
	rm -f "$pidfile"

	echo
	echo 'MongoDB init process complete; ready for start up.'
	echo
fi

exec /bin/sh -c "$cmd"