unit utotalcmd;

{$mode ObjFPC}{$H+}

interface

const
 //OpenMode is set to one of the following values:
 PK_OM_LIST   =0;// Open file for reading of file names only
 PK_OM_EXTRACT=1;// Open file for processing (extract or test)

 //Operation is set to one of the following:
 PK_SKIP   =0; //Skip this file
 PK_TEST   =1; //Test file integrity
 PK_EXTRACT=2; //Extract to disk

 //tChangeVolProc mode
 PK_VOL_ASK   =0; //Ask user for location of next volume
 PK_VOL_NOTIFY=1; //Notify app that next volume will be unpacked

 //FileAttr can be set to any combination of the following values:
 PK_FILE_ATTR_READONLY =$01;
 PK_FILE_ATTR_HIDDEN   =$02;
 PK_FILE_ATTR_SYSTEM   =$04;
 PK_FILE_ATTR_VOLUME_ID=$08;
 PK_FILE_ATTR_DIRECTORY=$10;
 PK_FILE_ATTR_ARCHIVE  =$20;
 PK_FILE_ATTR_ANY      =$3F;

 //errors
 E_SUCCESS       = 0; //Success
 E_END_ARCHIVE   =10; //No more files in archive
 E_NO_MEMORY     =11; //Not enough memory
 E_BAD_DATA      =12; //CRC error in the data of the currently unpacked file
 E_BAD_ARCHIVE   =13; //The archive as a whole is bad, e.g. damaged headers
 E_UNKNOWN_FORMAT=14; //Archive format unknown
 E_EOPEN         =15; //Cannot open existing file
 E_ECREATE       =16; //Cannot create file
 E_ECLOSE        =17; //Error closing file
 E_EREAD         =18; //Error reading from file
 E_EWRITE        =19; //Error writing to file
 E_SMALL_BUF     =20; //Buffer too small
 E_EABORTED      =21; //Function aborted by user
 E_NO_FILES      =22; //No files found
 E_TOO_MANY_FILES=23; //Too many files to pack
 E_NOT_SUPPORTED =24; //Function not supported

type
 POpenArchiveData=^tOpenArchiveData;
 tOpenArchiveData=packed record
  ArcName   :PAnsiChar;
  OpenMode  :Integer;
  OpenResult:Integer;
  CmtBuf    :PChar;
  CmtBufSize:Integer;
  CmtSize   :Integer;
  CmtState  :Integer;
 end;

 POpenArchiveDataW=^tOpenArchiveDataW;
 tOpenArchiveDataW=packed record
  ArcName   :PWideChar;
  OpenMode  :Integer;
  OpenResult:Integer;
  CmtBuf    :PChar;
  CmtBufSize:Integer;
  CmtSize   :Integer;
  CmtState  :Integer;
 end;

 PHeaderData=^tHeaderData;
 tHeaderData=packed record
  ArcName   :array[0..259] of AnsiChar;
  FileName  :array[0..259] of AnsiChar;
  Flags     :Integer;
  PackSize  :Integer;
  UnpSize   :Integer;
  HostOS    :Integer;
  FileCRC   :Integer;
  FileTime  :Integer;
  UnpVer    :Integer;
  Method    :Integer;
  FileAttr  :Integer;
  CmtBuf    :PChar;
  CmtBufSize:Integer;
  CmtSize   :Integer;
  CmtState  :Integer;
 end;

 PHeaderDataEx=^tHeaderDataEx;
 tHeaderDataEx=packed record
  ArcName     :array[0..1023] of AnsiChar;
  FileName    :array[0..1023] of AnsiChar;
  Flags       :Integer;
  PackSize    :DWORD;
  PackSizeHigh:DWORD;
  UnpSize     :DWORD;
  UnpSizeHigh :DWORD;
  HostOS      :Integer;
  FileCRC     :Integer;
  FileTime    :Integer;
  UnpVer      :Integer;
  Method      :Integer;
  FileAttr    :Integer;
  //align???
  CmtBuf      :PChar;
  CmtBufSize  :Integer;
  CmtSize     :Integer;
  CmtState    :Integer;
  Reserved    :array[0..1023] of AnsiChar;
 end;

 PHeaderDataExW=^tHeaderDataExW;
 tHeaderDataExW=packed record
  ArcName     :array[0..1023] of WideChar;
  FileName    :array[0..1023] of WideChar;
  Flags       :Integer;
  PackSize    :DWORD;
  PackSizeHigh:DWORD;
  UnpSize     :DWORD;
  UnpSizeHigh :DWORD;
  HostOS      :Integer;
  FileCRC     :Integer;
  FileTime    :Integer;
  UnpVer      :Integer;
  Method      :Integer;
  FileAttr    :Integer;
  //align???
  CmtBuf      :PChar;
  CmtBufSize  :Integer;
  CmtSize     :Integer;
  CmtState    :Integer;
  Reserved    :array[0..1023] of AnsiChar;
 end;

 //function that asks the user to change volume.
 tChangeVolProc=function(ArcName:PAnsiChar;Mode:Integer):Integer; stdcall;
 tChangeVolProcW=function(ArcName:PWideChar;Mode:Integer):Integer; stdcall;

 //function that notifies the user about the progress when un/packing files.
 tProcessDataProc=function(FileName:PAnsiChar;Size:Integer):Integer; stdcall;
 tProcessDataProcW=function(FileName:PWideChar;Size:Integer):Integer; stdcall;

//prototypes

//function OpenArchive(ArchiveData:POpenArchiveData):Pointer; stdcall;
//function OpenArchiveW(ArchiveData:POpenArchiveDataW):Pointer; stdcall;

//function CloseArchive(hArcData:Pointer):Integer; stdcall;

//function ReadHeader(hArcData:Pointer;HeaderData:PHeaderData):Integer; stdcall;
//function ReadHeaderEx(hArcData:Pointer;HeaderData:PHeaderDataEx):Integer; stdcall;
//function ReadHeaderExW(hArcData:Pointer;HeaderData:PHeaderDataExW):Integer; stdcall;

//function ProcessFile(hArcData:Pointer;Operation:Integer;DestPath,DestName:PAnsiChar):Integer; stdcall;
//function ProcessFileW(hArcData:Pointer;Operation:Integer;DestPath,DestName:PWideChar):Integer; stdcall;

//procedure SetChangeVolProc(hArcData:Pointer;pChangeVolProc:tChangeVolProc);
//procedure SetChangeVolProcW(hArcData:Pointer;pChangeVolProc:tChangeVolProcW);

//procedure SetProcessDataProc(hArcData:Pointer;pProcessDataProc:tProcessDataProc);
//procedure SetProcessDataProcW(hArcData:Pointer;pProcessDataProc:tProcessDataProcW);

implementation

end.

