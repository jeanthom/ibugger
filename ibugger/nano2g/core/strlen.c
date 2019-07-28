#include <string.h>
#include <limits.h>

size_t strlen(_CONST char *str)
{
  _CONST char *start = str;

  while (*str)
    str++;

  return str - start;
}
