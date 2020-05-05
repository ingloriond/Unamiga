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

#include "SdFat.h"
#include <SPI.h>
#include <Wire.h>

const unsigned char version[4] = "108"; // v 1.08

// the OSD screen width in chars
#define SCREEN_WIDTH_IN_CHARS 32

//  the OSX screen height in chars
#define MENU_MAX_LINES 8

// the keycodes produced by the core (lower 5bits)
#define KEY_UP  30
#define KEY_DOW 29
#define KEY_LFT 27 
#define KEY_RGT 23 
#define KEY_RET 15
#define KEY_NOTHING 31
#define KEY_A   0  
#define KEY_B   1   
#define KEY_C   2   
#define KEY_D   3  
#define KEY_E   4   
#define KEY_F   5   
#define KEY_G   6  
#define KEY_H   7  
#define KEY_I   8  
#define KEY_J   9   
#define KEY_K   10  
#define KEY_L   11  
#define KEY_M   12  
#define KEY_N   13  
#define KEY_O   14 
#define KEY_P   16  
#define KEY_Q   17  
#define KEY_R   18 
#define KEY_S   19  
#define KEY_T   20  
#define KEY_U   21 
#define KEY_V   22
#define KEY_W   24  
#define KEY_X   25  
#define KEY_Y   26  
#define KEY_Z   28 
 
//#define KEY_0   95  

// events produced by the core
#define EVENT_NOTHING 0
#define EVENT_KEYPRESS 1

unsigned char core_mod = 0;

// the maximum number of files per directory that can be sorted (the limit is the available memory)
#define MAX_SORTED_FILES 128

// the filename length
#define FILENAME_LEN 64

// the maximum of extensions that can be parsed (separated by "/") (context: filtering files in navigateMenu)
#define MAX_PARSED_EXTENSIONS 10 

// the maximum length of extensions (including ".")
#define MAX_LENGTH_EXTENSION 5



// one entry in a directory (may be either a file or directory)
struct SPI_Directory {
  char filename[FILENAME_LEN];
  enum entry_type { none=0,file=1, dir=2} entry_type;
};



const int TCKpin = PB0;   
const int TDIpin = PB1;    
const int TMSpin = PB10;   
const int TDOpin = PB11; //input  

const int CS_SDCARDpin  = PA4; 
const int LEDpin = PC13;  
unsigned char transfer_index =0;

char core_name[32];
char dat_name[32];

SdFat sd1(1);

SdFile  file;
SdFile  entry;

//bool SD_ok = false;
bool CORE_ok = true;

char sd_buffer[1024];
unsigned char ret;

unsigned long menu_opened;


unsigned char option_sel[32] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
unsigned char option_num[32] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};

unsigned char key;
unsigned char cmd;
unsigned char last_key = 31; //only the 5 lower bit are keys
unsigned char last_cmd = 1;
    
unsigned char last_ret;
unsigned char cur_select = 0;

char file_selected[64];

    
#define START_PIN  PA8
#define nWAITpin  PA15

#define NSS_PIN  PB12
#define NSS_SET ( GPIOB->regs->BSRR = (1U << 12) )
#define NSS_CLEAR ( GPIOB->regs->BRR = (1U << 12) )


// TODO: TRY TO USE endsWith, defined in fileSort (should it be there??)
bool isExtension(char* filename, char* extension) 
{
    int8_t len = strlen(filename);
    char ext[5];
    char file[64];
    bool result;
    char temp[64];
    char *token;
       
    strcpy(file, filename);  
    strcpy(temp, extension);  
        
    token = strtok(temp,"/");
    
    while(token)
    {
        strcpy(ext, token);  

        // Serial.print ("isExtension:");
        // Serial.println (token);
            
        if ( strstr(strlwr(file + (len - 4)), strlwr(ext)) ) 
        {
          return true;
        } 
       
        
        token = strtok(NULL,"/");
    }
    
    return false;
}

unsigned char codeToNumber (unsigned char code)
{
    if (code >= '0' && code <= '9') return code-48;
    if (code >= 'A' && code <= 'Z') return code-55;

    return code;
}


