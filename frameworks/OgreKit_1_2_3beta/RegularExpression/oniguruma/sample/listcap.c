/*
 * listcap.c
 *
 * capture history (?@...) sample.
 */
#include <stdio.h>
#include "oniguruma.h"

extern int main(int argc, char* argv[])
{
  int r;
  unsigned char *start, *range, *end;
  regex_t* reg;
  OnigErrorInfo einfo;
  OnigRegion *region;
  OnigSyntaxType syntax;

#if 0
  static unsigned char* pattern = "(a)(?@.b.)+(DEF)";
  static unsigned char* str = "aabcwbdjbqpbsibvbbbbbbabcbbcpbvbbdbbbbbbDEF";
#endif

  static unsigned char* pattern = "\\g<p>(?@<p>\\(\\g<s>\\)){0}(?<s>(?:\\g<p>)*|){0}";
  static unsigned char* str = "((())())";

  onig_copy_syntax(&syntax, ONIG_SYNTAX_DEFAULT);
  syntax.op2 |= ONIG_SYN_OP2_ATMARK_CAPTURE_HISTORY; /* enable capture hostory */
  r = onig_new(&reg, pattern, pattern + strlen(pattern),
	       ONIG_OPTION_DEFAULT, ONIG_ENCODING_ASCII, &syntax, &einfo);
  if (r != ONIG_NORMAL) {
    char s[ONIG_MAX_ERROR_MESSAGE_LEN];
    onig_error_code_to_str(s, r, &einfo);
    fprintf(stderr, "ERROR: %s\n", s);
    return -1;
  }

  region = onig_region_new();

  end   = str + strlen(str);
  start = str;
  range = end;
  r = onig_search(reg, str, end, start, range, region, ONIG_OPTION_NONE);
  if (r >= 0) {
    int i, j;

    fprintf(stderr, "match at %d\n", r);
    for (i = 0; i < region->num_regs; i++) {
      fprintf(stderr, "%d: (%d-%d)\n", i, region->beg[i], region->end[i]);
    }
    fprintf(stderr, "\n");

    /* capture history */
    for (i = 1; i <= region->num_regs; i++) {
      if (ONIG_IS_CAPTURE_HISTORY_GROUP(region, i)) {
	OnigRegion* caps = region->list[i];
	fprintf(stderr, "%d: %d\n", i, caps->num_regs);
	for (j = 0; j < caps->num_regs; j++) {
	  fprintf(stderr, "  (%d-%d)\n", caps->beg[j], caps->end[j]);
	}
      }
    }
  }
  else if (r == ONIG_MISMATCH) {
    fprintf(stderr, "search fail\n");
  }
  else { /* error */
    char s[ONIG_MAX_ERROR_MESSAGE_LEN];
    onig_error_code_to_str(s, r);
    return -1;
  }

  onig_region_free(region, 1 /* 1:free self, 0:free contents only */);
  onig_free(reg);
  onig_end();
  return 0;
}
