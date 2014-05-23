# generates a Info.plist with soreted known keys + values, removing all others
### needs param:
## xsltproc
## mode_directory
## (plist_result_directory) // maybe for later use - without instead movment of the file?
## mode_plist_suffix
## plist_files
## plist_result_files
###

xslt=SortInfoPlist.xslt

################################################################ Startup
all: header result_plists
result_plists: $(plist_result_files)

header:
	@ echo "########## Sorting Info.plists";

################################################################ Recipe
### generating a InfoPlist with sorted keys + values
# use xslt to generate the new Info.plist
###

$(plist_result_directory)%$(mode_plist_suffix): $(xslt) force
	@ if [ -s $(mode_directory)$*$(mode_plist_suffix) ]; then \
		mkdir -p "$$(dirname $(plist_result_directory)$*$(mode_plist_suffix))"; \
		$(xsltproc) --novalid $(xslt) $(mode_directory)$*$(mode_plist_suffix) > $(plist_result_directory)$*$(mode_plist_suffix); \
		mv $(plist_result_directory)$*$(mode_plist_suffix) $(mode_directory)$*$(mode_plist_suffix); \
		echo "Created sorted Info.plist:\t$*"; \
	else \
		echo "No Mode:\t\t$*"; \
	fi

# This recipe forces the other recipe to happen every time
force:
