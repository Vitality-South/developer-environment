#!/usr/bin/env bash

VS_DEV_VERSION=2.0.4
VS_DEV_LAST_UPDATED=2026-07-07

set -euo pipefail

echo "VS developer environment update version: ${VS_DEV_VERSION}"
echo "VS developer environment last updated on: ${VS_DEV_LAST_UPDATED}"

# do not run as root
if [[ $(id -u) -eq 0 ]]
then
	echo "Do not run as root"
	exit 1
fi

# Saving stdout's state
exec 3>&1
exec 4>&2

# Redirecting stdout to a file
exec 1>~/.vs-dev-setup.log
exec 2>&1

set -euo pipefail

alertOnError() {
    echo "An error occurred on the last command, exiting..." >&4
}

trap alertOnError ERR

MY_OS=`uname -s`
MY_UOS=`uname -o`
MY_ARCH=`uname -m`

echo "Your architecture is ${MY_ARCH}" >&3
echo "Your OS is ${MY_OS}" >&3

BUILD_DIR=~/.vsenvbuild
TARBALLS_DIR=~/.vsenvtarballs
VSBIN_DIR=~/.vsenvbin
VSSRC_DIR=~/.vssrc

GOLANG_VERSION=1.26.5                # https://go.dev/dl/
AWSCLI_VERSION=2.35.17               # https://raw.githubusercontent.com/aws/aws-cli/v2/CHANGELOG.rst
PROTOBUF_VERSION=35.1                # https://github.com/protocolbuffers/protobuf
GRPCWEB_VERSION=1.5.0                # https://github.com/grpc/grpc-web
GOLANGCILINT_VERSION=v2.12.2         # https://github.com/golangci/golangci-lint
AWSIAMAUTH_VERSION=0.7.14            # https://github.com/kubernetes-sigs/aws-iam-authenticator
CLI53_VERSION=0.9.0                  # https://github.com/barnybug/cli53
PROTOBUFJSGEN_VERSION=3.21.4         # https://github.com/protocolbuffers/protobuf-javascript/releases

TAILWINDCSS_CLI_VERSION=latest/download
WEBSOCAT_VERSION=latest/download

#NODEJS_ARCH=${MY_ARCH}
AWSCLI_ARCH=${MY_ARCH}
GOLANG_ARCH=${MY_ARCH}
PROTOBUF_ARCH=${MY_ARCH}
RESTIC_ARCH=${MY_ARCH}
GRPCWEB_ARCH=${MY_ARCH}
AWSIAMAUTH_ARCH=${MY_ARCH}
CLI53_ARCH=${MY_ARCH}
TAILWINDCSS_CLI_ARCH=${MY_ARCH}
WEBSOCAT_ARCH=${MY_ARCH}
PROTOBUFJSGEN_ARCH=${MY_ARCH}

VS_GO_BIN=$HOME/.vsenvbin/go/bin/go
VS_NPM_BIN=npm

if [[ "${MY_ARCH}" = "x86_64" || "${MY_ARCH}" = "amd64" ]]
then
#  NODEJS_ARCH=x64
  AWSCLI_ARCH=x86_64
  GOLANG_ARCH=amd64
  PROTOBUF_ARCH=x86_64
  RESTIC_ARCH=amd64
  GRPCWEB_ARCH=x86_64
  AWSIAMAUTH_ARCH=amd64
  CLI53_ARCH=amd64
  TAILWINDCSS_CLI_ARCH=x64
  WEBSOCAT_ARCH=x86_64
  PROTOBUFJSGEN_ARCH=x86_64
fi

if [[ "${MY_ARCH}" = "aarch64" || "${MY_ARCH}" = "arm64" ]]
then
#  NODEJS_ARCH=arm64
  AWSCLI_ARCH=aarch64
  GOLANG_ARCH=arm64
  PROTOBUF_ARCH=aarch_64
  RESTIC_ARCH=arm64
  GRPCWEB_ARCH=x86_64
  AWSIAMAUTH_ARCH=arm64
  CLI53_ARCH=arm64
  TAILWINDCSS_CLI_ARCH=arm64
  WEBSOCAT_ARCH=aarch64
  PROTOBUFJSGEN_ARCH=aarch_64
fi

