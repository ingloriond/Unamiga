//
// Multicore 2
//
// Copyright (c) 2017-2020 - Victor Trucco
//
// Additional code, debug and fixes: Diogo Patrão
//
// All rights reserved
//
// Redistribution and use in source and synthezised forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
//
// Redistributions in synthesized form must reproduce the above copyright
// notice, this list of conditions and the following disclaimer in the
// documentation and/or other materials provided with the distribution.
//
// Neither the name of the author nor the names of other contributors may
// be used to endorse or promote products derived from this software without
// specific prior written permission.
//
// THIS CODE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//
// You are responsible for any legal issues arising from your use of this code.
//

#ifndef FILESORT_INO
#define FILESORT_INO

/**
 * returns true whether myString ends with any extension within the array extensions (of length totalExtensions)
 */
bool endsWithSome(char* myString, char extensions[MAX_PARSED_EXTENSIONS][MAX_LENGTH_EXTENSION], int totalExtensions) {
  if ( totalExtensions == 0 ) {
    return true;
  }
  for( int i=0;i<totalExtensions;i++ ) {
    if ( endsWith( myString, extensions[i] ) ) {
      return true;
    }
  }
  return false;
}

/**
 * returns true whethen mystring ends with "ending". (case insensitive)
 * 
 * if ending is null, then returns true regardless of what myString is
 */
bool endsWith( char* myString, char* ending ) {
  if ( ending == NULL ) {
    return true;
  }
  int lm = strlen( myString );
  int le = strlen( ending );
  return stricmp( myString+(lm-le),ending )==0;
}

/**
 * a wrapper for strcmp, in order to work with qsort
 */
int mystrcmp( const void* a, const void* b ) {
  if ( ((SPI_Directory*)a)->entry_type == ((SPI_Directory*)b)->entry_type ) {
    return stricmp(((SPI_Directory*)a)->filename,((SPI_Directory*)b)->filename);
  } else {
    if ( ((SPI_Directory*)a)->entry_type > ((SPI_Directory*)b)->entry_type ) {
      return -1;
    } else if ( ((SPI_Directory*)a)->entry_type < ((SPI_Directory*)b)->entry_type ) {
      return 1;
    } else {
      return 0;
    }
  }
}

/**
 * returns a ordered array of files. Directories are always the first entries.
 * only orders up to MAX_SORTED_FILES (due to memory constraints)
 * 
 * if "extension" is null, all files will be returned
 * or else only files ending with the specified extension or directories will be returned.
 */
void sortFiles( SdFat sd, SPI_Directory orderedFiles[MAX_SORTED_FILES], int *totalFiles, char extensions[MAX_PARSED_EXTENSIONS][MAX_LENGTH_EXTENSION], int totalExtensions, bool showDir) {
  SdFile  myEntry;
  int i=0;
  int ct=0; // total of files
  int st=0;
  char filename[FILENAME_LEN]; 
    
  Serial.println("Sorting files");  

  sd.vwd()->rewind(); 

  // if is not root and we have to show directories,
  // the first entry must be ".."
  if ( !sd.vwd()->isRoot() && showDir ) {
    strcpy( orderedFiles[0].filename, ".." );
    orderedFiles[0].entry_type = SPI_Directory::dir ;
    i = 1;
    st = 1;
  }

  // retrieve filtered items
  while (myEntry.openNext(sd.vwd(), O_READ)) 
  { 
    myEntry.getName(filename,FILENAME_LEN);
    
    if ( ( myEntry.isDir() && showDir ) || endsWithSome(filename,extensions,totalExtensions) ) {
      strcpy( orderedFiles[i].filename, filename );
      orderedFiles[i].entry_type = myEntry.isDir() ? SPI_Directory::dir : SPI_Directory::file; //SPI_Directory
      Serial.println(filename);
      i++;  
    } 
    if (i>=MAX_SORTED_FILES) {
      Serial.println("ERROR: more than MAX_SORTED_FILES files in this directory - truncating!");
      break;
    }
    myEntry.close();
  }
  ct = i;

  Serial.print(ct);
  Serial.print(" filtered files and directories found");

  // sort (skipping the first entry ".." if applicable)
  qsort( orderedFiles + st , ct - st, sizeof(SPI_Directory), mystrcmp );
  
  Serial.println("End sorting files");  
  *totalFiles = ct;
}


#endif
