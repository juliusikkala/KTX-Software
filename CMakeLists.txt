# Copyright 2015-2020 The Khronos Group Inc.
# Modified by Julius Ikkala in 2021.
# SPDX-License-Identifier: Apache-2.0

cmake_minimum_required(VERSION 3.15)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake/modules/")

set(KTX_VERSION 4)

project(KTX-Software
    VERSION ${KTX_VERSION}
    DESCRIPTION "Libraries and tools to create and read KTX image texture files."
)

include(GNUInstallDirs)
include(CMakeDependentOption)

include(cmake/cputypetest.cmake)

# OPTIONS

if( IOS OR EMSCRIPTEN )
    set( LIB_TYPE_DEFAULT ON )
else()
    set( LIB_TYPE_DEFAULT OFF )
endif()

option( KTX_FEATURE_STATIC_LIBRARY "Create static libraries (shared otherwise)" ${LIB_TYPE_DEFAULT} )

set_target_processor_type(CPU_ARCHITECTURE)
if(CPU_ARCHITECTURE STREQUAL x86_64 OR CPU_ARCHITECTURE STREQUAL x86)
    option( BASISU_SUPPORT_SSE "Compile with SSE support so applications can choose to use it" ON )
endif()

CMAKE_DEPENDENT_OPTION(KTX_EMBED_BITCODE "Embed bitcode in binaries" OFF "APPLE AND IOS" OFF)

if(APPLE)
    set(XCODE_CODE_SIGN_IDENTITY "Development" CACHE STRING "Xcode code sign ID")
    set(XCODE_DEVELOPMENT_TEAM "" CACHE STRING "Xcode development team ID")
    set(PRODUCTBUILD_IDENTITY_NAME "" CACHE STRING "productbuild identity name")
    set(PRODUCTBUILD_KEYCHAIN_PATH "" CACHE FILEPATH "pkgbuild keychain file")
    if(IOS)
        set(XCODE_PROVISIONING_PROFILE_SPECIFIER "" CACHE STRING "Xcode provisioning profile specifier")
        set(MOLTENVK_SDK "$ENV{VULKAN_SDK}/../MoltenVK" CACHE STRING "MoltenVK directory inside the Vulkan SDK")
    endif()
endif()

# Might become options in the future

# option( KTX_FEATURE_KTX1 "KTX version 1" ON )
# option( KTX_FEATURE_KTX2 "KTX version 2" ON )

set( KTX_FEATURE_KTX1 ON )
set( KTX_FEATURE_KTX2 ON )
set( KTX_FEATURE_VULKAN ON )
set( KTX_FEATURE_GL_UPLOAD "" ON )

# Platform specific settings

if (WIN32 AND ${CMAKE_SYSTEM_NAME} STREQUAL "WindowsStore")
    # Disable OpenGL upload on Universal Windows Platform
    set(KTX_FEATURE_GL_UPLOAD OFF)
endif()

if(APPLE)
    set(CMAKE_OSX_DEPLOYMENT_TARGET "10.11" CACHE STRING "macOS Deployment Target")
    if(IOS)
        set(CMAKE_XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET "11.0" CACHE STRING "iOS Deployment Target")
        set(CMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH NO)
    endif()
endif()

if(UNIX AND NOT APPLE AND NOT EMSCRIPTEN AND NOT ANDROID)
    set(LINUX TRUE)
endif()

set(bitness 64)
if(NOT CMAKE_SIZEOF_VOID_P EQUAL 8 OR FORCE32)
        set(bitness 32)
endif()

if(KTX_FEATURE_STATIC_LIBRARY)
    set(LIB_TYPE STATIC)
else()
    if(IOS OR EMSCRIPTEN)
        message(SEND_ERROR "Library type cannot be shared for the current platform. Set KTX_FEATURE_STATIC_LIBRARY to ON!")
    endif()
    set(LIB_TYPE SHARED)
endif()

# Depends on the settings, so it must be included after
include(cmake/mkvk.cmake)

# Global compile & link options including optimization flags
if(MSVC)
    # With /W4 VS2015 (V19.0) issues many warnings that VS2017 & 2019 don't
    # so only increase warning level for recent versions.
    add_compile_options($<$<VERSION_GREATER_EQUAL:${CMAKE_CXX_COMPILER_VERSION},19.16>:/W4>)
    add_compile_options( $<IF:$<CONFIG:Debug>,/Gz,/O2> )
elseif(${CMAKE_CXX_COMPILER_ID} STREQUAL "GNU"
       OR ${CMAKE_CXX_COMPILER_ID} MATCHES "Clang")
    add_compile_options(-Wall -Wextra)
    add_compile_options( $<IF:$<CONFIG:Debug>,-O0,-O3> )
    add_link_options( $<IF:$<CONFIG:Debug>,-g,-O3> )
else()
    message(ERROR "${CMAKE_CXX_COMPILER_ID} not yet supported.")
endif()

