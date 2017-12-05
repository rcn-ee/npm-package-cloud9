#!/bin/bash -e

DIR=$PWD

prefix="/opt/cloud9/.c9/node_modules"

export NODE_PATH=${prefix}/

npm_options="--prefix /opt/cloud9/.c9/"

echo "Resetting: ${prefix}/"
if [ -d ${prefix}/ ] ; then
	rm -rf ${prefix}/* || true
fi

mkdir -p ${prefix}/

distro=$(lsb_release -cs)

npm_git_install () {
	if [ -d ${prefix}/${npm_project}/ ] ; then
		rm -rf ${prefix}/${npm_project}/ || true
	fi

	if [ -d /tmp/${git_project}/ ] ; then
		echo "Resetting: /tmp/${git_project}/"
		rm -rf /tmp/${git_project}/ || true
	fi

	git clone -b ${git_branch} ${git_user}/${git_project} /tmp/${git_project}
	if [ -d /tmp/${git_project}/ ] ; then
		echo "Cloning: ${git_user}/${git_project}"
		cd /tmp/${git_project}/
		package_version=$(cat package.json | grep version | awk -F '"' '{print $4}' || true)
		git_version=$(git rev-parse --short HEAD)

		TERM=dumb ${node_bin} ${npm_bin} install ${npm_options}
		cd -
		rm -rf /tmp/${git_project}/
	fi

	wfile="${npm_project}-${package_version}-${git_version}-${node_version}"
	cd ${prefix}/
	if [ -f ${wfile}.tar.xz ] ; then
		rm -rf ${wfile}.tar.xz || true
	fi
	tar -hcJf ${wfile}.tar.xz ${npm_project}/
	cd -

	if [ ! -f ./deploy/${distro}/${wfile}.tar.xz ] ; then
		cp -v ${prefix}/${wfile}.tar.xz ./deploy/${distro}/
		echo "New Build: ${wfile}.tar.xz"
	fi

	if [ -d /tmp/${git_project}/ ] ; then
		rm -rf /tmp/${git_project}/
	fi
}

npm_pkg_install () {
	if [ -d ${prefix}/${npm_project}/ ] ; then
		rm -rf ${prefix}/${npm_project}/ || true
	fi

	cd /tmp/
	echo "TERM=dumb ${node_bin} ${npm_bin} pack ${npm_project}@${package_version}"
	tmp_package=$(TERM=dumb ${node_bin} ${npm_bin} pack ${npm_project}@${package_version} | tail -1)

	echo "TERM=dumb ${node_bin} ${npm_bin} install -g ${tmp_package} ${npm_options}"
	TERM=dumb ${node_bin} ${npm_bin} install -g ${tmp_package} ${npm_options}

	cd $DIR/

	wfile="${npm_project}-${package_version}-${node_version}"
	cd ${prefix}/
	if [ -f ${wfile}.tar.xz ] ; then
		rm -rf ${wfile}.tar.xz || true
	fi
	tar -cJf ${wfile}.tar.xz ${npm_project}/
	cd -

	if [ ! -f ./deploy/${distro}/${wfile}.tar.xz ] ; then
		cp -v ${prefix}/${wfile}.tar.xz ./deploy/${distro}/
		echo "New Build: ${wfile}.tar.xz"
	fi
}

npm_install () {
	node_bin="/usr/bin/nodejs"
	npm_bin="/usr/bin/npm"

	unset node_version
	node_version=$(${node_bin} --version || true)

	unset npm_version
	npm_version=$(${node_bin} ${npm_bin} --version || true)


	echo "npm: [`${node_bin} ${npm_bin} --version`]"
	echo "node: [`${node_bin} --version`]"

	npm_project="pty.js"
	package_version="0.3.1"
	npm_pkg_install
}

npm_install
