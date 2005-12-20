/*
 * listcap.c
 *
 * capture history (?@...) sample.
 */
#include <stdio.h>
#include "oniguruma.h"

static int
node_callback(int group, int beg, int end, int level, int at, void* arg)
{
  int i;

  if (at != ONIG_TRAVERSE_CALLBACK_AT_FIRST)
    return -1; /* error */

  /* indent */
  for (i = 0; i < level * 2; i++)
    fputc(' ', stderr);

  fprintf(stderr, "%d: (%d-%d)\n", group, beg, end);
  return 0;
}

extern int ex(unsigned char* str, unsigned char* pattern,
              OnigSyntaxType* syntax)
{
  int r;
  unsigned char *start, *range, *end;
  regex_t* reg;
  OnigErrorInfo einfo;
  OnigRegion *region;

  r = onig_new(&reg, pattern, pattern + strlen(pattern),
	       ONIG_OPTION_DEFAULT, ONIG_ENCODING_ASCII, syntax, &einfo);
  if (r != ONIG_NORMAL) {
    char s[ONIG_MAX_ERROR_MESSAGE_LEN];
    onig_error_code_to_str(s, r, &einfo);
    fprintf(stderr, "ERROR: %s\n", s);
    return -1;
  }

  fprintf(stderr, "number of captures: %d\n", onig_number_of_captures(reg));
  fprintf(stderr, "number of capture histories: %d\n",
          onig_number_of_capture_histories(reg));

  region = onig_region_new();

  end   = str + strlen(str);
  start = str;
  range = end;
  r = onig_search(reg, str, end, start, range, region, ONIG_OPTION_NONE);
  if (r >= 0) {
    int i;

    fprintf(stderr, "match at %d\n", r);
    for (i = 0; i < region->num_regs; i++) {
      fprintf(stderr, "%d: (%d-%d)\n", i, region->beg[i], region->end[i]);
    }
    fprintf(stderr, "\n");

    r = onig_capture_tree_traverse(region, ONIG_TRAVERSE_CALLBACK_AT_FIRST,
                                   node_callback, (void* )0);
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
  return 0;
}


extern int main(int argc, char* argv[])
{
  int r;
  OnigSyntaxType syn;

  static unsigned char* str1 = "((())())";
  static unsigned char* pattern1
    = "\\g<p>(?@<p>\\(\\g<s>\\)){0}(?@<s>(?:\\g<p>)*|){0}";

  static unsigned char* str2     = "x00x00x00";
  static unsigned char* pattern2 = "(?@x(?@\\d+))+";

  static unsigned char* str3     = "0123";
  static unsigned char* pattern3 = "(?@.)(?@.)(?@.)(?@.)";

 /* enable capture hostory */
  onig_copy_syntax(&syn, ONIG_SYNTAX_DEFAULT);
  onig_set_syntax_op2(&syn, 
       onig_get_syntax_op2(&syn) | ONIG_SYN_OP2_ATMARK_CAPTURE_HISTORY);

  r = ex(str1, pattern1, &syn);
  r = ex(str2, pattern2, &syn);
  r = ex(str3, pattern3, &syn);

  onig_end();
  return 0;
}
