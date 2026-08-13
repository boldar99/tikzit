cmake_minimum_required(VERSION 3.16)

project(tikzit LANGUAGES CXX)

set(FULL_VERSION "2.2")

if (NOT QT_VER)
    set(QT_VER "Qt6")
endif ()

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)

find_package(${QT_VER} REQUIRED COMPONENTS Core Gui Widgets Network Pdf) # <<-- added Pdf component
find_package(BISON)
find_package(FLEX)

include_directories(
    ${PROJECT_SOURCE_DIR}
    ${PROJECT_SOURCE_DIR}/src
    ${PROJECT_SOURCE_DIR}/src/data
    ${PROJECT_SOURCE_DIR}/src/gui
)


BISON_TARGET(PARSER src/data/tikzparser.y ${CMAKE_CURRENT_BINARY_DIR}/tikzparser.parser.cpp)
FLEX_TARGET(LEXER src/data/tikzlexer.l
    ${CMAKE_CURRENT_BINARY_DIR}/tikzlexer.lexer.cpp
    # tikzlexer.l fixes this filename relative to Flex's source working
    # directory. Declare it so clean/incremental builds track it correctly.
    DEFINES_FILE ${CMAKE_CURRENT_SOURCE_DIR}/tikzlexer.h
)
ADD_FLEX_BISON_DEPENDENCY(LEXER PARSER)


set(SOURCES
    src/data/delimitedstringvalidator.cpp
    src/data/edge.cpp
    src/data/path.cpp
    src/data/graph.cpp
    src/data/graphelementdata.cpp
    src/data/graphelementproperty.cpp
    src/data/node.cpp
    src/data/pdfdocument.cpp
    src/data/style.cpp
    src/data/stylelist.cpp
    src/data/tikzassembler.cpp
    src/data/tikzdocument.cpp
    src/data/tikzstyles.cpp
    src/gui/commands.cpp
    src/gui/delimitedstringitemdelegate.cpp
    src/gui/edgeitem.cpp
    src/gui/pathitem.cpp
    src/gui/exportdialog.cpp
    src/gui/latexprocess.cpp
    src/gui/mainmenu.cpp
    src/gui/mainwindow.cpp
    src/gui/nodeitem.cpp
    src/gui/preferencedialog.cpp
    src/gui/previewwindow.cpp
    src/gui/propertypalette.cpp
    src/gui/styleeditor.cpp
    src/gui/stylepalette.cpp
    src/gui/tikzscene.cpp
    src/gui/tikzview.cpp
    src/gui/toolpalette.cpp
    src/gui/undocommands.cpp
    src/main.cpp
    src/tikzit.cpp
    src/util.cpp
)

set(HEADERS
    src/data/edge.h
    src/data/path.h
    src/data/graph.h
    src/data/graphelementdata.h
    src/data/graphelementproperty.h
    src/data/node.h
    src/data/pdfdocument.h
    src/data/style.h
    src/data/stylelist.h
    src/data/tikzassembler.h
    src/data/tikzdocument.h
    src/data/tikzparserdefs.h
    src/data/tikzstyles.h
    src/gui/commands.h
    src/gui/delimitedstringitemdelegate.h
    src/gui/edgeitem.h
    src/gui/pathitem.h
    src/gui/exportdialog.h
    src/gui/latexprocess.h
    src/gui/mainmenu.h
    src/gui/mainwindow.h
    src/gui/nodeitem.h
    src/gui/preferencedialog.h
    src/gui/previewwindow.h
    src/gui/propertypalette.h
    src/gui/styleeditor.h
    src/gui/stylepalette.h
    src/gui/tikzscene.h
    src/gui/tikzview.h
    src/gui/toolpalette.h
    src/gui/undocommands.h
    src/tikzit.h
    src/util.h
)

set(FORMS
    src/gui/exportdialog.ui
    src/gui/mainmenu.ui
    src/gui/mainwindow.ui
    src/gui/preferencedialog.ui
    src/gui/previewwindow.ui
    src/gui/propertypalette.ui
    src/gui/styleeditor.ui
    src/gui/stylepalette.ui
)

if (${QT_VER} STREQUAL "Qt6")
    qt6_add_resources(QT_RESOURCES tikzit.qrc)
else()
    qt5_add_resources(QT_RESOURCES tikzit.qrc)
endif()

set(CMAKE_AUTOUIC_SEARCH_PATHS
    "${CMAKE_SOURCE_DIR}/src/gui"
)

set(FORMS
    src/gui/exportdialog.ui
    src/gui/mainmenu.ui
    src/gui/mainwindow.ui
    src/gui/preferencedialog.ui
    src/gui/previewwindow.ui
    src/gui/propertypalette.ui
    src/gui/styleeditor.ui
    src/gui/stylepalette.ui
)

set(CMAKE_BUILD_WITH_INSTALL_RPATH OFF)
set(CMAKE_MACOSX_RPATH OFF)

set(TIKZIT_APP_ICON "${CMAKE_CURRENT_SOURCE_DIR}/images/tikzit.icns")
set_source_files_properties(${TIKZIT_APP_ICON} PROPERTIES
    MACOSX_PACKAGE_LOCATION "Resources"
)

add_executable(tikzit MACOSX_BUNDLE
        ${SOURCES}
        ${HEADERS}
        ${FORMS}
        ${FLEX_LEXER_OUTPUTS}
        ${BISON_PARSER_OUTPUTS}
        ${QT_RESOURCES}
        ${TIKZIT_APP_ICON}
)

set_target_properties(tikzit PROPERTIES
    MACOSX_BUNDLE_ICON_FILE "tikzit.icns"
    MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/Info.plist"
)

target_link_libraries(${PROJECT_NAME}
    "${QT_VER}::Core"
    "${QT_VER}::Gui"
    "${QT_VER}::Widgets"
    "${QT_VER}::Network"
    "${QT_VER}::Pdf"
)

# Keep the non-code project assets next to CLion's build output. Most images
# are also embedded by tikzit.qrc; this copy is useful for packaging and for
# inspecting a complete build tree. The macOS app icon itself is copied into
# tikzit.app/Contents/Resources by MACOSX_PACKAGE_LOCATION above.
add_custom_command(TARGET tikzit POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${CMAKE_CURRENT_SOURCE_DIR}/images"
            "${CMAKE_CURRENT_BINARY_DIR}/images"
    COMMAND ${CMAKE_COMMAND} -E copy_directory
            "${CMAKE_CURRENT_SOURCE_DIR}/share"
            "${CMAKE_CURRENT_BINARY_DIR}/share"
    COMMENT "Copying TikZiT images and shared data to the build directory"
)

install(TARGETS tikzit DESTINATION bin)
