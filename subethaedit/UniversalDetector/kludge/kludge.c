#include "prmem.h" // nose core nose core nose core nose core

PR_IMPLEMENT(void *) PR_Malloc(PRUint32 size)
{
    return malloc(size);
}

PR_IMPLEMENT(void *) PR_Calloc(PRUint32 nelem, PRUint32 elsize)
{
    return calloc(nelem, elsize);
}

PR_IMPLEMENT(void *) PR_Realloc(void *ptr, PRUint32 size)
{
    return realloc(ptr, size);
}

PR_IMPLEMENT(void) PR_Free(void *ptr)
{
    free(ptr);
}
