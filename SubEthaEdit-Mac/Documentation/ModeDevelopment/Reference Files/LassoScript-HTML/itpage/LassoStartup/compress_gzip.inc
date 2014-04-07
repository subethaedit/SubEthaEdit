[//lasso
/*----------------------------------------------------------------------------

[compress_gzip]
Returns a gzipped version of the supplied data.

Author: Fletcher Sandbeck
Last Modified: Jun. 30, 2006
License: Public Domain

Description:
This tag performs Gzip compression on some data and returns the result. Gzip 
compression is similar to the Zlib compression which Lasso's [compress] tag 
returns, but has a different wrapper around the compressed data.
 
 The wrapper starts with a header that includes flags which identify the file 
as including Gzip compression, the date and time the data was compressed, and 
the optional name of the file. This is followed by data compressed using the 
"deflate" algorithm. The wrapper concludes with a 32-bit CRC checksum and the 
original size of the data before compression. These final values are used by 
the decompressor to check that the compressed data wasn't altered in transit.
 
 Lasso's built-in [compress] tag performs Zlib compression which uses the same 
"deflate" algorithm as Gzip compression, but has a different wrapper. In order 
to get the compressed data for the Gzip compression we simply strip the Zlib 
wrapper off the output of the [compress] tag.
 
 The 32-bit CRC checksum for the data is returned using the [Encode_CRC32] tag 
which is implemented natively in Lasso 8.1 and higher.

This tag was created as part of this article: Tip of the Week - Automatic Gzip 
Compression for Lasso 8.1


Sample Usage:
var('zipped') = compress_gzip($data);

Downloaded from tagSwap.net on Jun. 17, 2008.
Latest version available from <http://tagSwap.net/compress_gzip>.

----------------------------------------------------------------------------*/
		

Define_Tag: 'Gzip', -Namespace='Compress_', -Required='data', -Optional='name';
	Local: 'bytes' = Bytes;
	// ID 1 - Fixed value (31)
	#bytes->(Import8Bits: 0x1f);
	// ID 2 - Fixed value (139)
	#bytes->(Import8Bits: 0x8b);
	// CM - Compression Method (8 Deflate)
	#bytes->(Import8Bits: 0x08);
	// FLG - Flags (8 = FNAME, 0 = NONE)
	if: (local_defined: 'name');
		#bytes->(Import8Bits: 0x08);
	else;
		#bytes->(Import8Bits: 0x00);
	/if;
	// MTIME - Compression Time (0 Unavailable)
	Local: 'time' = (integer: date);
	#bytes->(Import8Bits: #time % 256);
	#time = (#time - (#time % 256)) / 256;
	#bytes->(Import8Bits: #time % 256);
	#time = (#time - (#time % 256)) / 256;
	#bytes->(Import8Bits: #time % 256);
	#time = (#time - (#time % 256)) / 256;
	#bytes->(Import8Bits: #time % 256);
	// XFL - Extra Flags (0 None)
	#bytes->(Import8Bits: 0x00);
	// OS - Operating System (255 Unknown)
	#bytes->(Import8Bits: 0xFF);
	// FNAME
	if: (local_defined: 'name');
		#bytes->(importstring: (string_replaceregexp: #name, -find='.*/', -replace=''), 'iso-8859-1');
		#bytes->(import8bits: 0x00);
	/if;
	// DATA
	local: 'temp'= (Compress: #data);
	#bytes += #temp->(getrange: 7, #temp->size - 10);
	// CRC32
	local: 'crc' = (Encode_CRC32: #data);
	#bytes->(Import8Bits: #crc % 256);
	#crc = (#crc - (#crc % 256)) / 256;
	#bytes->(Import8Bits: #crc % 256);
	#crc = (#crc - (#crc % 256)) / 256;
	#bytes->(Import8Bits: #crc % 256);
	#crc = (#crc - (#crc % 256)) / 256;
	#bytes->(Import8Bits: #crc % 256);
	// ISIZE 
	Local: 'size' = #data->size;
	#bytes->(Import8Bits: #size % 256);
	#size = (#size - (#size % 256)) / 256;
	#bytes->(Import8Bits: #size % 256);
	#size = (#size - (#size % 256)) / 256;
	#bytes->(Import8Bits: #size % 256);
	#size = (#size - (#size % 256)) / 256;
	#bytes->(Import8Bits: #size % 256);
	Return: @#bytes;
/Define_Tag;
]
