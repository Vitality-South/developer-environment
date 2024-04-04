#!/usr/bin/env bash

# We support Linux, Mac, and Windows (if using WSL 2)

set -euo pipefail

# do not run as root
if [[ $(id -u) -eq 0 ]]
then
	echo "Do not run as root"
	exit 1
fi

doflutter=true
dohelm=true

showHelpMessage () {
        echo "Usage: $0 [arguments]"
        echo -e "\t-h\tShow this help message"
        echo -e "\t-s\tSkip install/upgrade of the following options"
	echo -e "\t\tflutter helm"
	echo -e "\t\tNote: -s can specified multiple times"
	echo "Example of skipping both flutter and helm install/upgrade:"
	echo "$0 -s flutter -s helm"
}

while getopts "hs:" opt
do
    case "${opt}" in
	s)
		case "${OPTARG}" in
			flutter) doflutter=false;;
			helm) dohelm=false;;
			*)
				echo "Unknown skip option: $OPTARG"
				showHelpMessage >&2
				exit 1
				;;
		esac
		;;
        h) 
		showHelpMessage
		exit 0
		;;
        ?)
                echo "Unknown option" >&2
		showHelpMessage >&2
                exit 1
                ;;
	:)
		echo "Option -$OPTARG requires an argument." >&2
		showHelpMessage >&2
		exit 1
		;;
    esac
done

# Saving stdout's state
exec 3>&1
exec 4>&2

# Redirecting stdout to a file
exec 1>~/.vs-dev-setup.log
exec 2>&1

set -euxo pipefail

alertOnError() {
    echo "An error occurred on the last command, exiting..." >&4
}

trap alertOnError ERR

make_gitconfig () {
cat <<EOF > "$HOME/.gitconfig"
[user]
	name = $1
	email = $2
[pull]
	rebase = true
[fetch]
	prune = true
[diff]
	colorMoved = zebra
EOF
}

if [ ! -f "$HOME/.gitconfig" ]
then
	read -p "Your name: " yourname
	read -p "Your email: " youremail
	make_gitconfig "$yourname" "$youremail"
fi

set_vs_env_variables () {
cat <<'EOF' >> $HOME/.bashrc

export VS_DEVENV_IS_SET=true

# local bin
export PATH=$HOME/.local/bin:$HOME/bin:$PATH

# flutter
export PATH=$HOME/.vssrc/flutter/bin:$HOME/.pub-cache/bin:$PATH

# golang
export PATH=$HOME/.vsenvbin/go/bin:$PATH
export PATH=$HOME/go/bin:$PATH

# yarn global install path
export PATH=$HOME/.yarn/bin:$PATH

# Java home
export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH=$BUN_INSTALL/bin:$PATH

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Load Angular CLI autocompletion.
source <(ng completion script)
EOF
}

if ! grep -q "VS_DEVENV_IS_SET=" $HOME/.bashrc; then
	set_vs_env_variables
	source $HOME/.bashrc
	export VS_DEVENV_IS_SET=true

	# local bin
	export PATH=$HOME/.local/bin:$HOME/bin:$PATH

	# nodejs - use nvm instead
	#export PATH=$HOME/.vsenvbin/nodejs/bin:$PATH

	# flutter
	export PATH=$HOME/.vssrc/flutter/bin:$HOME/.pub-cache/bin:$PATH

	# golang
	export PATH=$HOME/.vsenvbin/go/bin:$PATH
	export PATH=$HOME/go/bin:$PATH

	# yarn global install path
	export PATH=$HOME/.yarn/bin:$PATH

	# Java home
	export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"

	# bun
	export BUN_INSTALL="$HOME/.bun"
	export PATH=$BUN_INSTALL/bin:$PATH
fi

MY_OS=`uname -s`
MY_UOS=`uname -o`
MY_ARCH=`uname -m`

if [[ "${OS:-}" = "Windows_NT" || "$OSTYPE" = "cygwin" || "$OSTYPE" = "msys" || "$OSTYPE" = "win32" || "${MY_UOS}" = "Msys" || "${MY_UOS}" = "Cygwin" || "${MY_OS}" = "Windows_NT" ]]
then
	echo 'error: Run in Windows Subsystem for Linux (WSL 2)' >&4
	exit 1
