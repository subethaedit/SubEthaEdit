#this CMakeLists.txt doesn't do anything useful, but it shoudl demonstrate the cmake syntax highlighting
#Alexander Neundorf <neundorf@kde.org>

#ok this is a comment
#and another line
#a built-in command, it's bold black
ADD_DEFINITIONS(-Wall -Wctor-dtor-privacy -Woverloaded-virtual -Wno-long-long -pipe -fno-builtin -fno-exceptions)

#and another function
INCLUDE_DIRECTORIES(
#comments are also highlighted inside function parameters
#variables are Qt::blue
${CMAKE_CURRENT_SOURCE_DIR}/../../lib/qt4/include/Qt  
)

# BEGIN defining a macro
MACRO(ECOS_ADD_EXECUTABLE _exe_NAME )

#special parameters are italic, see the STATIC in the next line
ADD_LIBRARY(${_exe_NAME} STATIC ${ARGN})
#but not in the following line ?
  ADD_LIBRARY(${_exe_NAME} STATIC ${ARGN})
# it seems the kate highlighting file could need some love, Alex


#another command with a bunch of variables and special parameters   
   ADD_CUSTOM_COMMAND(
      TARGET ${_exe_NAME} 
      PRE_LINK 
      COMMAND ${CMAKE_C_COMPILER} 
      ARGS -o ${_exe_NAME} 
$\(${_exe_NAME}_SRC_OBJS\) -nostdlib  -nostartfiles -Lecos/install/lib -Ttarget.ld
   )

#add the created files to the make_clean_files
   SET(ECOS_ADD_MAKE_CLEAN_FILES ${ECOS_ADD_MAKE_CLEAN_FILES};${_exe_NAME};)
#and another command...   
   SET_DIRECTORY_PROPERTIES( 
      PROPERTIES
      ADDITIONAL_MAKE_CLEAN_FILES "${ECOS_ADD_MAKE_CLEAN_FILES}"
   )
ENDMACRO(ECOS_ADD_EXECUTABLE)
# END of macro

#calling a self-defined function, variables are also Qt::blue here
ECOS_ADD_EXECUTABLE(${PROJECT_NAME} ${the_sources} ${qt4_moc_SRCS})