bool navigateOptions()
{
       //char sd_buffer[1024] {          "S,PRG,Load *.PRG;S,TAP/TZX,Load *.TAP;TC,Play/Stop TAP;OG,Menos sound,Off,On;OH,Mais sound,Off,On;OD,Tape sound,Off,On;O3,Video,PAL,NTSC;O2,CRT with load address,Yes,No;OAB,Scanlines,Off,25%,50%,75%;O45,Enable 8K+ Expansion,Off,8K,16K,24K;O6,Enable 3K Expansion,Off,On;O78,Enable 8k ROM,Off,RO,RW;O9,Audio Filter,On,Off;T0,Reset;T1,Reset with cart unload;." };
      
      int ini = 0;
      int fim=0;
      int cur_line = 0;
      int page = 0;
      int i,j,k;
      int opt_sel =0;
      int total_options = 0;
      int total_show = 0;
      int last_page = 0;

      int event; // keyboard events

      char exts[32];
      char ext[5];

       OsdClear();
      //show the menu to navigate
      OSDVisible(true);
      
      cur_select=0;
      
      while(1)
      {
     



      ini = 0;
      fim = 0;
      opt_sel =0;
      cur_line=0;
      total_options = 0;
      total_show = 0;
      
      while (ini < strlen(sd_buffer))
      {
            for (i=ini; i<strlen(sd_buffer);i++)
            {
                if (sd_buffer[i]==';') 
                {
                    fim = i;
                    break;
                } 
                else
                {
                    fim=strlen(sd_buffer);
                }
            }
        
          
            char temp[128];
            strncpy(temp, sd_buffer + ini, fim-ini);
            temp[fim-ini] = '\0';
            
            ini = fim+1;
            
            Serial.print ("linha:");
            Serial.println (temp);
       
            char *token; 
            token = strtok(temp, ",");

         

            char line[32] = {"                               "};

            if (token[0] == 'S') //it's a LOAD option
            {        
                unsigned char s_index;
                
                if (token[1] != ',') {
                  s_index = codeToNumber(token[1]);
                } else {
                  s_index = 1; //default to "drive 1"
                }
                
                token = strtok(NULL, ",");
            
                if (cur_select==cur_line) 
                {
                  // strcpy(ext,".");
                //   strcat(ext,token); 

                   strcpy(exts, token);
                }
                
                token = strtok(NULL, ",");
                strcpy(line,token);
                line[32] = '\0';
                
                total_options++;

                option_num[opt_sel] = 99;
                option_sel[opt_sel] = s_index; 
                
                if (cur_line >= page*8 && total_show <= 8)
                {
                    OsdWriteOffset(cur_line - (page*8), line, (cur_select==cur_line) , 0, 0, 0);
                    total_show++;
                }
                    
                cur_line++;
                opt_sel++;
            }   
            
            if (token[0] == 'T') //it's an toggle option
            {
                int num_op_token = codeToNumber(token[1]);
                
                token = strtok(NULL, ",");
                strcpy(line,token);
                line[32] = '\0';
                
                total_options++;;

                option_num[opt_sel] = 1;
                option_sel[opt_sel] = (num_op_token<<3); 
                
                if (cur_line >= page*8 && total_show <= 8)
                {
                    OsdWriteOffset(cur_line - (page*8), line, (cur_select==cur_line) , 0, 0, 0);
                    total_show++;
                }
                    
                cur_line++;
                opt_sel++;
            }      
           
            if (token[0] == 'O') //it's an Option for menu
            {

                int num_op_token = codeToNumber(token[1]);
                
                token = strtok(NULL, ",");
                
                for (j=0; j<strlen(token);j++)
                {
                    line[j] = token[j];
                }
                line[j++] = ':';
                line[32] = '\0';
                
                token = strtok(NULL, ",");
                total_options++;;
                unsigned char opt_counter = 0;
                 
                while (token)
                {
                    if ((option_sel[opt_sel] & 0x07) == opt_counter)
                    {
                        for (k=0; k<strlen(token); k++)
                        {
                            line[31-strlen(token)+k] = token[k];
                        }
                      
                    }

                     // Serial.print ("token2 option:");
                    //  Serial.println (token);
                      token = strtok(NULL, ",");
                      
                      opt_counter++;
                      option_num[opt_sel] = opt_counter;
                      option_sel[opt_sel] = (num_op_token<<3) | (option_sel[opt_sel] & 0x07); 
                }
                
             // Serial.print ("opt[");
           //   Serial.print (opt_sel);
            //  Serial.print ("] = ");
            //  Serial.println (opt[opt_sel], BIN);
                  
                if (cur_line >= page*8 && total_show <= 8)
                {
                    OsdWriteOffset(cur_line - (page*8), line, (cur_select==cur_line) , 0, 0, 0);
                    total_show++;
                }
                
                cur_line++;
                opt_sel++;
  
            }
        
        }
        // erase unused lines
        while( total_show < MENU_MAX_LINES ) {
          
          OsdWriteOffset( total_show, "                                ", 0, 0,0,0 );
          total_show++;
        }

      
        // set second SPI on PA12-PA15
        SPI.setModule(2);
        NSS_SET; // ensure SS stays high for now

        Serial.println("Waiting keys! 1");
        
        NSS_CLEAR;
        key = SPI.transfer(0x10); //command to read from ps2 keyboad


        Serial.print("last key");

        Serial.print(last_cmd);
        Serial.print(":");
        Serial.println(last_key);
               
        
        // read keyboard and act
        event = readKeyboard(&key,&cmd);
  
        if ( event == EVENT_KEYPRESS ) {
          Serial.println("Key received 1");
  
          if (key == 30) //up
          {
            if (cur_select > 0) cur_select--;
  
             if (cur_select < page*8) 
             {
                cur_select = page*8 - 1;
                page--;
             }
          }
          else if (key == 29) //down
          {
             if (cur_select < total_options-1) cur_select++; 
  
             if (cur_select > ((page+1)*8)-1) page++;
          }
          else if (key == 27) //left
          {
             if (page > 0) page--;  
          }
          else if (key == 23) //right
          {
             if (page < ((total_options-1)/8)) page++; 
          }
          else if (key == 15) //enter
          {
              if (option_num[cur_select] == 99)
              {  
                  transfer_index = option_sel[cur_select];
                  OsdClear();
                  //Serial.print(ext);Serial.println("-----------------------------");
                  if (navigateMenu(exts, true, false,false,true))
                        {
                            
                            NSS_SET; //slave deselected
            
                            NSS_CLEAR; //slave selected
                            
                            Serial.println("we will execute a data pump 3!");     
                            dataPump();
  
                            OSDVisible(false);
                            last_cmd = 1;
                            last_key = 31;
                            return(true);
                        }
              }
              else
              {
                  option_sel[cur_select]++;
                  
                  if ((option_sel[cur_select] & 0x07) == (option_num[cur_select]) && option_num[cur_select] > 1) 
                      option_sel[cur_select] = 0; 
              }
          }
          else if ((cmd == 0x01 || cmd == 0x02 || cmd == 0x03)) //F12 - abort
          {
  
              if (menu_opened + 1000 < millis())
                  return false;  
          }
  
          if (page != last_page)
          {
              last_page = page;
              if (key !=30) cur_select = page*8;
              OsdClear();
          }
        }

/*
        Serial.print("option_num ");
        for (int j=0; j<32; j++)
        {
          Serial.print (option_num[j]);
           Serial.print(",");
        }
        Serial.println(" ");

         Serial.print("option_sel ");
        for (int j=0; j<32; j++)
        {
          Serial.print (option_sel[j]&0x07);
          Serial.print(",");
        }
        Serial.println(" ");

        Serial.print("option_sel ");
        for (int j=0; j<32; j++)
        {
          Serial.print (option_sel[j]);
          Serial.print(",");
        }
        Serial.println(" ");
  */
        SendStatusWord();
        
       
        
      }

       
    
}