fi

echo "Your architecture is ${MY_ARCH}" >&3
echo "Your OS is ${MY_OS}" >&3


BUILD_DIR=~/.vsenvbuild
TARBALLS_DIR=~/.vsenvtarballs
VSBIN_DIR=~/.vsenvbin
VSSRC_DIR=~/.vssrc

GOLANG_VERSION=1.22.2                # https://go.dev/dl/
NVM_VERSION=0.39.7                   # https://github.com/nvm-sh/nvm
NODEJS_VERSION=20.11.1               # installed via nvm
AWSCLI_VERSION=2.15.35               # https://raw.githubusercontent.com/aws/aws-cli/v2/CHANGELOG.rst
PROTOBUF_VERSION=26.1                # https://github.com/protocolbuffers/protobuf
RESTIC_VERSION=0.16.4                # https://github.com/restic/restic
GRPCWEB_VERSION=1.5.0                # https://github.com/grpc/grpc-web
GOLANGCILINT_VERSION=v1.57.2         # https://github.com/golangci/golangci-lint
KUBECTL_VERSION=1.27.9/2024-01-04    # https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html
EKSCTL_VERSION=0.175.0               # https://github.com/weaveworks/eksctl
AWSIAMAUTH_VERSION=0.6.14            # https://github.com/kubernetes-sigs/aws-iam-authenticator
HELM_VERSION=3.14.3                  # https://github.com/helm/helm/releases
YQ_VERSION=v4.43.1                   # https://github.com/mikefarah/yq
KOMPOSE_VERSION=v1.32.0              # https://github.com/kubernetes/kompose
CLI53_VERSION=0.8.22                 # https://github.com/barnybug/cli53

TAILWINDCSS_CLI_VERSION=latest/download
WEBSOCAT_VERSION=latest/download


#NODEJS_ARCH=${MY_ARCH}
AWSCLI_ARCH=${MY_ARCH}
GOLANG_ARCH=${MY_ARCH}
PROTOBUF_ARCH=${MY_ARCH}
RESTIC_ARCH=${MY_ARCH}
GRPCWEB_ARCH=${MY_ARCH}
EKSCTL_ARCH=${MY_ARCH}
KUBECTL_ARCH=${MY_ARCH}
AWSIAMAUTH_ARCH=${MY_ARCH}
HELM_ARCH=${MY_ARCH}
YQ_ARCH=${MY_ARCH}
KOMPOSE_ARCH=${MY_ARCH}
CLI53_ARCH=${MY_ARCH}
TAILWINDCSS_CLI_ARCH=${MY_ARCH}
WEBSOCAT_ARCH=${MY_ARCH}

VS_GO_BIN=$HOME/.vsenvbin/go/bin/go
VS_FLUTTER_BIN=$HOME/.vssrc/flutter/bin/flutter
VS_DART_BIN=$HOME/.vssrc/flutter/bin/dart
VS_BUN_BIN=$HOME/.bun/bin/bun
#VS_NODEJS_BIN=$HOME/.vsenvbin/nodejs/bin/node

if [[ "${MY_ARCH}" = "x86_64" || "${MY_ARCH}" = "amd64" ]]
then
#  NODEJS_ARCH=x64
  AWSCLI_ARCH=x86_64
  GOLANG_ARCH=amd64
  PROTOBUF_ARCH=x86_64
  RESTIC_ARCH=amd64
  EKSCTL_ARCH=amd64
  KUBECTL_ARCH=amd64
  GRPCWEB_ARCH=x86_64
  AWSIAMAUTH_ARCH=amd64
  HELM_ARCH=amd64
  YQ_ARCH=amd64
  KOMPOSE_ARCH=amd64
  CLI53_ARCH=amd64
  TAILWINDCSS_CLI_ARCH=x64
  WEBSOCAT_ARCH=x86_64
fi

