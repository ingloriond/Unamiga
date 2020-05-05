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

char mapKeyToChar( int key ){
  switch(key){
    case KEY_A:    return 'A';
    case KEY_B:    return 'B';
    case KEY_C:    return 'C';
    case KEY_D:    return 'D';
    case KEY_E:    return 'E';
    case KEY_F:    return 'F';
    case KEY_G:    return 'G';
    case KEY_H:    return 'H';
    case KEY_I:    return 'I';
    case KEY_J:    return 'J';
    case KEY_K:    return 'K';
    case KEY_L:    return 'L';
    case KEY_M:    return 'M';
    case KEY_N:    return 'N';
    case KEY_O:    return 'O';
    case KEY_P:    return 'P';
    case KEY_Q:    return 'Q';
    case KEY_R:    return 'R';
    case KEY_S:    return 'S';
    case KEY_T:    return 'T';
    case KEY_U:    return 'U';
    case KEY_V:    return 'V';
    case KEY_W:    return 'W';
    case KEY_X:    return 'X';
    case KEY_Y:    return 'Y';
    case KEY_Z:    return 'Z';
   // case KEY_0:    return '0';
  }
  return '\0'; // not mapped
}