if [[ "${MY_OS}" = "Linux" || "${MY_OS}" = "linux" ]]
then
  AWSCLI_OS=linux
  GOLANG_OS=linux
  PROTOBUF_OS=linux
  RESTIC_OS=linux
  KUBECTL_OS=linux
  EKSCTL_OS=Linux
  GRPCWEB_OS=linux
  AWSIAMAUTH_OS=linux
  HELM_OS=linux
  KOMPOSE_OS=linux
  CLI53_OS=linux
  TAILWINDCSS_CLI_OS=linux
  WEBSOCAT_OS=unknown-linux-musl
  PROTOBUFJSGEN_OS=linux
fi

AWSCLI_FILENAME=awscli-exe-${AWSCLI_OS}-${AWSCLI_ARCH}.zip
AWSCLI_ZIP=https://awscli.amazonaws.com/${AWSCLI_FILENAME}
GOLANG_FILENAME=go${GOLANG_VERSION}.${GOLANG_OS}-${GOLANG_ARCH}.tar.gz
GOLANG_ZIP=https://dl.google.com/go/${GOLANG_FILENAME}
PROTOBUF_FILENAME=protoc-${PROTOBUF_VERSION}-${PROTOBUF_OS}-${PROTOBUF_ARCH}.zip
PROTOBUF_ZIP=https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOBUF_VERSION}/${PROTOBUF_FILENAME}
GRPCWEB_URL=https://github.com/grpc/grpc-web/releases/download/${GRPCWEB_VERSION}/protoc-gen-grpc-web-${GRPCWEB_VERSION}-${GRPCWEB_OS}-${GRPCWEB_ARCH}
AWSIAMAUTH_URL=https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v${AWSIAMAUTH_VERSION}/aws-iam-authenticator_${AWSIAMAUTH_VERSION}_${AWSIAMAUTH_OS}_${AWSIAMAUTH_ARCH}
CLI53_URL=https://github.com/barnybug/cli53/releases/download/v${CLI53_VERSION}/cli53-${CLI53_OS}-${CLI53_ARCH}
TAILWINDCSS_CLI_URL=https://github.com/tailwindlabs/tailwindcss/releases/${TAILWINDCSS_CLI_VERSION}/tailwindcss-${TAILWINDCSS_CLI_OS}-${TAILWINDCSS_CLI_ARCH}
WEBSOCAT_URL=https://github.com/vi/websocat/releases/${WEBSOCAT_VERSION}/websocat.${WEBSOCAT_ARCH}-${WEBSOCAT_OS}
PROTOBUFJSGEN_FILENAME=protobuf-javascript-${PROTOBUFJSGEN_VERSION}-${PROTOBUFJSGEN_OS}-${PROTOBUFJSGEN_ARCH}.tar.gz
PROTOBUFJSGEN_URL=https://github.com/protocolbuffers/protobuf-javascript/releases/download/v${PROTOBUFJSGEN_VERSION}/${PROTOBUFJSGEN_FILENAME}

rm -rf ${BUILD_DIR}
mkdir -p ${BUILD_DIR} ${TARBALLS_DIR} ${VSBIN_DIR} ${VSSRC_DIR} $HOME/bin $HOME/.local/bin

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

# get protobuf-gen-js
if [ ! -f "${TARBALLS_DIR}/${PROTOBUFJSGEN_FILENAME}" ]
then
  echo "Downloading protoc-gen-js" >&3
  echo "Downloading protoc-gen-js..."
  curl -L -s -f -o ${TARBALLS_DIR}/${PROTOBUFJSGEN_FILENAME} ${PROTOBUFJSGEN_URL}
  if [ $? -ne 0 ]
  then
    echo "ERROR downloading protobuf-gen-js from ${PROTOBUFJSGEN_URL}"
    exit 1
  fi
  echo "Done."
fi

# install protobuf-gen-js
if [[ ! -f "${TARBALLS_DIR}/protobufjsgen-installed-${PROTOBUFJSGEN_VERSION}" && -f "${TARBALLS_DIR}/${PROTOBUFJSGEN_FILENAME}" ]]
then
  echo "Updating protoc-gen-js" >&3
  echo "Updating protoc-gen-js..."
  rm -rf ${VSBIN_DIR}/protobufjsgen
  rm -f ${TARBALLS_DIR}/protobufjsgen-installed-*
  tar -xzf ${TARBALLS_DIR}/${PROTOBUFJSGEN_FILENAME} -C ${BUILD_DIR}
  cp -f ${BUILD_DIR}/bin/protoc-gen-js ~/bin
  touch ${TARBALLS_DIR}/protobufjsgen-installed-${PROTOBUFJSGEN_VERSION}

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

