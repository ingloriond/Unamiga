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

/**
 * returns the first ocurrence of a filename starting by letter.
 * if not found, go to the next letter; or last entry.
 */
int findFirstByInitial( char letter, int totalFiles, int currentLine, SPI_Directory orderedFiles[MAX_SORTED_FILES] ){
  int selectedMin = 0; 
  int selectedMax = totalFiles;
  int selected;

  int lastDirectory = findLastDirectory( totalFiles, orderedFiles );
  int firstFile = findFirstFile( totalFiles, lastDirectory, orderedFiles );

  if ( orderedFiles[currentLine].entry_type == SPI_Directory::dir ) {
    // if selected entry is a dir, and either its first letter is after the typed letter
    //    OR there is no entry with this letter THEN
    // find in regular files
    if ( toupper(orderedFiles[currentLine].filename[0]) >= letter ) {
      selectedMin = firstFile;
    } else {
      // check next entry with this letter.
      selected = findInIntervalByFirstByInitial(letter,currentLine,lastDirectory,orderedFiles);
      if ( selected < 0 ) {     
        // find in files
        selectedMin = firstFile;
        selectedMax = totalFiles;
      } else {
        return selected;
      }
    }
  } else  if ( orderedFiles[currentLine].entry_type == SPI_Directory::file ) {
    if ( toupper(orderedFiles[currentLine].filename[0]) >= letter ) {
      // find in directories 
      selectedMax = lastDirectory;
    } else {
      // check next entry with this letter.
      selected = findInIntervalByFirstByInitial(letter,currentLine,totalFiles,orderedFiles);
      if ( selected < 0 ) {     
        // find in regular files
        selectedMax = lastDirectory;
      } else {
        return selected;
      }
    }
  }  

  selected = findInIntervalByFirstByInitial(letter,selectedMin,selectedMax,orderedFiles);

  if ( selected>=0 ) {
    return selected;
  } else {
    return currentLine;
  }
}

int findInIntervalByFirstByInitial(char letter, int selectedMin, int selectedMax, SPI_Directory orderedFiles[MAX_SORTED_FILES]) {

  int selected;
  while ( (selectedMin + 1 ) < selectedMax ) {
    Serial.print("Min: ");
    Serial.println(selectedMin);
    Serial.print("Max: ");
    Serial.println(selectedMax);
    selected = (selectedMin + selectedMax ) / 2;
    if ( toupper(orderedFiles[selected].filename[0]) >= letter ) {
      selectedMax = selected;
    } else if ( toupper(orderedFiles[selected].filename[0]) < letter ) {
      selectedMin = selected;
    }
  }
  if ( toupper(orderedFiles[selectedMin].filename[0]) == letter ) {
    return selectedMin;
  }
  if ( toupper(orderedFiles[selectedMax].filename[0]) == letter ) {
    return selectedMax;
  }
  // not found
  return -selectedMin;
}

/**
 * finds the index of the last directory entry in orderedFiles
 * return -1 if there are no directories.
 * assumes that directories are ordered first
 * 
 * TODO make it binary search
 */
int findLastDirectory( int totalFiles, SPI_Directory orderedFiles[MAX_SORTED_FILES] ) {
  int i;
  for( i = 0; i<totalFiles;i++ ) {
    if ( orderedFiles[i].entry_type == SPI_Directory::file ) {
      break;
    }
  }
  return i-1;
}

/**
 * finds the index of the first file entry in orderedFiles
 * return -1 if there are no files
 * assumes that directories are ordered first, then comes the files
 * 
 */
int findFirstFile( int totalFiles, int lastDirectory, SPI_Directory orderedFiles[MAX_SORTED_FILES] ) {
  if ( (lastDirectory+1)==totalFiles ) {
    return -1;
  }
  return lastDirectory+1;
}