void SendStatusWord (void)
{
    //generate the Status Word
    unsigned int statusWord = 0;
    for (int j=0; j<32; j++)
    {
    
      statusWord += (option_sel[j]&0x07)<<(option_sel[j]>>3);
      
    
    }
    
    Serial.print("statusWord ");
    Serial.println(statusWord, BIN);
    NSS_CLEAR;
    spi_osd_cmd_cont(0x15); //cmd to send the status data
    spi32(statusWord);
    spi8(core_mod);
    NSS_SET;
}


/**
 * This is the core selection menu
 * 
 * arguments:
 * ----------
 * 
 * char *extension => string with preferred file extension for cores (separated by "/", no ".")
 * bool canAbort => allow aborting by pressing F12?
 * bool filter => shows only files matching the extension(s)?
 * bool showDir => shows directories?
 * bool showExtensions => shows the file extensions?
 * 
 * return value
 * ------------
 * 
 * bool => true     when a core is selected (also sets the global file_selected, needed elsewhere)
 *      => false    when user request abort (pressed F12)
 */
bool navigateMenu( char* extension, bool canAbort, bool filter, bool showDir, bool showExtensions ) 
{
    int index=0;
    int event;
    unsigned char total_files = 0;
    unsigned char page = 0;
    unsigned char last_page = 0;
    bool selected = false;
    bool showfile = false;
    bool isDir = false;
    bool isSelectedDir = false;
    bool insideDir = false;

    int idleTime = millis();

    char ext[5];
    char extensions[MAX_PARSED_EXTENSIONS][MAX_LENGTH_EXTENSION]; // filtered extensions, with "."

    unsigned char cur_line = 0;

    unsigned char total_show = 0;

    showDir = true;

    cur_select=0;

    Serial.print("navigateMenu - extension: ");
    Serial.print(extension);
    Serial.print("| canAbort ");
    Serial.print(canAbort?"true":"false");
    Serial.print("| filter ");
    Serial.print(filter?"true":"false");
    Serial.print("| showDir");
    Serial.print(showDir?"true":"false");
    Serial.print("| showExtensions ");
    Serial.println(showExtensions?"true":"false");

    // prepare extensions
    int totalExtensions;
    prepareExtensions(extension,extensions,&totalExtensions);

    // sort files (TODO check configuration/file limit to avoid slowness)
    int totalFiles = 0;
    SPI_Directory orderedFiles[MAX_SORTED_FILES];
    sortFiles( sd1, orderedFiles, &totalFiles, extensions, totalExtensions, showDir );

    // if totalFIles is exactly MAX_SORTED_FILES, then some files may be not shown. Let's inform the user
    if ( totalFiles == MAX_SORTED_FILES ) {
      char errorMsg[33];
      sprintf(errorMsg,">= %d files in root directory.",MAX_SORTED_FILES);
      errorScreen( errorMsg );
      waitKeyPress();
    }

    int currentPage = 0;
    int currentLine = 0;
    int rolling_offset = 0;
    while (!selected)
    {
      int j;
      // show currentPage of results (MENU_MAX_LINES)
      for(j=0;j<MENU_MAX_LINES;j++) {
        if ( (j+currentPage*MENU_MAX_LINES) < totalFiles ) {
          int k;
          char temp_filename[64];
          SPI_Directory *d = &(orderedFiles[j+currentPage*MENU_MAX_LINES]);
          
          // skips one byte if its a dir so I can put <> around the dirname
          if ( d->entry_type == SPI_Directory::dir ) {
            strcpy( temp_filename+1, d->filename ); 
            temp_filename[0] = '<';
            temp_filename[strlen(temp_filename)] = '>';
            k = strlen( d->filename )+2;
          } else {
            strcpy( temp_filename, d->filename ); 
            k = strlen( d->filename );

            // remove filename extension (WARNING: WORKS ONLY WITH ONE EXTENSION)
            if ( endsWith( temp_filename, extension ) && !showExtensions && totalExtensions==1) {
              k -= strlen(extensions[0]);
            }

          }
          // pad rest of string with spaces (in order to erase garbage from previous screen)
          for(;k<31;k++ ) {
            temp_filename[k] = ' ';
          }
          temp_filename[k] = '\0';



          if ( j != (currentLine%MENU_MAX_LINES) ) {
            OsdWriteOffset( j, temp_filename, 0, 0,0,0 );           
          } else {

            // do not roll files that fit the screen 
            if ( strlen(temp_filename)< SCREEN_WIDTH_IN_CHARS ) {
              rolling_offset = 0;
            } else {

              // if rolled all the way to the end of string, stop, wait 2sec and start again
              if ( rolling_offset + 32 > strlen(temp_filename)  ) {                
                if ( (millis()-idleTime) > 2000 ) {
                  idleTime = millis();
                  rolling_offset = 0;
                }
              } else
              // if at start of string, wait 2sec to start rolling, then go 1 char each 0.2sec
              if ( ( rolling_offset == 0 && (millis()-idleTime) > 2000 ) || ( rolling_offset > 0 && (millis()-idleTime) > 200) ) {                 
                idleTime = millis();
                rolling_offset++;
              }
            }
            OsdWriteOffset( j, temp_filename+rolling_offset, 1, 0,0,0 );
          }

        } else {
          OsdWriteOffset( j, "", 0,0,0,0 ); // erase lines without files
        }
      }

      // read keyboard and act
      event = readKeyboard(&key,&cmd);

      if ( event == EVENT_KEYPRESS ) {
        idleTime = millis();
        rolling_offset = 0;
        switch(key){
          case KEY_UP: // up
            currentLine --;
            if ( currentLine < 0 ) {
              currentLine = totalFiles - 1;
            }
            break;
          case KEY_DOW: // down
            currentLine ++;
            if ( currentLine >= totalFiles ) {
              currentLine = 0;
            }
            break;          
          case KEY_LFT: // left
            currentLine -= MENU_MAX_LINES;
            if ( currentLine < 0 ) {
              currentLine = totalFiles + currentLine ;
            }
            break;
          case KEY_RGT: // right
            currentLine += MENU_MAX_LINES;
            if ( currentLine >= totalFiles ) {
              currentLine -= totalFiles;
            }
            break;          
            
          case KEY_A:
          case KEY_B:
          case KEY_C:
          case KEY_D:
          case KEY_E:
          case KEY_F:
          case KEY_G:
          case KEY_H:
          case KEY_I:
          case KEY_J:
          case KEY_K:
          case KEY_L:
          case KEY_M:
          case KEY_N:
          case KEY_O:
          case KEY_P:
          case KEY_Q:
          case KEY_R:
          case KEY_S:
          case KEY_T:
          case KEY_U:
          case KEY_V:
          case KEY_W:
          case KEY_X:
          case KEY_Y:
          case KEY_Z:
          //case KEY_0:
            currentLine = findFirstByInitial( mapKeyToChar(key), totalFiles, currentLine, orderedFiles );
            break;
            
          case KEY_RET: // enter
            Serial.print("Pressed enter... ");
            Serial.print(orderedFiles[currentLine].entry_type);
            Serial.println(" yep");
            
            if ( orderedFiles[currentLine].entry_type == SPI_Directory::dir ) { 
              
              Serial.print("Changing to directory ");
              Serial.println(orderedFiles[currentLine].filename);
              if ( strcmp( orderedFiles[currentLine].filename, ".." ) == 0 ) {
                sd1.chdir();
              } else {
                sd1.chdir(orderedFiles[currentLine].filename);
              }
                        
              // retrieve files from this dir
              totalFiles = 0;
              sortFiles( sd1, orderedFiles, &totalFiles, extensions, totalExtensions, showDir );
  
              // if totalFIles is exactly MAX_SORTED_FILES, then some files may be not shown. Let's inform the user
              if ( totalFiles == MAX_SORTED_FILES ) {
                char errorMsg[33];
                sprintf(errorMsg,">= %d files in this directory.",MAX_SORTED_FILES);
                errorScreen( errorMsg );
                waitKeyPress();
              }
              
              currentPage = 0;
              currentLine = 0;
              
            } else {
              // not a dir; then it is a file
              selected=true; // TODO after putting "return true" here, this can be removed I guess
              strcpy( file_selected, orderedFiles[currentLine].filename );
              return true;
            }
              break;
            case KEY_NOTHING: // nothing was pressed
              break;
            default:
             

              Serial.print("Unrecognized key pressed: ");
              Serial.println(key);
              break;
        }

         if ((cmd == 0x01 || cmd == 0x02 || cmd == 0x03) && canAbort) { //F12 - abort
                  Serial.println("Aborting");
                  return false;  
              }
              
        // recalculate page
        if ( currentPage != currentLine / MENU_MAX_LINES ) {
          currentPage = currentLine / MENU_MAX_LINES;
          OsdClear();
        }
      }
      
    }    
}

