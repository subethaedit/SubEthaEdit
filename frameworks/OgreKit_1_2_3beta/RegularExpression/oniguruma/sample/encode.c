/*
 * encode.c
 */
#include <stdio.h>
#include "oniguruma.h"

static int exec(OnigEncoding enc, OnigOptionType options,
		unsigned char* pattern, unsigned char* str)
{
  int r;
  unsigned char *start, *range, *end;
  regex_t* reg;
  OnigErrorInfo einfo;
  OnigRegion *region;

  r = onig_new(&reg, pattern, pattern + strlen(pattern),
		options, enc, ONIG_SYNTAX_DEFAULT, &einfo);
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
    int i;

    fprintf(stderr, "match at %d\n", r);
    for (i = 0; i < region->num_regs; i++) {
      fprintf(stderr, "%d: (%d-%d)\n", i, region->beg[i], region->end[i]);
    }
  }
  else if (r == ONIG_MISMATCH) {
    fprintf(stderr, "search fail\n");
  }
  else { /* error */
    char s[ONIG_MAX_ERROR_MESSAGE_LEN];
    onig_error_code_to_str(s, r);
    fprintf(stderr, "ERROR: %s\n", s);
    return -1;
  }

  onig_region_free(region, 1 /* 1:free self, 0:free contents only */);
  onig_free(reg);
  onig_end();
  return 0;
}

extern int main(int argc, char* argv[])
{
  int r;

  /* ISO 8859-1 test */
  static unsigned char str[] = { 0xc7, 0xd6, 0xfe, 0xea, 0xe0, 0xe2, 0x00 };
  static unsigned char pattern[] = { 0xe7, 0xf6, 0xde, '\\', 'w', '+', 0x00 };

  r = exec(ONIG_ENCODING_KOI8,   ONIG_OPTION_NONE, "a+", "bbbaaaccc");
  r = exec(ONIG_ENCODING_KOI8_R, ONIG_OPTION_NONE, "a+", "bbbaaaccc");
  r = exec(ONIG_ENCODING_BIG5,   ONIG_OPTION_NONE, "a+", "bbbaaaccc");
  r = exec(ONIG_ENCODING_EUC_TW, ONIG_OPTION_NONE, "b*a+?c+", "bbbaaaccc");
  r = exec(ONIG_ENCODING_EUC_KR, ONIG_OPTION_NONE, "a+", "bbbaaaccc");
  r = exec(ONIG_ENCODING_EUC_CN, ONIG_OPTION_NONE, "c+", "bbbaaaccc");
  r = exec(ONIG_ENCODING_ISO_8859_2, ONIG_OPTION_IGNORECASE,
	   "[ac]+", "bbbaAaCCC");
  r = exec(ONIG_ENCODING_ISO_8859_3, ONIG_OPTION_IGNORECASE,
	   "[ac]+", "bbbaAaCCC");
  r = exec(ONIG_ENCODING_ISO_8859_4, ONIG_OPTION_IGNORECASE,
	   "[ac]+", "bbbaAaCCC");
  r = exec(ONIG_ENCODING_ISO_8859_5, ONIG_OPTION_IGNORECASE,
	   "[ac]+", "bbbaAaCCC");
  r = exec(ONIG_ENCODING_ISO_8859_6, ONIG_OPTION_IGNORECASE,
	   "[ac]+", "bbbaAaCCC");
  r = exec(ONIG_ENCODING_ISO_8859_7, ONIG_OPTION_IGNORECASE,
	   "[ac]+", "bbbaAaCCC");
  r = exec(ONIG_ENCODING_ISO_8859_8, ONIG_OPTION_IGNORECASE,
	   "[ac]+", "bbbaAaCCC");
  r = exec(ONIG_ENCODING_ISO_8859_9, ONIG_OPTION_IGNORECASE,
	   "[ac]+", "bbbaAaCCC");
  r = exec(ONIG_ENCODING_ISO_8859_10, ONIG_OPTION_IGNORECASE,
	   "[ac]+", "bbbaAaCCC");
  r = exec(ONIG_ENCODING_ISO_8859_11, ONIG_OPTION_IGNORECASE,
	   "[ac]+", "bbbaAaCCC");
  r = exec(ONIG_ENCODING_ISO_8859_13, ONIG_OPTION_IGNORECASE,
	   "[ac]+", "bbbaAaCCC");
  r = exec(ONIG_ENCODING_ISO_8859_14, ONIG_OPTION_IGNORECASE,
	   "[ac]+", "bbbaAaCCC");

  r = exec(ONIG_ENCODING_ISO_8859_15, ONIG_OPTION_IGNORECASE, pattern, str);
  r = exec(ONIG_ENCODING_ISO_8859_16, ONIG_OPTION_IGNORECASE, pattern, str);

  r = exec(ONIG_ENCODING_ISO_8859_1, ONIG_OPTION_IGNORECASE,
	   "SSb\337ssc", "a\337bSS\337cd");

  r = exec(ONIG_ENCODING_ISO_8859_1, ONIG_OPTION_IGNORECASE,
	   "[a\337]{0,2}", "aSS");

  return 0;
}