if [[ "${MY_ARCH}" = "aarch64" || "${MY_ARCH}" = "arm64" ]]
then
#  NODEJS_ARCH=arm64
  AWSCLI_ARCH=aarch64
  GOLANG_ARCH=arm64
  PROTOBUF_ARCH=aarch_64
  RESTIC_ARCH=arm64
  KUBECTL_ARCH=arm64
  EKSCTL_ARCH=arm64
  GRPCWEB_ARCH=x86_64
  AWSIAMAUTH_ARCH=arm64
  HELM_ARCH=arm64
  YQ_ARCH=arm64
  KOMPOSE_ARCH=arm64
  CLI53_ARCH=arm64
  TAILWINDCSS_CLI_ARCH=arm64
  WEBSOCAT_ARCH=aarch64
fi

if [[ "${MY_OS}" = "Linux" || "${MY_OS}" = "linux" ]]
then
#  NODEJS_OS=linux
  AWSCLI_OS=linux
  GOLANG_OS=linux
  PROTOBUF_OS=linux
  RESTIC_OS=linux
  KUBECTL_OS=linux
  EKSCTL_OS=Linux
  GRPCWEB_OS=linux
  AWSIAMAUTH_OS=linux
  HELM_OS=linux
  YQ_OS=linux
  KOMPOSE_OS=linux
  CLI53_OS=linux
  TAILWINDCSS_CLI_OS=linux
  WEBSOCAT_OS=unknown-linux-musl

  echo "Installing linux OS updates via apt; sudo password may be needed here" >&3

  # for android studio
  sudo dpkg --add-architecture i386

  sudo apt update
  sudo apt upgrade -y
  sudo apt install -y build-essential dos2unix jq unzip zip jsdoc-toolkit docker.io docker-compose git bash xz-utils curl wget libglu1-mesa ca-certificates tzdata locales file lsb-release gcc libgl1-mesa-dev xorg-dev subversion cmake libpng-dev libssl-dev libpcre2-dev libz-dev libbz2-dev liblzma-dev liblz4-dev libzstd-dev

  # for Zint barcode lib
  sudo apt install -y mesa-common-dev libglu1-mesa-dev
  sudo apt install -y libxcb-xinerama0

  # for flutter linux toolchain
  # https://docs.flutter.dev/get-started/install/linux
  sudo apt install -y clang cmake git ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev

  # for android studio
  sudo apt install -y libc6:i386 libncurses5:i386 libstdc++6:i386 lib32z1 libbz2-1.0:i386

  # Java for Ionic
  sudo apt install -y default-jre default-jdk openjdk-17-jre openjdk-17-jdk 
fi

if [[ "${MY_OS}" = "Darwin" || "${MY_OS}" = "darwin" ]]
then
#  NODEJS_OS=darwin
  AWSCLI_OS=darwin
  GOLANG_OS=darwin
  PROTOBUF_OS=osx
  RESTIC_OS=darwin
  KUBECTL_OS=darwin
  EKSCTL_OS=Darwin
  GRPCWEB_OS=darwin
  AWSIAMAUTH_OS=darwin
  HELM_OS=darwin
  YQ_OS=darwin
  KOMPOSE_OS=darwin
  CLI53_OS=mac
  TAILWINDCSS_CLI_OS=macos
  WEBSOCAT_OS=apple-darwin
fi

