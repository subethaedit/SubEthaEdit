#import <Foundation/Foundation.h>
#include <stdio.h>
#include "expat.h"

int Eventcnt = 0;
char Buff[8];

void
default_hndl(void *data, const char *s, int len) {
  fwrite(s, len, sizeof(char), stdout);
}  /* End default_hndl */

/****************************************************************
 ** Call from within a handler to print the currently recognized
 ** document fragment. Temporarily set the default handler and then
 ** invoke it via the the XML_DefaultCurrent call.
 */
void
printcurrent(XML_Parser p) {
  XML_SetDefaultHandler(p, default_hndl);
  XML_DefaultCurrent(p);
  XML_SetDefaultHandler(p, (XML_DefaultHandler) 0);
}  /* End printcurrent */

void
start_hndl(void *data, const char *el, const char **attr) {
    printf("\n%4d: Start tag %s - ", Eventcnt++, el);
    int loop;
    int AttributeCount=XML_GetSpecifiedAttributeCount((XML_Parser) data);
    for (loop=0;loop<AttributeCount;loop+=2) {
        printf("\n  Attribute:%s - Value:%s",attr[loop],attr[loop+1]);
    }
//  printcurrent((XML_Parser) data);
}  /* End of start_hndl */


void
end_hndl(void *data, const char *el) {
  printf("\n%4d: End tag %s -\n", Eventcnt++, el);
}  /* End of end_hndl */

void
char_hndl(void *data, const char *txt, int txtlen) {
  printf("\n%4d: Text - ", Eventcnt++);
  fwrite(txt, txtlen, sizeof(char), stdout);
}  /* End char_hndl */

void
proc_hndl(void *data, const char *target, const char *pidata) {
  printf("\n%4d: Processing Instruction - ", Eventcnt++);
  printcurrent((XML_Parser) data);
}  /* End proc_hndl */

void
main(int argc, char **argv) {
  XML_Parser p = XML_ParserCreateNS(NULL,'ö');
  if (! p) {
    fprintf(stderr, "Couldn't allocate memory for parser\n");
    exit(-1);
  }

  XML_UseParserAsHandlerArg(p);
  XML_SetElementHandler(p, start_hndl, end_hndl);
  XML_SetCharacterDataHandler(p, char_hndl);
  XML_SetProcessingInstructionHandler(p, proc_hndl);

  /* Notice that the default handler is not set at this point */

  for (;;) {
    int done;
    int len;
    fgets(Buff, sizeof(Buff), stdin);
    len = strlen(Buff);
    if (ferror(stdin)) {
      fprintf(stderr, "Read error\n");
      exit(-1);
    }
    done = feof(stdin);
    if (! XML_Parse(p, Buff, len, done)) {
      fprintf(stderr, "Parse error at line %d:\n%s\n",
	      XML_GetCurrentLineNumber(p),
	      XML_ErrorString(XML_GetErrorCode(p)));
      exit(-1);
    }

    if (done)
      break;
  }
  printf("\n");
}  /* End main */