set(KTX_MAIN_SRC
    include/ktx.h
    lib/basis_sgd.h
    lib/basis_transcode.cpp
    lib/basisu/transcoder/basisu_containers.h
    lib/basisu/transcoder/basisu_containers_impl.h
    lib/basisu/transcoder/basisu_file_headers.h
    lib/basisu/transcoder/basisu_global_selector_cb.h
    lib/basisu/transcoder/basisu_global_selector_palette.h
    lib/basisu/transcoder/basisu_transcoder_internal.h
    lib/basisu/transcoder/basisu_transcoder_uastc.h
    lib/basisu/transcoder/basisu_transcoder.cpp
    lib/basisu/transcoder/basisu_transcoder.h
    lib/basisu/transcoder/basisu.h
    lib/basisu/zstd/zstd.c
    lib/checkheader.c
    lib/dfdutils/createdfd.c
    lib/dfdutils/colourspaces.c
    lib/dfdutils/dfd.h
    lib/dfdutils/dfd2vk.inl
    lib/dfdutils/interpretdfd.c
    lib/dfdutils/printdfd.c
    lib/dfdutils/queries.c
    lib/dfdutils/vk2dfd.c
    lib/dfdutils/vulkan/vk_platform.h
    lib/dfdutils/vulkan/vulkan_core.h
    lib/filestream.c
    lib/filestream.h
    lib/formatsize.h
    lib/gl_format.h
    lib/hashlist.c
    lib/info.c
    lib/ktxint.h
    lib/memstream.c
    lib/memstream.h
    lib/strings.c
    lib/swap.c
    lib/texture.c
    lib/texture.h
    lib/texture2.c
    lib/texture2.h
    lib/uthash.h
    lib/vk_format.h
    lib/vkformat_check.c
    lib/vkformat_enum.h
    lib/vkformat_str.c
    )

if(KTX_FEATURE_GL_UPLOAD)
    list(APPEND KTX_MAIN_SRC
        lib/gl_funcs.c
        lib/gl_funcs.h
        lib/glloader.c
    )
endif()

# Read-only library
add_library( ktx_read ${LIB_TYPE}
    ${KTX_MAIN_SRC}
    )

macro(commom_lib_settings lib write)

    if(TARGET mkvk)
        # Creating vulkan headers is only required when Vulkan SDK updates.
        add_dependencies(${lib} mkvk)
    endif()

    set_target_properties(${lib} PROPERTIES
        PUBLIC_HEADER ${CMAKE_SOURCE_DIR}/include/ktx.h
        VERSION ${PROJECT_VERSION}
        SOVERSION ${PROJECT_VERSION_MAJOR}
        XCODE_ATTRIBUTE_ENABLE_HARDENED_RUNTIME "YES"
    )

    target_compile_definitions(
        ${lib}
    PUBLIC
        "$<$<CONFIG:Debug>:_DEBUG;DEBUG>"
    PRIVATE
        LIBKTX
    )

    # C/C++ Standard
    target_compile_features(${lib} PUBLIC c_std_99 cxx_std_11)

    # Compiler Warning Flags
    target_compile_options(${lib} PRIVATE
        # clang options
        $<$<CXX_COMPILER_ID:AppleClang,Clang>:
            -Wno-nested-anon-types
            -Wno-gnu-anonymous-struct
        >
        # not clang options
        $<$<NOT:$<CXX_COMPILER_ID:MSVC>>:
            -Wno-pedantic
        >
    )

    target_include_directories(
        ${lib}
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
    PRIVATE
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/lib/basisu/transcoder>
        $<INSTALL_INTERFACE:lib/basisu/transcoder>

        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/lib/basisu/zstd>
        $<INSTALL_INTERFACE:lib/basisu/zstd>
    )

    if( LIB_TYPE STREQUAL STATIC )
        # KHRONOS_STATIC overrides the value of KTX_API set below.
        target_compile_definitions(${lib} PUBLIC KHRONOS_STATIC)
    endif()

    # To reduce size, don't support transcoding to ancient formats.
    target_compile_definitions(${lib} PRIVATE BASISD_SUPPORT_FXT1=0)

    # TODO: make options for all formats and good per-platform defaults
    # - BASISD_SUPPORT_UASTC
    # - BASISD_SUPPORT_DXT1 (BC1)
    # - BASISD_SUPPORT_DXT5A (BC3/4/5)
    # - BASISD_SUPPORT_BC7
    # - BASISD_SUPPORT_BC7_MODE5
    # - BASISD_SUPPORT_PVRTC1
    # - BASISD_SUPPORT_ETC2_EAC_A8
    # - BASISD_SUPPORT_ASTC
    # - BASISD_SUPPORT_ATC
    # - BASISD_SUPPORT_ASTC_HIGHER_OPAQUE_QUALITY
    # - BASISD_SUPPORT_ETC2_EAC_RG11
    # - BASISD_SUPPORT_FXT1
    # - BASISD_SUPPORT_PVRTC2

    if(WIN32)
        target_compile_definitions(
            ${lib}
        PRIVATE
            # KHRONOS_STATIC defined earlier for the static library overrides
            # so no need for a generator expression to conditionally set this.
            KTX_API=__declspec\(dllexport\)
        PUBLIC # only for basisu_c_binding.
            BASISU_NO_ITERATOR_DEBUG_LEVEL
        )
    endif()

    if(KTX_FEATURE_KTX1)
        target_compile_definitions(${lib} PUBLIC KTX_FEATURE_KTX1)
        target_sources(
            ${lib}
        PRIVATE
            lib/texture1.c
            lib/texture1.h
        )
    endif()

    if(KTX_FEATURE_KTX2)
        target_compile_definitions(${lib} PUBLIC KTX_FEATURE_KTX2)
    endif()

    if(WIN32)
        # By wrapping in generator expression we force multi configuration generators (like Visual Studio)
        # to take the exact path and not change it.
        set(CMAKE_RUNTIME_OUTPUT_DIRECTORY $<1:${KTX_BUILD_DIR}/$<CONFIG>>)

    elseif(APPLE)
        if(KTX_EMBED_BITCODE)
            target_compile_options(${lib} PRIVATE "-fembed-bitcode")
        endif()
        if(NOT IOS)
            # Set a common RUNTIME_OUTPUT_DIR for all target, so that INSTALL RPATH
            # is functional in build directory as well. BUILD_WITH_INSTALL_RPATH is necessary
            # for working code signing.
            set(CMAKE_RUNTIME_OUTPUT_DIRECTORY $<1:${KTX_BUILD_DIR}/$<CONFIG>>)
        endif()

    elseif(LINUX)
        find_package(Threads REQUIRED)
        target_link_libraries(
            ${lib}
        PUBLIC
            dl
            Threads::Threads
        )
    endif()

    if(KTX_FEATURE_VULKAN)
        target_sources(
            ${lib}
        PRIVATE
            include/ktxvulkan.h
            lib/vk_funcs.c
            lib/vk_funcs.h
            lib/vkloader.c
        )
        target_include_directories(
            ${lib}
        PRIVATE
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/lib/dfdutils>
            $<INSTALL_INTERFACE:lib/dfdutils>
        )

        get_target_property( KTX_PUBLIC_HEADER ${lib} PUBLIC_HEADER )
        list(APPEND KTX_PUBLIC_HEADER ${CMAKE_SOURCE_DIR}/include/ktxvulkan.h)
        set_target_properties(${lib} PROPERTIES
            PUBLIC_HEADER "${KTX_PUBLIC_HEADER}"
        )
    else()
        target_compile_definitions( ${lib} PRIVATE KTX_OMIT_VULKAN=1 )
    endif()

