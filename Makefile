DUCKDB_REPO=https://github.com/duckdb/duckdb.git
DUCKDB_REF=ab8c90985741ac68cd203c8396022894c1771d4b

.PHONY: install
install:
	go install .

.PHONY: examples
examples:
	go run examples/appender/main.go
	go run examples/json/main.go
	go run examples/scalar_udf/main.go
	go run examples/simple/main.go
	go run examples/table_udf/main.go
	go run examples/table_udf_parallel/main.go

.PHONY: test
test:
	go test -v -race -count=1 .

.PHONY: deps.header
deps.header:
	git clone --depth 1 ${DUCKDB_REPO}
	git -C ./duckdb fetch --depth 1 origin ${DUCKDB_REF}
	git -C ./duckdb checkout ${DUCKDB_REF}
	cp duckdb/src/include/duckdb.h duckdb.h

.PHONY: duckdb
duckdb:
	rm -rf duckdb
	git clone --depth 1 ${DUCKDB_REPO}
	git -C ./duckdb fetch --depth 1 origin ${DUCKDB_REF}
	git -C ./duckdb checkout ${DUCKDB_REF}
	cp extension_config_local.cmake duckdb/extension/extension_config.cmake


DUCKDB_COMMON_BUILD_FLAGS := BUILD_SHELL=0 DISABLE_SHELL=1 STATIC_LIBCPP=0 BUILD_UNITTESTS=0 DUCKDB_PLATFORM=any ENABLE_EXTENSION_AUTOLOADING=1 ENABLE_EXTENSION_AUTOINSTALL=1 SKIP_SUBSTRAIT_C_TESTS=true USE_MERGED_VCPKG_MANIFEST=1 VCPKG_TOOLCHAIN_PATH=${VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake 

.PHONY: deps.darwin.amd64
deps.darwin.amd64: duckdb
	if [ "$(shell uname -s | tr '[:upper:]' '[:lower:]')" != "darwin" ]; then echo "Error: must run build on darwin"; false; fi
	mkdir -p deps/darwin_amd64

	cd duckdb && \
	OSX_BUILD_ARCH="x86_64" CFLAGS="-target x86_64-apple-macos11 -O3" CXXFLAGS="-target x86_64-apple-macos11 -O3" ${DUCKDB_COMMON_BUILD_FLAGS} VCPKG_TARGET_TRIPLET=x64-osx make extension_configuration bundle-library -j 2
	cp duckdb/build/release/src/libduckdb.* deps/darwin_amd64/
	find duckdb/build/release/repository -name '*.duckdb_extension' -exec cp {} deps/darwin_amd64/ \;

.PHONY: deps.darwin.arm64
deps.darwin.arm64: duckdb
	if [ "$(shell uname -s | tr '[:upper:]' '[:lower:]')" != "darwin" ]; then echo "Error: must run build on darwin"; false; fi
	mkdir -p deps/darwin_arm64

	cd duckdb && \
	OSX_BUILD_ARCH="arm64" CFLAGS="-target arm64-apple-macos11 -O3" CXXFLAGS="-target arm64-apple-macos11 -O3" ${DUCKDB_COMMON_BUILD_FLAGS} VCPKG_TARGET_TRIPLET=arm64-osx make extension_configuration bundle-library -j 2
	cp duckdb/build/release/src/libduckdb.* deps/darwin_arm64/
	find duckdb/build/release/repository -name '*.duckdb_extension' -exec cp {} deps/darwin_arm64/ \;

.PHONY: deps.linux.amd64
deps.linux.amd64: duckdb
	if [ "$(shell uname -s | tr '[:upper:]' '[:lower:]')" != "linux" ]; then echo "Error: must run build on linux"; false; fi
	mkdir -p deps/linux_amd64

	cd duckdb && \
	CFLAGS="-O3" CXXFLAGS="-O3" ${DUCKDB_COMMON_BUILD_FLAGS} VCPKG_TARGET_TRIPLET=x64-linux make extension_configuration bundle-library -j 2
	cp duckdb/build/release/src/libduckdb.* deps/linux_amd64/
	find duckdb/build/release/repository -name '*.duckdb_extension' -exec cp {} deps/linux_amd64/ \;

.PHONY: deps.linux.arm64
deps.linux.arm64: duckdb
	if [ "$(shell uname -s | tr '[:upper:]' '[:lower:]')" != "linux" ]; then echo "Error: must run build on linux"; false; fi
	mkdir -p deps/linux_arm64

	cd duckdb && \
	CC="aarch64-linux-gnu-gcc" CXX="aarch64-linux-gnu-g++" CFLAGS="-O3" CXXFLAGS="-O3" ${DUCKDB_COMMON_BUILD_FLAGS} VCPKG_TARGET_TRIPLET=arm64-linux make extension_configuration bundle-library -j 2
	cp duckdb/build/release/src/libduckdb.* deps/linux_arm64/
	find duckdb/build/release/repository -name '*.duckdb_extension' -exec cp {} deps/linux_arm64/ \;

