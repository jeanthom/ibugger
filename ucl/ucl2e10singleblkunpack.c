/* uclpack.c -- example program: a simple file packer

   This file is part of the UCL data compression library.

   Copyright (C) 1996-2002 Markus Franz Xaver Johannes Oberhumer
   All Rights Reserved.

   The UCL library is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License as
   published by the Free Software Foundation; either version 2 of
   the License, or (at your option) any later version.

   The UCL library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with the UCL library; see the file COPYING.
   If not, write to the Free Software Foundation, Inc.,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

   Markus F.X.J. Oberhumer
   <markus@oberhumer.com>
 */


/*************************************************************************
// NOTE: this is an example program, so do not use to backup your data
//
// This program lacks things like sophisticated file handling but is
// pretty complete regarding compression - it should provide a good
// starting point for adaption for you applications.
**************************************************************************/

#include <ucl/ucl.h>
#include "lutil.h"

static const char *progname = NULL;

static unsigned long total_in = 0;
static unsigned long total_out = 0;

/* magic file header for compressed files */
static const unsigned char magic[8] =
    { 0x00, 0xe9, 0x55, 0x43, 0x4c, 0xff, 0x01, 0x1a };


/*************************************************************************
// file IO
**************************************************************************/

ucl_uint xread(FILE *f, ucl_voidp buf, ucl_uint len, ucl_bool allow_eof)
{
    ucl_uint l;

    l = ucl_fread(f,buf,len);
    if (l > len)
    {
        fprintf(stderr,"\nsomething's wrong with your C library !!!\n");
        exit(1);
    }
    if (l != len && !allow_eof)
    {
        fprintf(stderr,"\nread error - premature end of file\n");
        exit(1);
    }
    total_in += l;
    return l;
}

ucl_uint xwrite(FILE *f, const ucl_voidp buf, ucl_uint len)
{
    ucl_uint l;

    if (f != NULL)
    {
        l = ucl_fwrite(f,buf,len);
        if (l != len)
        {
            fprintf(stderr,"\nwrite error [%ld %ld]  (disk full ?)\n",
                   (long)len, (long)l);
            exit(1);
        }
    }
    total_out += len;
    return len;
}


int xgetc(FILE *f)
{
    unsigned char c;
    xread(f,(ucl_voidp) &c,1,0);
    return c;
}

void xputc(FILE *f, int c)
{
    unsigned char cc = (unsigned char) c;
    xwrite(f,(const ucl_voidp) &cc,1);
}

/* read and write portable 32-bit integers */

ucl_uint32 xread32(FILE *f)
{
    unsigned char b[4];
    ucl_uint32 v;

    xread(f,b,4,0);
    v  = (ucl_uint32) b[3] <<  0;
    v |= (ucl_uint32) b[2] <<  8;
    v |= (ucl_uint32) b[1] << 16;
    v |= (ucl_uint32) b[0] << 24;
    return v;
}

void xwrite32(FILE *f, ucl_uint32 v)
{
    unsigned char b[4];

    b[3] = (unsigned char) (v >>  0);
    b[2] = (unsigned char) (v >>  8);
    b[1] = (unsigned char) (v >> 16);
    b[0] = (unsigned char) (v >> 24);
    xwrite(f,b,4);
}


/*************************************************************************
// compress
**************************************************************************/

int do_compress(FILE *fi, FILE *fo, ucl_uint size)
{
    int r = 0;
    ucl_byte *in = NULL;
    ucl_byte *out = NULL;
    ucl_uint in_len;
    ucl_uint out_len;
    ucl_uint overhead = 4*size;

    total_in = total_out = 0;

/*
 * Step 1: allocate compression buffers and work-memory
 */
    in = (ucl_byte *) ucl_malloc(size);
    out = (ucl_byte *) ucl_malloc(size + overhead);
    if (in == NULL || out == NULL)
    {
        printf("%s: out of memory\n", progname);
        r = 1;
        goto err;
    }

/*
 * Step 2: compress (single block)
 */
    /* read block */
    in_len = xread(fi,in,size,1);

    r = ucl_nrv2e_decompress_safe_8(in,in_len,out,&out_len,NULL);
    if (r != UCL_E_OK || out_len > in_len + overhead)
    {
        /* this should NEVER happen */
        printf("internal error - decompression failed: %d\n", r);
        r = 2;
        goto err;
    }

    xwrite(fo,out,out_len);

    r = 0;
err:
    ucl_free(out);
    ucl_free(in);
    return r;
}


/*************************************************************************
//
**************************************************************************/

static void usage(void)
{
    printf("usage: %s input-file output-file  (decompress)\n", progname);
    exit(1);
}


/* open input file */
static FILE *xopen_fi(const char *name)
{
    FILE *f;

    f = fopen(name,"rb");
    if (f == NULL)
    {
        printf("%s: cannot open input file %s\n", progname, name);
        exit(1);
    }
#if defined(HAVE_STAT) && defined(S_ISREG)
    {
        struct stat st;
#if defined(HAVE_LSTAT)
        if (lstat(name,&st) != 0 || !S_ISREG(st.st_mode))
#else
        if (stat(name,&st) != 0 || !S_ISREG(st.st_mode))
#endif
        {
            printf("%s: %s is not a regular file\n", progname, name);
            fclose(f);
            exit(1);
        }
    }
#endif
    return f;
}


/* open output file */
static FILE *xopen_fo(const char *name)
{
    FILE *f;

#if 0
    /* this is an example program, so make sure we don't overwrite a file */
    f = fopen(name,"rb");
    if (f != NULL)
    {
        printf("%s: file %s already exists -- not overwritten\n", progname, name);
        fclose(f);
        exit(1);
    }
#endif
    f = fopen(name,"wb");
    if (f == NULL)
    {
        printf("%s: cannot open output file %s\n", progname, name);
        exit(1);
    }
    return f;
}


/*************************************************************************
//
**************************************************************************/

int main(int argc, char *argv[])
{
    int i = 1;
    int r = 0;
    FILE *fi = NULL;
    FILE *fo = NULL;
    const char *in_name = NULL;
    const char *out_name = NULL;
    int size;
    const char *s;

#if defined(__EMX__)
    _response(&argc,&argv);
    _wildcard(&argc,&argv);
#endif
    progname = argv[0];
    for (s = progname; *s; s++)
        if (*s == '/' || *s == '\\')
            progname = s + 1;

    printf("\nUCL real-time data compression library (v%s, %s).\n",
            ucl_version_string(), ucl_version_date());
    printf("Copyright (C) 1996-2002 Markus Franz Xaver Johannes Oberhumer\n\n");

/*
 * Step 1: initialize the UCL library
 */
    if (ucl_init() != UCL_E_OK)
    {
        printf("ucl_init() failed !!!\n");
        exit(1);
    }

    if (i + 2 != argc)
        usage();

/*
 * Step 2: process file(s)
 */
    in_name = argv[i++];
    out_name = argv[i++];
    fi = xopen_fi(in_name);
    fo = xopen_fo(out_name);
    fseek(fi, 0, SEEK_END);
    size = ftell(fi);
    fseek(fi, 0, SEEK_SET);
    r = do_compress(fi,fo,size);
    if (r == 0)
        printf("%s: algorithm NRV2E-99/10-singleblk, decompressed %ld into %ld bytes\n",
                progname, total_in, total_out);

quit:
    if (fi) fclose(fi);
    if (fo) fclose(fo);
    return r;
}