AWSCLI_FILENAME=awscli-exe-${AWSCLI_OS}-${AWSCLI_ARCH}.zip
AWSCLI_ZIP=https://awscli.amazonaws.com/${AWSCLI_FILENAME}
#NODEJS_FILENAME=node-v${NODEJS_VERSION}-${NODEJS_OS}-${NODEJS_ARCH}.tar.xz
#NODEJS_ZIP=https://nodejs.org/dist/v${NODEJS_VERSION}/${NODEJS_FILENAME}
GOLANG_FILENAME=go${GOLANG_VERSION}.${GOLANG_OS}-${GOLANG_ARCH}.tar.gz
GOLANG_ZIP=https://dl.google.com/go/${GOLANG_FILENAME}
PROTOBUF_FILENAME=protoc-${PROTOBUF_VERSION}-${PROTOBUF_OS}-${PROTOBUF_ARCH}.zip
PROTOBUF_ZIP=https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERSION}/${PROTOBUF_FILENAME}
RESTIC_FILENAME=restic_${RESTIC_VERSION}_${RESTIC_OS}_${RESTIC_ARCH}.bz2
RESTIC_ZIP=https://github.com/restic/restic/releases/download/v${RESTIC_VERSION}/${RESTIC_FILENAME}
GRPCWEB_URL=https://github.com/grpc/grpc-web/releases/download/${GRPCWEB_VERSION}/protoc-gen-grpc-web-${GRPCWEB_VERSION}-${GRPCWEB_OS}-${GRPCWEB_ARCH}
KUBECTL_URL=https://s3.us-west-2.amazonaws.com/amazon-eks/${KUBECTL_VERSION}/bin/${KUBECTL_OS}/${KUBECTL_ARCH}/kubectl
EKSCTL_URL=https://github.com/weaveworks/eksctl/releases/download/v${EKSCTL_VERSION}/eksctl_${EKSCTL_OS}_${EKSCTL_ARCH}.tar.gz
AWSIAMAUTH_URL=https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v${AWSIAMAUTH_VERSION}/aws-iam-authenticator_${AWSIAMAUTH_VERSION}_${AWSIAMAUTH_OS}_${AWSIAMAUTH_ARCH}
HELM_URL=https://get.helm.sh/helm-v${HELM_VERSION}-${HELM_OS}-${HELM_ARCH}.tar.gz
YQ_URL=https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_${YQ_OS}_${YQ_ARCH}
KOMPOSE_URL=https://github.com/kubernetes/kompose/releases/download/${KOMPOSE_VERSION}/kompose-${KOMPOSE_OS}-${KOMPOSE_ARCH}
CLI53_URL=https://github.com/barnybug/cli53/releases/download/${CLI53_VERSION}/cli53-${CLI53_OS}-${CLI53_ARCH}
TAILWINDCSS_CLI_URL=https://github.com/tailwindlabs/tailwindcss/releases/${TAILWINDCSS_CLI_VERSION}/tailwindcss-${TAILWINDCSS_CLI_OS}-${TAILWINDCSS_CLI_ARCH}
WEBSOCAT_URL=https://github.com/vi/websocat/releases/${WEBSOCAT_VERSION}/websocat.${WEBSOCAT_ARCH}-${WEBSOCAT_OS}

# override with macOS specific changes
if [[ "${MY_OS}" = "Darwin" || "${MY_OS}" = "darwin" ]]
then
  AWSCLI_FILENAME=AWSCLIV2.pkg
  AWSCLI_ZIP=https://awscli.amazonaws.com/AWSCLIV2.pkg
  KUBECTL_ARCH=amd64
  KUBECTL_URL=https://s3.us-west-2.amazonaws.com/amazon-eks/${KUBECTL_VERSION}/bin/${KUBECTL_OS}/${KUBECTL_ARCH}/kubectl
fi

rm -rf ${BUILD_DIR}
mkdir -p ${BUILD_DIR} ${TARBALLS_DIR} ${VSBIN_DIR} ${VSSRC_DIR} $HOME/bin $HOME/.local/bin

# install or update nvm
echo "Installing nvm" >&3
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
nvm install ${NODEJS_VERSION}
nvm alias default ${NODEJS_VERSION}
nvm use ${NODEJS_VERSION}
VS_NPM_BIN=$HOME/.nvm/versions/node/v${NODEJS_VERSION}/bin/npm

if [ "${doflutter}" = true ]
then
  echo "Updating flutter to the latest stable release" >&3
	# get flutter if it's not downloaded
	if [ ! -d "${VSSRC_DIR}/flutter" ]
	then
		pushd ${VSSRC_DIR}
		git clone https://github.com/flutter/flutter.git -b stable
		popd
	fi

	# update flutter to latest stable
	if [ -d "${VSSRC_DIR}/flutter" ]
	then
		pushd ${VSSRC_DIR}/flutter
		git pull
		$VS_FLUTTER_BIN precache
		$VS_DART_BIN pub global activate protoc_plugin
		popd
	fi