void waitACK (void)
{
   //----------------------------------------------------
      // set second SPI on PA12-PA15
      SPI.setModule(2);
      NSS_SET; // ensure SS stays high for now
      //syncronize and clear the SPI buffers
   
 //     Serial.println ("waitACK");
      
      while (ret != 'K') //wait for command acknoledge
      {
          NSS_CLEAR;  
          ret = SPI.transfer(0); //clear the SPI buffers
          delay(100); //wait a little to receive the last bit
          NSS_SET; // ensure SS stays high for now
           
          if (last_ret !=ret)
          {
            last_ret = ret;
           
          }
          
      //    Serial.print ("\n");
      //      Serial.print (ret);
      //      Serial.print ("=");
       //     Serial.print ((char)ret);
            
      }
   
      SPI.setModule(1);
      //----------------------------------------------------
}


void waitSlaveCommand (void)
{
      unsigned char cmd;
      unsigned int char_count = 0;

      // Serial.println("\nwaitSlaveCommand");
       
      //----------------------------------------------------
      // set second SPI on PA12-PA15
      SPI.setModule(2);
      NSS_SET;
      
      NSS_CLEAR;  //SS clear to send a comand
      ret = SPI.transfer(0x10); //read data from slave
          
      while (1) //wait for commands
      {

            cmd = SPI.transfer(0x00); //Dummy data, just to get the response 
            
           //       Serial.print ("\n cmd: ");
          //  Serial.println (cmd, BIN);
            
            cmd = (cmd & 0xe0) >> 5; //just the 3 msb are the command



            if (cmd == 0x01 || cmd == 0x02  || cmd == 0x03)
            {
  

                 char_count = 0;

                 OsdClear();
                 EnableOsdSPI();

               
                  
                //let's ask if we need a specific file or need to show the menu
                ret = SPI.transfer(0x14); // command 0x14 - get STR_CONFIG
                
                while(ret != 0)
                {
                   // delay(50);
                    ret = SPI.transfer(0x00); //get one char at time
                   
                    sd_buffer[char_count] = ret; //use the sd_buffer as a general buffer
                    
                //    Serial.print ("\n command 0x14 reply:");
                    //Serial.print (ret);
                 //  Serial.print ("=");
                    Serial.print ((char)ret);
                    char_count++;
                    
                }
                Serial.println (" ");


               // read an external ".INI", if exists
          
                //strcpy(core_name,"robotron"); //debug
                strcpy(file_selected,core_name);
                strcat(file_selected,".ini");
                file.open(file_selected);
                
                Serial.print(file_selected);

                if (file.isOpen()) 
                {
                  
                    char line[128];
                    char *token; 
                    unsigned int n;
                    unsigned int count;
                    
                     Serial.println(" opened");
                    char_count--;
                  
                    
                     while ((n = file.fgets(line, sizeof(line))) > 0) 
                     {
  
                         int i=0;
                         for (i=0; i<128; i++)
                         {
                              if (line[i]== 0x0d || line[i]== 0x0a) //clip the line at the CR or LF
                              {  
                                   line[i]='\0';
                                   break;
                              }   
                          }
                              
                          token = strtok(line, "=");
                         
                          //CONF option, add a config string to the menu
                          if (strcmp(strlwr(token),"conf")==0)
                          {
 
                              token = strtok(NULL, "=");
                              //Serial.println(token);
  
                              int i=0; 
                             
                              sd_buffer[char_count] = ';';
                              char_count++;
                                
                              while (token[i])
                              {
                                if (token[i]!= '"')// && token[i]!= 0x0d && token[i]!= 0x0a) //remove quotes and CR LF
                                {  
                                  sd_buffer[char_count] = token[i];
                                  char_count++;
                                }
                                i++;
                                
                              }
                          } 
                          //MOD option, to assign a hardware number (core variant)
                          else if (strcmp(strlwr(token),"mod")==0)
                          {
                              token = strtok(NULL, "=");
                              Serial.print("MOD = ");
                              Serial.println(atoi(token),HEX);

           
                              core_mod = atoi(token);
                              
            
                          }
                          //NAME option, to force a CORE_NAME (different than the loaded .rbf)
                          else if (strcmp(strlwr(token),"name")==0)
                          {
                              token = strtok(NULL, "=");
                              strcpy(dat_name,token);
                              Serial.print("|");
                              Serial.print(token);
                              Serial.println("|");
                          }
                          else if (strcmp(strlwr(token),"options")==0)
                          {
                              int i=0;
 
                              token = strtok(NULL, ",");
                               
                              while (token)
                              {
                               /*   Serial.print("option ");
                                  Serial.print(i);
                                  Serial.print(" = ");
                                  Serial.println(token);
                              */
                                  option_sel[i] = atoi(token);
              
                                  token = strtok(NULL, ",");
                                  i++;
              
                              }

                          }      
                     }
                      sd_buffer[char_count] = ';';
                      sd_buffer[++char_count] = '\0';

                      Serial.print("final:");
                      Serial.print(sd_buffer);
                      Serial.println("|");
                     
                }
                else
                {
                     Serial.println(" - no file");
                }
                file.close();
                // end .INI parse process



                

                //check if we have a CONF_STR
                if (char_count>1 && (cmd == 0x01 || cmd == 0x03))
                {
                    char temp[64];

                      Serial.println("CMD 0x01");

                      SPI.transfer(0x55); // command 0x55 - UIO_FILE_INDEX;
                      SPI.transfer(0x00); // index 0 - ROM
      
                      NSS_SET; //slave deselected
      
                      NSS_CLEAR; //slave selected

                      if (sd_buffer[0] == 'P' && sd_buffer[1] == ',' && cmd == 0x01) //initial data pump only when cmd=0x01 
                      {
                            int strpos;
                          //datapump only
                        
                              char *token = strtok(sd_buffer, ",");
                              token = strtok(NULL, ",");

                              token = strtok(token, ";");

                             // strpos = strstr(token, ";");
                             // if ( strpos ) strncpy(token,token,strpos);
                              
                              Serial.print ("\ntoken pump:");
                              Serial.print (token);

                              if (strcmp(token, "CORE_NAME.dat")  == 0)  // test to see if the two strings are equal
                              {
                                 strcpy(file_selected,dat_name);
                                 strcat(file_selected,".dat");
                              }
                              else
                              {
                                  strcpy(file_selected,token);
                              }

                              transfer_index = 0; //index for the ROM
                              dataPump();
                              
                               SendStatusWord(); //update the core with the read options
                        
                      } 
                      else //we have an "options" menu 
                      {
                          
                                
                          SendStatusWord(); //update the core with the read options
                          navigateOptions();
                          SaveIni(); //save the options on SD card
                          OSDVisible(false);
                     }
                     
                }
                else //we dont have a STR_CONF, so show the menu or CMD = 0x02
                {
                      Serial.println("CMD 0x02");

                      Serial.println ("we dont have a STR_CONF, so show the menu");

                      NSS_SET; 
  
                      //show the menu to navigate
                      OSDVisible(true);
                    
                      if (navigateMenu("", true, false, false,false))
                      {
                          NSS_SET; //slave deselected
                          
                          spi_osd_cmd_cont(0x55); // command 0x55 - UIO_FILE_INDEX;
                         // SPI.transfer(cur_select + 1); // file index 
                         SPI.transfer(0x01); // index as 0x01 for Sinclair QL 
                        
                          NSS_SET; //slave deselected
          
                          NSS_CLEAR; //slave selected
                          
                          Serial.println("we will execute a data pump 2!");     
                          dataPump();
                      }
      
                      OSDVisible(false);
                }
                
                break; //ok!
            }
            
            else if (cmd == 0x07)
            {
             // Serial.println("CMD 0x07");
              break;
            }
          
      }
   
      DisableOsdSPI();
      //----------------------------------------------------
}

