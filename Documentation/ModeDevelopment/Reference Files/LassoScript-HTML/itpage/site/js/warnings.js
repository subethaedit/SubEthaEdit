<!-- 
function confirmDeleteCategory()
{
  return confirm('Caution: This will delete the existing category completely and all underlying information. There is no recovery! Are you sure you want to proceed?');
}
function confirmDeleteContent()
{
  return confirm('Caution: This will delete the content completely. There is no recovery! Are you sure you want to proceed?');
}
function confirmDeleteUser()
{
  return confirm('Caution: This will delete the user completely. There is no recovery! Are you sure you want to proceed?');
}
function confirmDeleteImages()
{
  return confirm('Caution: This will delete this image from the Library. There is no recovery! If it is used in any content pages, the link will be broken. Use the "Check Usage" button to see where it is linked. Are you sure you want to proceed?');
}
function confirmAddCategory()
{
  return confirm('Note: This will add a category or product AFTER the existing entry. Are you sure you want to do that?');
}
function confirmMaint()
{
  return confirm('Do you really want to run this maintenance routine? It may take awhile...');
}
function confirmDeleteFiles()
{
  return confirm('Caution: This will delete all files! Are you sure you want to proceed?');
}
// Functions to close windows when session times out
// Used with permission thanks to Tami Williams, 12/20/07
if (screen) {
	leftPos = screen.width-950;  // increase the number to move right
	}
function openwin(theURL) { 
  popwin = window.open(theURL, 'thiswin' ,'status=no,history=no,resizable=yes,scrollbars=yes,menubar=no,location=no,toolbar=no,width=350,height=450,left='+leftPos+',top=200') // increase top number to move down
	popwin.focus();
}
function openlogoutwin(theURL) { 
	popwin = window.open(theURL, 'thiswin' ,'status=no,history=no,resizable=no,scrollbars=no,menubar=no,location=no,toolbar=no,width=475,height=400left='+leftPos+',top=200') // Increase top number to move down
	popwin.focus();
}
// End  -->