fi

# get AWS CLI v2
if [ ! -f "${TARBALLS_DIR}/${AWSCLI_FILENAME}" ]
then
  echo "Downloading AWS cli v2" >&3
  echo "Downloading AWS CLI v2..."
  curl -L -s -f -o ${TARBALLS_DIR}/${AWSCLI_FILENAME} ${AWSCLI_ZIP}
  if [ $? -ne 0 ]
  then
    echo "ERROR downloading AWS CLI v2 from ${AWSCLI_ZIP}"
    exit 1
  fi
  echo "Done."
fi

if [[ ! -f "${TARBALLS_DIR}/awscli-installed-${AWSCLI_VERSION}" && -f "${TARBALLS_DIR}/${AWSCLI_FILENAME}" ]]
then
  echo "Updating AWS cli v2" >&3
  echo "Updating AWS CLI v2..."
  rm -rf ${VSBIN_DIR}/awscli
  rm -f ${TARBALLS_DIR}/awscli-installed-*

  curl -L -s -f -o ${TARBALLS_DIR}/${AWSCLI_FILENAME} ${AWSCLI_ZIP}

  if [ "${MY_OS}" = "Darwin" ]
  then
    echo "sudo password may be needed here to install AWS cli" >&3
    sudo installer -pkg ${TARBALLS_DIR}/${AWSCLI_FILENAME} -target /
  else
    unzip -q ${TARBALLS_DIR}/${AWSCLI_FILENAME} -d ${BUILD_DIR}
    ${BUILD_DIR}/aws/install -i ${VSBIN_DIR}/awscli -b $HOME/bin --update
    touch ${TARBALLS_DIR}/awscli-installed-${AWSCLI_VERSION}
  fi

  # clean build directory when done
  rm -rf ${BUILD_DIR}
  mkdir -p ${BUILD_DIR}
  echo "Done."
fi

# get restic
if [ ! -f "${TARBALLS_DIR}/${RESTIC_FILENAME}" ]
then
  echo "Downloading restic" >&3
  echo "Downloading restic..."
  curl -L -s -f -o ${TARBALLS_DIR}/${RESTIC_FILENAME} ${RESTIC_ZIP}
  if [ $? -ne 0 ]
  then
    echo "ERROR downloading restic from ${RESTIC_ZIP}"
    exit 1
  fi
  echo "Done."
fi

if [[ ! -f "${TARBALLS_DIR}/restic-installed-${RESTIC_VERSION}" && -f "${TARBALLS_DIR}/${RESTIC_FILENAME}" ]]
then
  echo "Updating restic" >&3
  echo "Updating restic..."
  rm -rf ${VSBIN_DIR}/restic
  rm -f ${TARBALLS_DIR}/restic-installed-*
  cp -f ${TARBALLS_DIR}/${RESTIC_FILENAME} ${BUILD_DIR}
  bunzip2 -q ${BUILD_DIR}/${RESTIC_FILENAME}
  mv -f ${BUILD_DIR}/${RESTIC_FILENAME/.bz2/} ~/bin/restic
  chmod a+x ~/bin/restic
  touch ${TARBALLS_DIR}/restic-installed-${RESTIC_VERSION}

  # clean build directory when done
  rm -rf ${BUILD_DIR}
  mkdir -p ${BUILD_DIR}
  echo "Done."
fi

# get Protocol Buffers (Protobuf)
if [ ! -f "${TARBALLS_DIR}/${PROTOBUF_FILENAME}" ]
then
  echo "Downloading Protobuf" >&3
  echo "Downloading Protobuf..."
  curl -L -s -f -o ${TARBALLS_DIR}/${PROTOBUF_FILENAME} ${PROTOBUF_ZIP}
  if [ $? -ne 0 ]
  then
    echo "ERROR downloading Protobuf from ${PROTOBUF_ZIP}"
    exit 1
  fi
  echo "Done."
fi