void SaveIni(void)
{
      char temp_file[9] = {"temp.ini"};
      SdFile  tfile;
      
    //  strcpy(core_name,"robotron"); //debug
      
      strcpy(file_selected,core_name);
      strcat(file_selected,".ini");
     /* 
      Serial. print ("SaveIni: ");
      Serial.println(file_selected);

      Serial. print ("temp: ");
      Serial.println(temp_file);
*/
       if (!sd1.exists(file_selected)) 
      { 
          file.open(file_selected,FILE_WRITE);
      }
      else
      {
          file.open(file_selected);
      }

      
      

      tfile.open(temp_file, O_WRITE | O_CREAT | O_TRUNC );
      
      if (file.isOpen()) 
      {
          char line[128];
          char *token; 
          unsigned int n;

           while ((n = file.fgets(line, sizeof(line))) > 0) 
           {
            //  Serial. print ("reading: ");
              //   Serial.print(line);

              if(strncmp(line,"OPTIONS=",8)!=0)
              {
                  tfile.print(line);
    
               //   Serial. print ("writing: ");
               //   Serial.print(line);
              }
           }   
          
          //add the options to the file
          tfile.print("OPTIONS=");
          for (int i=0; i<32; i++)
          {
               tfile.print(option_sel[i],DEC);
               if (i<31) tfile.print(",");
          }
          tfile.println("");
            
      }
      
      file.close();
      tfile.close();
/*
     tfile.open(temp_file );
      
      if (tfile.isOpen()) 
      {
          char line[128];
          char *token; 
          unsigned int n;

           while ((n = tfile.fgets(line, sizeof(line))) > 0) 
           {

                Serial.print(line);
              
           }    
      }
*/
      sd1.remove(file_selected);
      sd1.rename(temp_file,file_selected);
      
      Serial. print ("SaveIni: ");
      Serial.println(file_selected);
                  
}

