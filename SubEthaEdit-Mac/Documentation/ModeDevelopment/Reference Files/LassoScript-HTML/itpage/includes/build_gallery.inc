<?Lassoscript
// Last modified 6/22/09 by ECL, Landmann InterActive

// CHANGE NOTES
// 6/22/09
// First implementation

/* ----------------------------------------- */
/* --- BUILD GALLERY ----------------------- */
/* ----------------------------------------- */
Var:'GalleryContent' = (string);

// Initialize vars to display file matrix
Var:'GalleryArray' = array;
Var:'ImageCount' = integer;
Var:'GalleryGroupText' = string;

// Initialize the vars to display the table
// var:'column_limit' = 5;
// var:'column_counter'= 0;

$GalleryContent += '\n<!-- START build_gallery -->\n';
/* SAMLE QUERY
SELECT gal.Gallery_id, gal.Gallery_title, gal.Gallery_caption, gal.Gallery_URL, gal.Gallery_thumb
FROM cms_Gallerygroups AS gg
LEFT JOIN cms_gg2gallery
	USING (gg_groupid)
LEFT JOIN cms_gallery AS gal
	USING (gallery_id)
WHERE
gg.gg_groupid = 12 AND
gg.active = 'Y' AND
gal.active = 'Y'
ORDER BY gal.Gallery_ID
*/
	// The fields gallery_title and gallery_URL currently are not used
	Var:'SQLBuildGallery' = '/* build_gallery - $SQLBuildGallery */
		SELECT gal.gallery_id, gal.gallery_title, gal.gallery_caption, gal.gallery_URL, gal.gallery_thumb,
			 gg.gg_text AS GalleryGroupText
		FROM ' $svGalleryGroupsTable ' AS gg
		LEFT JOIN ' $svGG2GalleryTable '
			USING (gg_groupid)
		LEFT JOIN ' $svGalleryTable ' AS gal
			USING (gallery_id)
		WHERE
		gg.gg_groupid = ' $vGalleryGroupID ' AND
		gg.active = "Y" AND
		gal.active = "Y"
		ORDER BY gal.gallery_ID';
	
	Inline: $IV_Galleries, -SQL=$SQLBuildGallery;

		$ImageCount = ($GalleryArray->size);

		Records;

			// Put items into a map.
			// GalleryGroupText will be the same for every record as it is associated with the entire gallery
			$GalleryArray->insert(map(
				'gallery_id' = (Field:'gallery_id'),
				'filename' = (Field:'gallery_thumb'),
				'ImageAlt' = (Field:'gallery_caption'),
				'ImageCaption' = (Field:'gallery_caption'),
				'GalleryGroupText' = (Field:'GalleryGroupText')));

		/Records;		

		Debug;
			$GalleryContent += '<p class="debug">45: SQLBuildGallery = ' ($SQLBuildGallery) '<br>\n';
			$GalleryContent += '45: Found_Count = ' (Found_Count) '</p>\n';
			$GalleryContent += '<p class="debug">65: GalleryArray = ' ($GalleryArray) '</p>\n';
		/Debug;

	/Inline;

// END container for right navbar
$GalleryContent += '<!-- END build_gallery -->\n';

?>