if [[ ! -f "${TARBALLS_DIR}/protobuf-installed-${PROTOBUF_VERSION}" && -f "${TARBALLS_DIR}/${PROTOBUF_FILENAME}" ]]
then
  echo "Updating Protobuf" >&3
  echo "Updating Protobuf..."
  rm -rf ${VSBIN_DIR}/protobuf
  rm -f ${TARBALLS_DIR}/protobuf-installed-*
  unzip -q ${TARBALLS_DIR}/${PROTOBUF_FILENAME} -d ${BUILD_DIR}
  cp -f ${BUILD_DIR}/bin/protoc ~/bin
  mkdir -p ~/.protobufincludes
  rm -rf ~/.protobufincludes/google
  cp -a ${BUILD_DIR}/include/google ~/.protobufincludes
  touch ${TARBALLS_DIR}/protobuf-installed-${PROTOBUF_VERSION}

  # clean build directory when done
  rm -rf ${BUILD_DIR}
  mkdir -p ${BUILD_DIR}
  echo "Done."
fi

# get golang
if [ ! -f "${TARBALLS_DIR}/${GOLANG_FILENAME}" ]
then
  echo "Downloading golang" >&3
  echo "Downloading golang..."
  curl -L -s -f -o ${TARBALLS_DIR}/${GOLANG_FILENAME} ${GOLANG_ZIP}
  if [ $? -ne 0 ]
  then
    echo "ERROR downloading Golang from ${GOLANG_ZIP}"
  fi
  echo "Done."
fi

if [[ ! -f "${TARBALLS_DIR}/go-installed-${GOLANG_VERSION}" && -f "${TARBALLS_DIR}/${GOLANG_FILENAME}" ]]
then
  echo "Updating golang" >&3
  echo "Updating Golang..."
  rm -rf ${VSBIN_DIR}/go
  rm -f ${TARBALLS_DIR}/go-installed-*
  tar -C ${VSBIN_DIR} -xzf ${TARBALLS_DIR}/${GOLANG_FILENAME}
  touch ${TARBALLS_DIR}/go-installed-${GOLANG_VERSION}
  echo "Done."
fi

# update golint
echo "Updating golint" >&3
echo "Updating golint..."
$VS_GO_BIN install golang.org/x/lint/golint@latest
echo "Done."

# update protoc-gen-go Protobuf for Go
echo "Updating protoc-gen-go" >&3
echo "Updating protoc-gen-go..."
$VS_GO_BIN install google.golang.org/protobuf/cmd/protoc-gen-go@latest
echo "Done."

# update protoc-gen-go-grpc Go gRPC for protobuf
echo "Updating protoc-gen-go-grpc" >&3
echo "Updating protoc-gen-go-grpc..."
$VS_GO_BIN install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
echo "Done."

# upgrade npm to latest
echo "Updating npm to latest" >&3
echo "Updating npm to latest..."
$VS_NPM_BIN install -g npm@latest
echo "Done."

# install yarn
echo "Updating yarn" >&3
echo "Updating yarn..."
$VS_NPM_BIN install -g yarn
echo "Done."

# install pnpm
echo "Updating pnpm" >&3
echo "Updating pnpm..."
$VS_NPM_BIN install -g pnpm
echo "Done."

# update cli53
echo "Updating cli53" >&3
echo "Updating cli53..."
curl --silent --location -o ~/bin/cli53 "${CLI53_URL}"
chmod a+x ~/bin/cli53
echo "Done."

# install vue cli
echo "Updating vue cli" >&3
echo "Updating vue cli..."
yarn global add @vue/cli
echo "Done."

# install quasar cli
echo "Updating quasar cli" >&3
echo "Updating quasar cli..."
yarn global add @quasar/cli
echo "Done."

# install hexo
echo "Updating hexo " >&3
echo "Updating hexo..."
$VS_NPM_BIN install -g hexo-cli
echo "Done."

# install eslint
echo "Updating eslint" >&3
echo "Updating eslint..."
$VS_NPM_BIN install -g eslint
echo "Done."

# install twilio-cli
echo "Updating twilio-cli" >&3
echo "Updating twilio-cli..."
$VS_NPM_BIN install -g twilio-cli
echo "Done."

# install goimports
echo "Updating goimports" >&3
echo "Updating goimports..."
$VS_GO_BIN install golang.org/x/tools/cmd/goimports@latest
echo "Done."

# install gofumpt
echo "Updating gofumpt" >&3
echo "Updating gofumpt..."
$VS_GO_BIN install mvdan.cc/gofumpt@latest
echo "Done."

# install golangci-lint
echo "Updating golangci-lint" >&3
echo "Updating golangci-lint..."
curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $($VS_GO_BIN env GOPATH)/bin ${GOLANGCILINT_VERSION}
echo "Done."

# update protoc-go-inject-tag (tag generation for Go protobuf)
echo "Updating protoc-go-inject-tag" >&3
echo "Updating protoc-go-inject-tag..."
$VS_GO_BIN install github.com/favadi/protoc-go-inject-tag@latest
echo "Done."

# update godoc
echo "Updating godoc" >&3
echo "Updating godoc..."
$VS_GO_BIN install golang.org/x/tools/cmd/godoc@latest
echo "Done."

# update aws amplify cli
echo "Updating aws amplify cli" >&3
echo "Updating aws amplify cli..."
$VS_NPM_BIN install -g @aws-amplify/cli
echo "Done."

# install latest fmgen for Go
echo "Updating fmgen for Go" >&3
echo "Updating fmgen for Go..."
$VS_GO_BIN install github.com/ryan-holcombe/fmgen@latest
echo "Done."

# update google apis
echo "Updating google apis for protobuf" >&3
echo "Updating google apis for protobuf..."
if [ -d "$HOME/.vsgoogleapis" ]
then
  git -C $HOME/.vsgoogleapis pull
else
  git clone https://github.com/googleapis/googleapis.git $HOME/.vsgoogleapis
fi
echo "Done."

# update eksctl
echo "Updating eksctl" >&3
echo "Updating eksctl..."
curl --silent --location "${EKSCTL_URL}" | tar xz -C /tmp
sudo mv -f /tmp/eksctl /usr/local/bin
echo "Done."

# update kubectl
echo "Updating kubectl" >&3
echo "Updating kubectl..."
curl --silent --location -o ~/bin/kubectl "${KUBECTL_URL}"
chmod a+x ~/bin/kubectl
echo "Done."

# update aws-iam-authenticator
echo "Updating aws-iam-authenticator" >&3
echo "Updating aws-iam-authenticator..."
curl --silent --location -o ~/bin/aws-iam-authenticator "${AWSIAMAUTH_URL}"
chmod a+x ~/bin/aws-iam-authenticator
echo "Done."

# update protoc-gen-grpc-web
echo "Updating protoc-gen-grpc-web" >&3
echo "Updating protoc-gen-grpc-web..."
curl --silent --location -o ~/bin/protoc-gen-grpc-web "${GRPCWEB_URL}"
chmod a+x ~/bin/protoc-gen-grpc-web
echo "Done."

# update helm
if [ "${dohelm}" = true ]
then
	echo "Updating helm" >&3
	echo "Updating helm..."
	curl --silent --location "${HELM_URL}" | tar zx --strip-components=1 -C ~/bin ${HELM_OS}-${HELM_ARCH}/helm
	chmod a+x ~/bin/helm
	echo "Done."
fi

# update yq
echo "Updating yq" >&3
echo "Updating yq..."
curl --silent --location -o ~/bin/yq "${YQ_URL}" 
chmod a+x ~/bin/yq
echo "Done."

# update kompose
echo "Updating kompose" >&3
echo "Updating kompose..."
curl --silent --location -o ~/bin/kompose "${KOMPOSE_URL}" 
chmod a+x ~/bin/kompose
echo "Done."

# update bazelisk
echo "Updating bazelisk" >&3
echo "Updating bazelisk..."
$VS_NPM_BIN install -g @bazel/bazelisk
echo "Done."

# get protobuf-javascript/protoc-gen-js
echo "Updating protobuf-javascript/protoc-gen-js" >&3
echo "Updating protobuf-javascript/protoc-gen-js..."
pushd ${VSSRC_DIR}
rm -rf protobuf-javascript
git clone https://github.com/protocolbuffers/protobuf-javascript.git
popd