uint16_t crc16_update  ( uint16_t  crc,
uint8_t   a 
) 
{
   int i;
 
   crc ^= a;
   for (i = 0; i < 8; ++i)
   {
     if (crc & 1)
       crc = (crc >> 1) ^ 0xA001;
     else
       crc = (crc >> 1);
   }
 
   return crc;
 }

 uint16_t crc16_CCITT (uint16_t  crc, uint8_t data) {
  uint8_t i;

  crc = crc ^ ((uint16_t)data << 8);
  for (i = 0; i < 8; i++) {
    if (crc & 0x8000)
      crc = (crc << 1) ^ 0x1021;
    else
      crc <<= 1;
  }
  return crc;
}


 uint16_t checksum_16 (uint16_t  total, uint8_t data) {

  total = total + data;
  
  return total;
}
 
void dataPump (void)
{
        unsigned long file_size;
        unsigned long to_read;
        unsigned int read_count = 0;
        char buffer_temp[6];
        unsigned char percent = 0;
        unsigned long loaded = 0;

        uint16_t crc_read = 0;
        uint16_t crc_write = 0;

        int state = LOW;
        unsigned char c=0;

        unsigned char digit, val;

        //convert to lower case
        strlwr(file_selected);

        memcpy(buffer_temp, &file_selected[strlen(file_selected) - 4], 4);
        buffer_temp[4] = '\0';

        file.open(file_selected);
        file_size = file.fileSize();
        
        read_count = file_size / sizeof(sd_buffer);
        if (file_size % sizeof(sd_buffer) != 0) read_count++;     
                 
        SPI.setModule(2);
        NSS_SET; // ensure SS stays high for now
        
        Serial.print ("\ndata pump : ");
        Serial.println (file_selected);

        Serial.print ("file ext : ");
        Serial.println ((char*)buffer_temp);

        Serial.print ("file size : ");
        Serial.println (file_size);

        Serial.print ("read_count : ");
        Serial.println (read_count);

        Serial.print ("index : ");
        Serial.println (transfer_index);

        NSS_CLEAR;
        //send the transfer_index
        spi_osd_cmd_cont(0x55); // command 0x55 - UIO_FILE_INDEX;
        spi8(transfer_index); // index 0 - ROM, 1 = drive 1, 2 = drive 2
        NSS_SET;

        // config buffer - 16 bytes
        spi_osd_cmd_cont(0x60); //cmd to fill the config buffer

        // spi functions transfer the MSB byte first
        spi32(file_size); // 4 bytes for file size

        //3 bytes for extension
        spi8(buffer_temp[1]);
        spi8(buffer_temp[2]);
        spi8(buffer_temp[3]);
        spi8(0xFF);
        
        spi8(0xFF);
        spi8(0xFF);
        spi8(0xFF);
        spi8(0xFF);
        
        spi8(0xFF);
        //last bytes as STM version
        spi8(version[2] - '0');
        spi8(version[1] - '0');
        spi8(version[0] - '0');
        
        DisableOsdSPI(); 
    
        SPI.setModule(1); // select the SD Card SPI 
        


        for (int k=1; k<read_count+1; k++) 
        { 
            unsigned char val;
          //  Serial.print ("block read ");
         //   Serial.println (k);

        
            to_read = ( file_size >= (sizeof(sd_buffer) *k)) ? sizeof(sd_buffer) : file_size - loaded+1;

        //    Serial.print ("to_read ");
        //   Serial.println (to_read);


        
            val = file.read(sd_buffer, to_read);
           
            SPI.setModule(2); // select the second SPI (connected on FPGA)
            NSS_CLEAR;  //SS clear to send a comand
            ret = SPI.transfer(0x61); //start the data pump to slave


              // Serial.print ("RET 0x61: ");
            //    Serial.println (ret, HEX);
            
            for (int f=0; f<to_read; f++) 
            {

                if (digitalRead(nWAITpin) == LOW) { Serial.println ("waiting SPI"); delay(1);} //check for a WAIT state
              
                ret = SPI.transfer (sd_buffer[f]);
                
       //         crc_write = checksum_16(crc_write, sd_buffer[f]);
       //         crc_read  = checksum_16(crc_read, ret);

              // Serial.print ("RET : ");
              //  Serial.println (ret, HEX);
            }
            NSS_SET; //end the pumped block

        /*    Serial.print ("crc_write : ");
            Serial.println (crc_write, HEX);
  
            Serial.print ("crc_read : ");
            Serial.println (crc_read, HEX);
          */
            
            loaded += to_read;
            percent = loaded * 100 / file_size;

            digit = 0;
            val = percent;
              while (val > 9)
              {
                val -= 10;
                digit++;
              }
            
            
            buffer_temp[0] = ' ';
            buffer_temp[1] = '0' + digit;
            buffer_temp[2] = '0' + val;
            buffer_temp[3] = '%';
            buffer_temp[4] = ' ';
            buffer_temp[5] = '\0';
            
            OsdWriteOffset(6, "            Loading", 0 , 0, 0, 0);
            OSD_progressBar(7, buffer_temp, percent);
            
            SPI.setModule(1); // select the SD Card SPI   

            state++;
            digitalWrite(LEDpin, state>>2 & 1); //led off
        }

        digitalWrite(LEDpin, HIGH); //led off
        
        file.close();

            
          
        //CLEAR THE LOADING MESSAGE
        OsdWriteOffset(6, " ", 0 , 0, 0, 0);
        OsdWriteOffset(7, " ", 0 , 0, 0, 0);

        Serial.println ("end data");



  /*          Serial.print ("crc_write final : ");
            Serial.println (crc_write, HEX);
  
            Serial.print ("crc_read final : ");
            Serial.println (crc_read, HEX);
    */        

            crc_read = 0;
            crc_write = 0;
            
        spi_osd_cmd_cont(0x62); // end the data pump


        NSS_SET; // SS end sequence
}



//   JTAG   ////////////////////////////////////////////////////////////////////////////////////////////////

void setupJTAG()
{

  pinMode(TCKpin, OUTPUT);
  pinMode(TDOpin, INPUT_PULLUP);
  pinMode(TMSpin, OUTPUT);
  pinMode(TDIpin, OUTPUT);

  digitalWrite(TCKpin, LOW);
  digitalWrite(TMSpin, LOW);
  digitalWrite(TDIpin, LOW);
}

void error() 
{
      Serial.println("JTAG");
      Serial.println("ERROR!!!!");
}


void program_FPGA()
{
    unsigned long bitcount = 0;
    bool last = false;
    int n = 0; 
    


    Serial.print ("Programming");

   // display.setTextSize(1);
   // display.setCursor(0,40);
    //display.println("Programando");
    //display.display();
    
    JTAG_PREprogram(); 


    //writetofile ("Inicio programacao ------------------------------");

    int mark_pos = 0;
    int total = file.fileSize();
    int divisor = total / 32; 
    int state = LOW;
    
    while(bitcount < total)  //155224
    { 
        
        unsigned char val = file.read();
        int value;
        
        if (bitcount % divisor == 0) 
        {
            Serial.print ("*");

    
            state = !state;

          digitalWrite(LEDpin, state);
          
       //      display.setCursor(mark_pos*8,55);
        //    display.println("*");
         //   display.display();
         //   mark_pos++;
        }
        bitcount++;
  
      //pula os primeiros 44 caracteres do RBF (header no cyclone II)
      //if (bitcount<45) continue; 

        for (n = 0; n <= 7; n++)
        {
            value = ((val >> n) & 0x01);
            digitalWrite(TDIpin, value); JTAG_clock();
        }

    }

      //writetofile ("Additional 16 bytes of 0xFF ------------------------------------------");
      
      /* AKL (Version1.7): Dump additional 16 bytes of 0xFF at the end of the RBF file */
      for (n=0;n<127;n++ )
      {
          digitalWrite(TDIpin, HIGH); JTAG_clock();

        // writetofile ("1");
      }
 
      //   writetofile ("1 - TMS 1");

      digitalWrite(TDIpin, HIGH); 
      digitalWrite(TMSpin, HIGH);
      JTAG_clock();
      
       
      // writetofile ("fim programacao ------------------------------------------");     

     
      
          Serial.println ("");
          Serial.print ("Programmed ");
          Serial.print (bitcount);
          Serial.println(" bytes");
      
      
    file.close();

    JTAG_POSprogram();
}