endmacro(commom_lib_settings)

set(KTX_BUILD_DIR "${CMAKE_BINARY_DIR}")

commom_lib_settings(ktx_read 0)

target_compile_definitions(
    ktx_read
PRIVATE
    # We're reading the files ourselves so don't need Basis KTX v2 support.
    BASISD_SUPPORT_KTX2_ZSTD=0
    BASISD_SUPPORT_KTX2=0
)

# Turn off these warnings until Rich fixes the occurences.
# It it not clear to me if generator expressions can be used here
# hence the long-winded way.
if(MSVC)
# Currently no need to disable any warnings in basisu code. Rich fixed them.
elseif(${CMAKE_CXX_COMPILER_ID} STREQUAL "GNU")
    set_source_files_properties(
        lib/basisu/transcoder/basisu_transcoder.cpp
        PROPERTIES COMPILE_OPTIONS "-Wno-sign-compare;-Wno-unused-function;-Wno-unused-variable;-Wno-class-memaccess;-Wno-maybe-uninitialized"
        )
elseif(${CMAKE_CXX_COMPILER_ID} MATCHES "Clang")
else()
    message(ERROR "${CMAKE_CXX_COMPILER_ID} not yet supported.")
endif()

set(KTX_INSTALL_TARGETS ktx_read)

# Install

if(APPLE OR LINUX)
    # Have library's name links as separate component
    set(KTX_NAMELINKS ON)
    install(TARGETS ${KTX_INSTALL_TARGETS}
        EXPORT KTXTargets
        LIBRARY
            DESTINATION ${CMAKE_INSTALL_LIBDIR}
            COMPONENT library
            NAMELINK_SKIP
        PUBLIC_HEADER
            DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
            COMPONENT dev
    )
    install(TARGETS ${KTX_INSTALL_TARGETS}
        LIBRARY
            DESTINATION ${CMAKE_INSTALL_LIBDIR}
            COMPONENT library
            NAMELINK_ONLY
    )
else()
    # No name links on Windows
    set(KTX_NAMELINKS OFF)
    install(TARGETS ${KTX_INSTALL_TARGETS}
        EXPORT KTXTargets
        ARCHIVE
            DESTINATION ${CMAKE_INSTALL_LIBDIR}
            COMPONENT dev
        LIBRARY
            DESTINATION ${CMAKE_INSTALL_LIBDIR}
            COMPONENT library
        RUNTIME
            DESTINATION ${CMAKE_INSTALL_BINDIR}
            COMPONENT library
        PUBLIC_HEADER
            DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
            COMPONENT dev
    )
endif()
