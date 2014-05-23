# generates a Info.plist with changed values
### needs param:
## xsltproc
## mode_directory
## (plist_result_directory) // maybe for later use - without instand movment of the file?
## mode_plist_suffix
## plist_files
## plist_result_files
## key
## to
###

xslt=UpdateInfoPlist.xslt

################################################################ Startup
all: header result_plists
result_plists: $(plist_result_files)

header:
	@ echo "########## Updating Info.plists";

################################################################ Recipe
### generating a InfoPlist with changed values
# use xslt to generate the new Info.plist
###

$(plist_result_directory)%$(mode_plist_suffix): $(xslt) force
	@ if [ -s $(mode_directory)$*$(mode_plist_suffix) ]; then \
		mkdir -p "$$(dirname $(plist_result_directory)$*$(mode_plist_suffix))"; \
		$(xsltproc) --param key "'$(key)'" --param to "'$(to)'" --novalid $(xslt) $(mode_directory)$*$(mode_plist_suffix) > $(plist_result_directory)$*$(mode_plist_suffix); \
		mv $(plist_result_directory)$*$(mode_plist_suffix) $(mode_directory)$*$(mode_plist_suffix); \
		echo "Created changed Info.plist:\t$*"; \
	else \
		echo "No Mode:\t\t$*"; \
	fi

# This recipe forces the other recipe to happen every time
force:
