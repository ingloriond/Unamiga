#include "SdFat.h"
#include <SPI.h>
#include <Wire.h>

const unsigned char version[4] = "105"; // v 1.04

const int TCKpin = PB0;   
const int TDIpin = PB1;    
const int TMSpin = PB10;   
const int TDOpin = PB11; //input  

const int CS_SDCARDpin  = PA4; 
const int LEDpin = PC13;  

SdFat sd1(1);

SdFile  file;
SdFile  entry;

//bool SD_ok = false;
bool CORE_ok = true;

char sd_buffer[1024];
unsigned char ret;


unsigned char option_sel[32] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
unsigned char option_num[32] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
    unsigned char key;
    unsigned char cmd;
    unsigned char last_key = 31; //only the 5 lower bit are keys
    unsigned char last_cmd = 1;
    
unsigned char last_ret;
unsigned char cur_select = 0;
    
#define START_PIN  PA8

char file_selected[64];

#define NSS_PIN  PB12
#define NSS_SET ( GPIOB->regs->BSRR = (1U << 12) )
#define NSS_CLEAR ( GPIOB->regs->BRR = (1U << 12) )

bool isExtension(char* filename, char* extension) 
{
    int8_t len = strlen(filename);
    char ext[5];
    char file[64];
    bool result;
  
    //local copy the strings
    strcpy(ext, extension);  
    strcpy(file, filename);  
  
    if ( strstr(strlwr(file + (len - 4)), strlwr(ext)) ) 
    {
      result = true;
    } 
    else 
    {
      result = false;
    }
    
    return result;
}

unsigned char codeToNumber (unsigned char code)
{
    if (code >= '0' && code <= '9') return code-48;
    if (code >= 'A' && code <= 'Z') return code-55;

    return code;
}


bool navigateOptions()
{
      // char sd_buffer[1024] {          "S,PRG,Load *.PRG;S,TAP,Load *.TAP;TC,Play/Stop TAP;OG,Menos sound,Off,On;OH,Mais sound,Off,On;OD,Tape sound,Off,On;O3,Video,PAL,NTSC;O2,CRT with load address,Yes,No;OAB,Scanlines,Off,25%,50%,75%;O45,Enable 8K+ Expansion,Off,8K,16K,24K;O6,Enable 3K Expansion,Off,On;O78,Enable 8k ROM,Off,RO,RW;O9,Audio Filter,On,Off;T0,Reset;T1,Reset with cart unload;." };
      
      int ini = 0;
      int fim=0;
      int cur_line = 0;
      int page = 0;
      int i,j,k;
      int opt_sel =0;
      int total_options = 0;
      int total_show = 0;
      int last_page = 0;


    
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
        
          
            char temp[64];
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
                
                token = strtok(NULL, ",");

                if (cur_select==cur_line) 
                {
                   strcpy(ext,".");
                   strcat(ext,token); 
                }
                
                token = strtok(NULL, ",");
                strcpy(line,token);
                line[32] = '\0';
                
                total_options++;

                option_num[opt_sel] = 99;
                option_sel[opt_sel] = 0; 
                
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
               
        while (true)
        {
   
            key = SPI.transfer(0); //dummy data, just to read the response

            cmd = (key & 0xe0) >> 5; //just the 3 msb is the command
            key = key & 0x1f; //just the lower 5 bits are keys

          /* Serial.print ("\n");
           Serial.print (cmd);
           Serial.print (":");
           Serial.print (key);
           Serial.print (" = ");
           Serial.print ((char)key);
            */  



            
            if (key!=last_key || cmd != last_cmd) break; //something was pressed on keyboard or a command arrived
       
        }
        
        NSS_SET; // SS high 
 
        last_key = key;
        last_cmd = cmd;


        


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
                 OsdClear();
                //Serial.print(ext);Serial.println("-----------------------------");
                if (navigateMenu(ext, true, false))
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
        else if ((cmd == 0x01 || cmd == 0x02)) //F12 - abort
        {
            
            return false;  
        }

        if (page != last_page)
        {
            last_page = page;
            if (key !=30) cur_select = page*8;
            OsdClear();
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
         NSS_SET;
        
      }

       
    
}

bool navigateMenu( char* extension, bool canAbort, bool filter ) 
{
    int index=0;
    unsigned char total_files = 0;
    unsigned char page = 0;
    unsigned char last_page = 0;
    bool selected = false;
    bool showfile = false;
    bool isDir = false;
    bool isSelectedDir = false;
    bool insideDir = false;

    char ext[5];
    unsigned char cur_line = 0;

    unsigned char total_show = 0;

    cur_select=0;

    Serial.println("navigateMenu");
  
    //local copy of the extension
   // strcpy(ext, extension);

   
    while (!selected)
    {
        
            total_show = 0;
            sd1.vwd()->rewind(); 
            total_files = 0;
            cur_line = 0;
      
             if ( !sd1.vwd()->isRoot() )
             {
                   insideDir = true;
                   OsdWriteOffset(cur_line - (page*8), "<..>", (cur_select==cur_line) , 0, 0, 0);

                   cur_line++;
                   total_files++;   
                   total_show++;             
             }
             else
             {
                  insideDir = false;
             }

               
            while (entry.openNext(sd1.vwd(), O_READ)) 
            {
   
                char filetemp[64]; 
                char filename[64]; 
                
                entry.getName(filename,64);

                showfile = false;
     
                if ( strlen(extension) < 2 )
                {
                  // filter = false;
                   showfile = true;
                }
                else if (isExtension(filename, extension)) 
                {
                 //  filter = true;
                   showfile = true;
                }

                
                isDir = entry.isDir();

                if (isDir && (strcmp(extension,".rbf") != 0) ) //don't show folders with .rbf selection
                { 
                    showfile = true; 
                }
      
                if (showfile) 
                {
                      
                      
                     unsigned char len = strlen(filename);
                     bool f_selected = false;
                    
                     if (cur_select==cur_line) 
                     {
                        f_selected = true;
                        strcpy(file_selected,filename);
                        isSelectedDir= entry.isDir();
                     }

                      
                      if (isDir) 
                      {
                        strcpy(filetemp, "<DIR> ");
                        strcat(filetemp, filename);
                        strcpy(filename, filetemp);
                        
                      }


                      if (cur_line >= page*8 && total_show <= 8)
                      {

             
                          if (!filter)
                          {
                              OsdWriteOffset(cur_line - (page*8), filename, f_selected , 0, 0, 0);
                          }
                          else
                          {
                              OsdWriteOffset(cur_line - (page*8), strtok(filename, "."), f_selected , 0, 0, 0);
                          }

                          total_show++;
                      }
                      
                      cur_line++;
                      total_files++;
                }
          
                   
                
                entry.close();
            }


        // Serial.print("total files ");    
        // Serial.println(total_files);    
      
    
    
        // set second SPI on PA12-PA15
        SPI.setModule(2);
        NSS_SET; // ensure SS stays high for now

       Serial.println("Waiting keys!");
        
        NSS_CLEAR;
        key = SPI.transfer(0x10); //command to read from ps2 keyboad
       
        while (true)
        {
   
            key = SPI.transfer(0); //dummy data, just to read the response

            cmd = (key & 0xe0) >> 5; //just the 3 msb are the command
            key = key & 0x1f; //just the lower 5 bits are keys
/*
           Serial.print ("\n");
           Serial.print (cmd);
           Serial.print (":");
           Serial.print (key);
           Serial.print (" = ");
           Serial.print ((char)key);
  */            
            if (key!=last_key || cmd != last_cmd) break; //something was pressed on keyboard or a command arrived
       
        }
        
        NSS_SET; // SS high 
 
        last_key = key;
        last_cmd = cmd;


        
        SPI.setModule(1);

       Serial.println("Key received");

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
           if (cur_select < total_files-1) cur_select++; 

           if (cur_select > ((page+1)*8)-1) page++;
        }
        else if (key == 27) //left
        {
           if (page > 0) page--;  
        }
        else if (key == 23) //right
        {
           if (page < ((total_files-1)/8)) page++; 
        }
        else if (key == 15) //enter
        {
            if (insideDir && cur_select == 0)
            {
                sd1.chdir();
                page = 0;
                last_page = 99; //to force a clear 
            }
            else if ( isSelectedDir)
            {
                sd1.chdir(file_selected);
                page = 0;
                last_page = 99; //to force a clear 
            }
            else
            {
                selected = true;  
            }
        }
        else if ((cmd == 0x01 || cmd == 0x02) && canAbort) //F12 - abort
        {
            return false;  
        }

        if (page != last_page)
        {
            last_page = page;
            if (key !=30) cur_select = page*8;
            OsdClear();
        }

    }
    
    return true;
    
}

void waitACK (void)
{
   //----------------------------------------------------
      // set second SPI on PA12-PA15
      SPI.setModule(2);
      NSS_SET; // ensure SS stays high for now
      //syncronize and clear the SPI buffers
   
      Serial.println ("waitACK");
      
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
          
          Serial.print ("\n");
            Serial.print (ret);
            Serial.print ("=");
            Serial.print ((char)ret);
            
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



            if (cmd == 0x01 || cmd == 0x02)
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
                    
                   // Serial.print ("\n command 0x14 reply:");
                    //Serial.print (ret);
                  // Serial.print ("=");
                    Serial.print ((char)ret);
                    char_count++;
                    
                }

                //check if we have a CONF_STR
                if (char_count>1 && cmd == 0x01)
                {

                      Serial.println("CMD 0x01");

                      SPI.transfer(0x55); // command 0x55 - UIO_FILE_INDEX;
                      SPI.transfer(0x00); // index 0 - ROM
      
                      NSS_SET; //slave deselected
      
                      NSS_CLEAR; //slave selected

                      if (sd_buffer[0] == 'P' && sd_buffer[1] == ',')
                      {
                          //datapump only
                        
                              char *token = strtok(sd_buffer, ",");
                              token = strtok(NULL, ",");
                              Serial.print ("\ntoken pump:");
                              Serial.print (token);
                              strcpy(file_selected,token);
                        
                              dataPump();
                        
                      } 
                      else //we have an "options" menu 
                      {

                          navigateOptions();
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
                    
                      if (navigateMenu("", true, false))
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
              Serial.println("CMD 0x07");
              break;
            }
          
      }
   
      DisableOsdSPI();
      //----------------------------------------------------
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
        
        Serial.print ("\ndata pump NEW : ");
        Serial.println (file_selected);

        Serial.print ("file ext : ");
        Serial.println ((char*)buffer_temp);

        Serial.print ("file size : ");
        Serial.println (file_size);

        Serial.print ("read_count : ");
        Serial.println (read_count);

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

     //       Serial.print ("to_read ");
      //      Serial.println (to_read);


        
            val = file.read(sd_buffer, to_read);
           
            SPI.setModule(2); // select the second SPI (connected on FPGA)
            NSS_CLEAR;  //SS clear to send a comand
            ret = SPI.transfer(0x61); //start the data pump to slave


              // Serial.print ("RET 0x61: ");
            //    Serial.println (ret, HEX);
            
            for (int f=0; f<to_read; f++) 
            {
                ret = SPI.transfer (sd_buffer[f]);
                
                crc_write = checksum_16(crc_write, sd_buffer[f]);
                crc_read  = checksum_16(crc_read, ret);

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



            Serial.print ("crc_write final : ");
            Serial.println (crc_write, HEX);
  
            Serial.print ("crc_read final : ");
            Serial.println (crc_read, HEX);
            

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
              file.open(file_selected);
            
              digitalWrite(LEDpin, HIGH); //led off
            
              delay(300);                       // wait for the FPGA power on
              setupJTAG();
              if (JTAG_scan() == 0)    program_FPGA();
            
              Serial.println("OK, finished");
              
              //loop forever waiting commands
              while(1)
              {
                    waitACK();
                    waitSlaveCommand();
                    delay(500);
              }
        }
        else // no core, start the menu
        {
            //  root = SD.open("/");
                
              EnableOsdSPI();  
              OsdClear();
              OSDVisible(true);
              
              if (!navigateMenu(".rbf", true, true)) //if we receive a command, go to the command state (to make de development easier)
              {
                
                OSDVisible(false);
                
                while(1)
                {
                      waitACK();
                      waitSlaveCommand();
                      delay(500);
                }
              }
              
              CORE_ok = true;
        }
        
     //   waitACK();
      //  waitSlaveCommand();
        
       
         
}  // end of loop