# update protobuf-javascript/protoc-gen-js to latest stable
if [ -d "${VSSRC_DIR}/protobuf-javascript" ]
then
  pushd ${VSSRC_DIR}/protobuf-javascript
  git pull
  bazel build //generator:protoc-gen-js
  cp -f bazel-bin/generator/protoc-gen-js ~/bin
  bazel clean --expunge
  popd
fi

# update protoc-gen-connect-web
echo "Updating protoc-gen-connect-web" >&3
echo "Updating protoc-gen-connect-web..."
$VS_NPM_BIN install -g @bufbuild/protoc-gen-connect-web
echo "Done."

# update typescript
echo "Updating typescript" >&3
echo "Updating typescript..."
$VS_NPM_BIN install -g typescript
echo "Done."

# update cloudflare wrangler
echo "Updating cloudflare wrangler" >&3
echo "Updating cloudflare wrangler..."
$VS_NPM_BIN install -g wrangler
echo "Done."

# update protoc-gen-es
echo "Updating protoc-gen-es" >&3
echo "Updating protoc-gen-es..."
$VS_NPM_BIN install -g @bufbuild/protoc-gen-es
echo "Done."

# install https://github.com/timostamm/protobuf-ts
echo "Updating protoc-gen-ts" >&3
echo "Updating protoc-gen-ts..."
$VS_NPM_BIN install -g @protobuf-ts/plugin
echo "Done."

# install Ionic cli
echo "Updating Ionic CLI" >&3
echo "Updating Ionic CLI"
$VS_NPM_BIN install -g @ionic/cli
echo "Done."

# install Angular cli
echo "Updating Angular CLI" >&3
echo "Updating Angular CLI"
$VS_NPM_BIN install -g @angular/cli
echo "Done."

# install sass
echo "Updating sass" >&3
echo "Updating sass"
$VS_NPM_BIN install -g sass
echo "Done."

# install blowfish-tools
echo "Updating blowfish-tools" >&3
echo "Updating blowfish-tools"
$VS_NPM_BIN install -g blowfish-tools
echo "Done."

# install taskfile.dev task tool
echo "Updating Taskfile.dev task tool" >&3
echo "Updating Taskfile.dev task tool"
$VS_GO_BIN install github.com/go-task/task/v3/cmd/task@latest
echo "Done."

# install cobra cli
echo "Updating cobra cli" >&3
echo "Updating cobra cli"
$VS_GO_BIN install github.com/spf13/cobra-cli@latest
echo "Done."

# install hugo extended edition
echo "Installing hugo extended edition" >&3
echo "Installing hugo extended edition..."
CGO_ENABLED=1 $VS_GO_BIN install -tags extended github.com/gohugoio/hugo@latest
echo "Done."

# install tailwindcss cli
echo "Installing tailwindcss cli" >&3
echo "Installing tailwindcss cli..."
curl -sL -o ~/bin/tailwindcss ${TAILWINDCSS_CLI_URL}
chmod +x ~/bin/tailwindcss
echo "Done."

# install  websocat
echo "Installing websocat" >&3
echo "Installing websocat..."
curl -sL -o ~/bin/websocat ${WEBSOCAT_URL}
chmod +x ~/bin/websocat
echo "Done."

# npm global update
echo "Updating npm global packages" >&3
echo "Updating npm global packages"
$VS_NPM_BIN upgrade -g
echo "Done."

# yarn global update
echo "Updating yarn global packages" >&3
echo "Updating yarn global packages"
yarn global upgrade
echo "Done."

# install bun
echo "Updating bun" >&3
echo "Updating bun"
curl -fsSL https://bun.sh/install | bash
$VS_BUN_BIN upgrade || true
echo "Done."

set +x

# Restore stdout and stderr to original state
exec 1>&3
exec 2>&3
exec 3>&-
exec 4>&-

echo ""
echo "Everything updated successfully!"
echo ""
echo "Close and re-open shell or run the following to reload bash config: source ~/.bashrc"

exit 0