# update buf
echo "Updating buf" >&3
echo "Updating buf..."
$VS_GO_BIN install github.com/bufbuild/buf/cmd/buf@latest
echo "Done."

# update grpcurl
echo "Updating grpcurl" >&3
echo "Updating grpcurl..."
$VS_GO_BIN install github.com/fullstorydev/grpcurl/cmd/grpcurl@latest
echo "Done."

# update protoc-gen-connect-go
echo "Updating protoc-gen-connect-go" >&3
echo "Updating protoc-gen-connect-go..."
$VS_GO_BIN install connectrpc.com/connect/cmd/protoc-gen-connect-go@latest
echo "Done."

# update protoc-gen-go-grpc Go gRPC for protobuf
echo "Updating protoc-gen-go-grpc" >&3
echo "Updating protoc-gen-go-grpc..."
$VS_GO_BIN install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
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
$VS_NPM_BIN install -g @vue/cli
echo "Done."

# install quasar cli
echo "Updating quasar cli" >&3
echo "Updating quasar cli..."
$VS_NPM_BIN i -g @quasar/cli
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
curl -sSfL https://golangci-lint.run/install.sh | sh -s -- -b $(go env GOPATH)/bin ${GOLANGCILINT_VERSION}
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

# update bazelisk
echo "Updating bazelisk" >&3
echo "Updating bazelisk..."
$VS_NPM_BIN install -g @bazel/bazelisk
echo "Done."

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

# update protoc-gen-connect-query
echo "Updating protoc-gen-connect-query" >&3
echo "Updating protoc-gen-connect-query..."
$VS_NPM_BIN install -g @connectrpc/protoc-gen-connect-query
echo "Done."

# update protoc-gen-connect-vue
echo "Updating protoc-gen-connect-vue" >&3
echo "Updating protoc-gen-connect-vue..."
$VS_NPM_BIN install -g @zachacious/protoc-gen-connect-vue
echo "Done."

# install https://github.com/timostamm/protobuf-ts
echo "Updating protoc-gen-ts" >&3
echo "Updating protoc-gen-ts..."
$VS_NPM_BIN install -g @protobuf-ts/plugin
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

# install gopls
echo "Updating gopls" >&3
echo "Updating gopls"
$VS_GO_BIN install golang.org/x/tools/gopls@latest
echo "Done."

# install Go staticcheck
echo "Updating Go staticcheck" >&3
echo "Updating Go staticcheck"
$VS_GO_BIN install honnef.co/go/tools/cmd/staticcheck@latest
echo "Done."

# install Go dlv
echo "Updating Go dlv" >&3
echo "Updating Go dlv"
$VS_GO_BIN install github.com/go-delve/delve/cmd/dlv@latest
echo "Done."

# install Go gotests
echo "Updating Go gotests" >&3
echo "Updating Go gotests"
$VS_GO_BIN install github.com/cweill/gotests/gotests@latest
echo "Done."

# install Go gomodifytags
echo "Updating Go gomodifytags" >&3
echo "Updating Go gomodifytags"
$VS_GO_BIN install github.com/fatih/gomodifytags@latest
echo "Done."

# install Go impl
echo "Updating Go impl" >&3
echo "Updating Go impl"
$VS_GO_BIN install github.com/josharian/impl@latest
echo "Done."

# install Go goplay
echo "Updating Go goplay" >&3
echo "Updating Go goplay"
$VS_GO_BIN install github.com/haya14busa/goplay/cmd/goplay@latest
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

# install protoc-gen-doc
echo "Updating protoc-gen-doc" >&3
echo "Updating protoc-gen-doc"
$VS_GO_BIN install github.com/pseudomuto/protoc-gen-doc/cmd/protoc-gen-doc@latest
echo "Done."

# npm global update
echo "Updating npm global packages" >&3
echo "Updating npm global packages"
$VS_NPM_BIN upgrade -g
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
echo "Close and re-open your shell or run the following to reload bash config: source ~/.bashrc"

exit 0