void initOSD(void)
{
    EnableOsdSPI();  
    OsdClear();
    OSDVisible(true);
}

void removeOSD(void)
{
    EnableOsdSPI();  
    OsdClear();
    OSDVisible(false);
    DisableOsdSPI();
}

void initialData(void)
{

        // config buffer - 16 bytes
        spi_osd_cmd_cont(0x60); //cmd to fill the config buffer

        spi8(0xFF);
        spi8(0xFF);
        spi8(0xFF);
        spi8(0xFF);

        spi8(0xFF);
        spi8(0xFF);
        spi8(0xFF);
        spi8(0xFF);
        
        spi8(0xFF);
        spi8(0xFF);
        spi8(0xFF);
        spi8(0xFF);
        
        spi8(0xFF);

        //last bytes as STM version
        spi8(version[2] - '0');
        spi8(version[1] - '0');
        spi8(version[0] - '0');
        
        DisableOsdSPI(); 
}

/////////////////////////////////////////////////////////////////////////


void setup (void)
{

      //Initialize serial and wait for port to open:
      Serial.begin(115200);
      while (!Serial) 
      {
          ; // wait for serial port to connect. Needed for native USB port only
      }
    
      Serial.println("Serial ok...");
      
      Serial.print("Initializing SPI version ");
      Serial.println((char*)version);

      pinMode(nWAITpin, INPUT_PULLUP);
      
      pinMode(LEDpin, OUTPUT);
      
      pinMode(TCKpin, INPUT);
      pinMode(TDOpin, INPUT);
      pinMode(TMSpin, INPUT);
      pinMode(TDIpin, INPUT);
      
      pinMode(NSS_PIN, OUTPUT); // configure NSS pin
      pinMode(START_PIN, INPUT);
      
      // set second SPI on PA12-PA15
      SPI.setModule(2);



      
      NSS_SET; // ensure SS stays high for now
      SPI.begin ();
//      SPI.setClockDivider(SPI_CLOCK_DIV2); //4mhz SPI
//      SPI.setClockDivider(SPI_CLOCK_DIV4); //2mhz SPI
      SPI.setClockDivider(SPI_CLOCK_DIV8); //1mhz SPI
      
            
      NSS_SET; //slave deselected
        
      waitACK();
      initialData();
      
      SPI.setModule(1); // select the SD Card SPI

      if (!sd1.begin(CS_SDCARDpin, SD_SCK_MHZ(50))) 
      {
            Serial.println("SD Card initialization failed!");
      
            initOSD();
            OsdWriteOffset(3, "          No SD Card!!! ", 1, 0, 0, 0 ); 
      
            //hold until a SD is inserted
            while (!sd1.begin(CS_SDCARDpin, SD_SCK_MHZ(50))) {}
          strcpy(file_selected,"core.rbf");
      if (!sd1.exists(file_selected)) 
      { 
         Serial.println ("core.rbf not found");
         CORE_ok = false;
      }
            removeOSD();
      } 
    
      strcpy(file_selected,"core.rbf");
      if (!sd1.exists(file_selected)) 
      { 
         Serial.println ("core.rbf not found");
         CORE_ok = false;
      }
      
      //SD_ok = true;
 
      Serial.println("SD Card initialization done.");

}  // end of setup


void loop (void)
{

        Serial.println("loop");

/*
        //--- Test the data pump the waiting for commands
        while(1)
        {
            waitACK();
            waitSlaveCommand();
            delay(500);
        }
        //----------------------
*/      
        //debug
        //navigateOptions();while(1);
        
        //if we have a core.rbf, lets transfer, without a menu
        if  (CORE_ok)
        {

             
              strncpy ( core_name, file_selected, strlen(file_selected)-4 ); // Save the core name to use later inside the core

              strcpy (dat_name, core_name);

              Serial.print ("core name:"); 
              Serial.println(core_name);

              file.open(file_selected);
            
              digitalWrite(LEDpin, HIGH); //led off
            
              delay(300);                       // wait for the FPGA power on
              setupJTAG();
              if (JTAG_scan() == 0) {
                program_FPGA();
              }
        
              Serial.println("OK, finished");
              
              //loop forever waiting commands
              while(1)
              {
                    waitACK();
                    waitSlaveCommand();
                    //delay(500);
              }
        }
        else // no core, start the menu
        {
            //  root = SD.open("/");
                
              EnableOsdSPI();  
              OsdClear();
              OSDVisible(true);

              splashScreen();

              if (!navigateMenu("rbf", true, true, false, false)) //if we receive a command, go to the command state (to make de development easier)
              {
                
                OSDVisible(false);
                
                while(1)
                {
                      waitACK();
                      waitSlaveCommand();
                     // delay(500);
                }
              }
              
              CORE_ok = true;
        }
        
     //   waitACK();
      //  waitSlaveCommand();
        
       
         
}  // end of loop
