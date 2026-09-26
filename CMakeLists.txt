cmake_minimum_required(VERSION 3.16)

# Die Anwendung liegt in src/ - das ist KEIN Standard-Komponentenordner von
# ESP-IDF. Ohne diese Zeile wird src/main.c nie gebaut und der Linker meldet
# "undefined reference to app_main". Muss vor project.cmake stehen.
set(EXTRA_COMPONENT_DIRS ${CMAKE_CURRENT_SOURCE_DIR}/src)

# WICHTIG: project.cmake MUSS vor project() eingebunden werden. Steht project()
# davor, kennt CMake die ESP-IDF-Toolchain noch nicht und bricht ab mit
# "No CMAKE_C_COMPILER could be found".
include($ENV{IDF_PATH}/tools/cmake/project.cmake)

project(${PROJECT_NAME})
