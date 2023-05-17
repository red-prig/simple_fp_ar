library simple_fp_ar;

{$mode objfpc}{$H+}

{$IF defined(CPUX86_64)}
 {$EXTENSION 'wcx64'}
{$ELSE}
 {$EXTENSION 'wcx'}
{$ENDIF}

{/$DEFINE DEBUG}

uses
 {$IFDEF DEBUG}
  windows,
 {$ENDIF}
 SysUtils,
 dateutils,
 uarch,
 utotalcmd;

type
 tReadState=(rsNextHeader,rsNextFile);

 PArchFile=^TArchFile;
 TArchFile=packed record
  F:Thandle;
  size:Int64;
  ArcName:PAnsiChar;
  ProcessCbA:tProcessDataProc;
  ProcessCbW:tProcessDataProcW;
  last_hdr:record
   FileName:array[0..1023] of AnsiChar;
   FileOffset:Int64;
  end;
  sysv_table:record
   data:PChar;
   Size:Int64;
  end;
  state:tReadState;
 end;

Procedure WriteStr(Const line,text,value:RawByteString); inline;
{$IFDEF DEBUG}
var
 num:DWORD;
 v:RawByteString;
{$ENDIF}
begin
 {$IFDEF DEBUG}
 v:='('+line+') '+text+':'+value+#13#10;
 WriteConsole(GetStdHandle(STD_ERROR_HANDLE),PAnsiChar(v),Length(v),num,nil);
 {$ENDIF}
end;

function OpenArchiveU(const ArcName:RawByteString;var OpenResult:Integer):PArchFile;
var
 F:THandle;
 size:Int64;
 sig:Tarch_sig;
begin

 {$IFDEF DEBUG}
 AllocConsole;
 {$ENDIF}

 WriteStr({$INCLUDE %LINE%},'OpenArchiveU',ArcName);

 Result:=nil;
 F:=FileOpen(ArcName,fmOpenRead or fmShareDenyNone);

 if (F=feInvalidHandle) then
 begin
  WriteStr({$INCLUDE %LINE%},'OpenArchiveU','E_EOPEN');
  OpenResult:=E_EOPEN;
  Exit;
 end;

 size:=FileSeek(F,0,fsFromEnd);
 if (size=-1) then
 begin
  WriteStr({$INCLUDE %LINE%},'OpenArchiveU','E_EREAD');
  FileClose(F);
  OpenResult:=E_EREAD;
  Exit;
 end;
 FileSeek(F,0,fsFromBeginning);

 if (FileRead(F,sig,SizeOf(sig))<>SizeOf(sig)) then
 begin
  WriteStr({$INCLUDE %LINE%},'OpenArchiveU','E_EREAD');
  FileClose(F);
  OpenResult:=E_EREAD;
  Exit;
 end;

 if (sig<>arch_sig) then
 begin
  WriteStr({$INCLUDE %LINE%},'OpenArchiveU','E_UNKNOWN_FORMAT');
  FileClose(F);
  OpenResult:=E_UNKNOWN_FORMAT;
  Exit;
 end;

 Result:=AllocMem(SizeOf(TArchFile)+Length(ArcName)+1);

 if (Result=nil) then
 begin
  WriteStr({$INCLUDE %LINE%},'OpenArchiveU','E_NO_MEMORY');
  FileClose(F);
  OpenResult:=E_NO_MEMORY;
  Exit;
 end;

 Result^.F      :=F;
 Result^.size   :=size;
 Result^.state  :=rsNextHeader;
 Result^.ArcName:=Pointer(Result+1);

 Move(PAnsiChar(ArcName)^,Result^.ArcName^,Length(ArcName));

 WriteStr({$INCLUDE %LINE%},'OpenArchiveU','E_SUCCESS');
 OpenResult:=E_SUCCESS;
end;

function OpenArchive(ArchiveData:POpenArchiveData):PArchFile; stdcall;
begin
 if (ArchiveData=nil) or (ptrint(ArchiveData)=-1) then Exit;

 Result:=OpenArchiveU(AnsiToUtf8(ArchiveData^.ArcName),
         ArchiveData^.OpenResult);
end;

function OpenArchiveW(ArchiveData:POpenArchiveDataW):PArchFile; stdcall;
begin
 if (ArchiveData=nil) or (ptrint(ArchiveData)=-1) then Exit;

 Result:=OpenArchiveU(UTF8Encode(WideString(ArchiveData^.ArcName)),
         ArchiveData^.OpenResult);
end;

function CloseArchive(hArcData:PArchFile):Integer; stdcall;
begin
 WriteStr({$INCLUDE %LINE%},'CloseArchive','');

 if (hArcData=nil) or (ptrint(hArcData)=-1) then Exit(E_ECLOSE);

 FileClose(hArcData^.F);

 FreeMem(hArcData^.sysv_table.data);
 FreeMem(hArcData);
end;

procedure SetChangeVolProc(hArcData:PArchFile;pChangeVolProc:tChangeVolProc);
begin
 //
end;

procedure SetChangeVolProcW(hArcData:PArchFile;pChangeVolProc:tChangeVolProcW);
begin
 //
end;

procedure SetProcessDataProc(hArcData:PArchFile;pProcessDataProc:tProcessDataProc);
begin
 WriteStr({$INCLUDE %LINE%},'SetProcessDataProc','');

 if (hArcData=nil) or (ptrint(hArcData)=-1) then Exit;
 hArcData^.ProcessCbA:=pProcessDataProc;
end;

procedure SetProcessDataProcW(hArcData:PArchFile;pProcessDataProc:tProcessDataProcW);
begin
 WriteStr({$INCLUDE %LINE%},'SetProcessDataProc','');

 if (hArcData=nil) or (ptrint(hArcData)=-1) then Exit;
 hArcData^.ProcessCbW:=pProcessDataProc;
end;

type
 PHeaderDataU=^tHeaderDataU;
 tHeaderDataU=packed record
  FileName:array[0..1023] of AnsiChar;
  FileSize:Int64;
  FileTime:Integer;
 end;

function ReadHeaderU(hArcData:PArchFile;HeaderData:PHeaderDataU):Integer;
label
 retry,
 short;
var
 hdr:Tarch_header;
 time,size,offset:Int64;
 D:TDateTime;
begin
 retry:

 //check end
 size:=hArcData^.size;

 offset:=FileSeek(hArcData^.F,0,fsFromCurrent);
 if (offset=-1) then
 begin
  WriteStr({$INCLUDE %LINE%},'ReadHeaderU','E_EREAD');
  Exit(E_EREAD);
 end;

 if (offset>=size) then
 begin
  WriteStr({$INCLUDE %LINE%},'ReadHeaderU','E_END_ARCHIVE');
  Exit(E_END_ARCHIVE);
 end;

 //read hdr
 if (FileRead(hArcData^.F,hdr,SizeOf(hdr))<>SizeOf(hdr)) then
 begin
  WriteStr({$INCLUDE %LINE%},'ReadHeaderU','E_EREAD');
  Exit(E_EREAD);
 end;

 WriteStr({$INCLUDE %LINE%},'hdr.FileName ',hdr.FileName );
 WriteStr({$INCLUDE %LINE%},'hdr.timestamp',hdr.timestamp);
 WriteStr({$INCLUDE %LINE%},'hdr.OwnerID  ',hdr.OwnerID  );
 WriteStr({$INCLUDE %LINE%},'hdr.GroupID  ',hdr.GroupID  );
 WriteStr({$INCLUDE %LINE%},'hdr.FileMode ',hdr.FileMode );
 WriteStr({$INCLUDE %LINE%},'hdr.FileSize ',hdr.FileSize );
 WriteStr({$INCLUDE %LINE%},'hdr.Ending   ','#$'+HexStr(ord(hdr.Ending[0]),2)+
                                            '#$'+HexStr(ord(hdr.Ending[1]),2));

 if (hdr.Ending<>hend_sig) then
 begin
  WriteStr({$INCLUDE %LINE%},'ReadHeaderU','E_BAD_ARCHIVE');
  Exit(E_BAD_ARCHIVE);
 end;

 hArcData^.last_hdr.FileOffset:=get_next_offset(@hdr);

 if (strlcomp(@hdr.FileName,@ftbl_sig,SizeOf(ftbl_sig))=0) then //sysv extension
 begin
  offset:=FileSeek(hArcData^.F,0,fsFromCurrent);
  if (offset=-1) then
  begin
   WriteStr({$INCLUDE %LINE%},'ReadHeaderU','E_EREAD');
   Exit(E_EREAD);
  end;

  size:=hArcData^.last_hdr.FileOffset;

  WriteStr({$INCLUDE %LINE%},'SYSV_TABLE',IntToStr(size));

  hArcData^.sysv_table.data:=AllocMem(size);
  hArcData^.sysv_table.Size:=size;

  if (hArcData^.sysv_table.data=nil) then
  begin
   WriteStr({$INCLUDE %LINE%},'ReadHeaderU','E_NO_MEMORY');
   Exit(E_NO_MEMORY);
  end;

  //load table
  if (FileRead(hArcData^.F,hArcData^.sysv_table.data^,size)<>size) then
  begin
   WriteStr({$INCLUDE %LINE%},'ReadHeaderU','E_EREAD');
   Exit(E_EREAD);
  end;

  goto retry;
 end else
 if (strlcomp(@hdr.FileName,@fspc_sig,SizeOf(fspc_sig))=0) then //another extension
 begin
  size:=hArcData^.last_hdr.FileOffset;

  WriteStr({$INCLUDE %LINE%},'EXTENSION',IntToStr(size));

  //skip
  offset:=FileSeek(hArcData^.F,size,fsFromCurrent);

  if (offset=-1) then
  begin
   WriteStr({$INCLUDE %LINE%},'ReadHeaderU','E_EREAD');
   Exit(E_EREAD);
  end;

  goto retry;
 end;

 FillChar(hArcData^.last_hdr.FileName,SizeOf(hArcData^.last_hdr.FileName),0);

 if (hdr.FileName[0]=#1) then //BSD extension
 begin
  size:=ord(hdr.FileName[1]); //len

  if (FileRead(hArcData^.F,hArcData^.last_hdr.FileName,size)<>size) then
  begin
   WriteStr({$INCLUDE %LINE%},'ReadHeaderU','E_EREAD');
   Exit(E_EREAD);
  end;

  Dec(hArcData^.last_hdr.FileOffset,size);
 end else
 if (hdr.FileName[0]='/') then //SYSV extension
 begin
  if (hArcData^.sysv_table.data=nil) or //table loaded?
     (hArcData^.sysv_table.Size<=0) then
   goto short;

  offset:=get_sysv_offset(@hdr);
  if (offset>hArcData^.sysv_table.Size) then
  begin
   goto short;
  end;

  hArcData^.last_hdr.FileName:=get_sysv_name(hArcData^.sysv_table.data,
                                             hArcData^.sysv_table.Size,
                                             offset);
 end else
 begin
  short:
  //short
  hArcData^.last_hdr.FileName:=get_file_name(@hdr);
 end;

 hArcData^.state:=rsNextFile;

 time:=get_time_stamp(@hdr);
 D:=UnixToDateTime(time);
 D:=UniversalTimeToLocal(D);

 WriteStr({$INCLUDE %LINE%},'FileTime',DateTimeToStr(D));

 if (HeaderData<>nil) then
 begin
  HeaderData^.FileName:=hArcData^.last_hdr.FileName;
  HeaderData^.FileSize:=get_file_size(@hdr);
  HeaderData^.FileTime:=DateTimeToDosDateTime(D);
 end;

 WriteStr({$INCLUDE %LINE%},'ReadHeaderU',get_file_name(@hdr));

 Result:=0;
end;

function CallProcData(hArcData:PArchFile;Size:Integer):Integer;
var
 A:RawByteString;
 W:WideString;
begin
 Result:=1;
 if (hArcData^.ProcessCbW<>nil) then
 begin
  W:=Utf8Decode(hArcData^.last_hdr.FileName);
  Result:=hArcData^.ProcessCbW(PWideChar(W),Size);
 end else
 if (hArcData^.ProcessCbA<>nil) then
 begin
  A:=Utf8toAnsi(hArcData^.last_hdr.FileName);
  Result:=hArcData^.ProcessCbA(PAnsiChar(A),Size);
 end;
end;

function ProcessFileU(hArcData:PArchFile;Operation:Integer;const DestPath,DestName:RawByteString):Integer;
const
 BufSize=64*1024;
var
 i,size,offset:Int64;
 S:RawByteString;
 F:THandle;
 buffer:Pointer;
begin
 hArcData^.state:=rsNextHeader;

 size:=hArcData^.last_hdr.FileOffset;

 WriteStr({$INCLUDE %LINE%},'ProcessFileU',IntToStr(size));

 if (Operation=PK_EXTRACT) then
 begin
  WriteStr({$INCLUDE %LINE%},'DestPath',DestPath);
  WriteStr({$INCLUDE %LINE%},'DestName',DestName);

  //DestName = full   DestPath = null
  //DestName = fname  DestPath = path

  if (DestPath='') then
  begin
   S:=DestName;
  end else
  begin
   S:=IncludeTrailingPathDelimiter(DestPath)+DestName;
  end;

  F:=FileCreate(S);
  if (F=THandle(-1)) then
  begin
   WriteStr({$INCLUDE %LINE%},'ProcessFileU','E_ECREATE');
   Exit(E_ECREATE);
  end;

  buffer:=AllocMem(BufSize);
  if (buffer=nil) then
  begin
   WriteStr({$INCLUDE %LINE%},'ProcessFileU','E_NO_MEMORY');
   FileClose(F);
   Exit(E_NO_MEMORY);
  end;

  while (size>0) do
  begin
   if (BufSize>size) then
    i:=size
   else
    i:=BufSize;

   if (FileRead(hArcData^.F,buffer^,i)<>i) then
   begin
    WriteStr({$INCLUDE %LINE%},'ProcessFileU','E_EREAD');
    FreeMem(buffer);
    FileClose(F);
    Exit(E_EREAD);
   end;

   if (FileWrite(F,buffer^,i)<>i) then
   begin
    WriteStr({$INCLUDE %LINE%},'ProcessFileU','E_EWRITE');
    FreeMem(buffer);
    FileClose(F);
    Exit(E_EWRITE);
   end;

   if (CallProcData(hArcData,i)=0) then
   begin
    WriteStr({$INCLUDE %LINE%},'ProcessFileU','E_EABORTED');
    FreeMem(buffer);
    FileClose(F);
    Exit(E_EABORTED);
   end;

   Dec(size,i);
  end;

  FreeMem(buffer);
  FileClose(F);

  offset:=FileSeek(hArcData^.F,0,fsFromCurrent);
 end else
 begin
  offset:=FileSeek(hArcData^.F,size,fsFromCurrent);
 end;

 if (offset=-1) or (offset>hArcData^.size) then
 begin
  WriteStr({$INCLUDE %LINE%},'ProcessFileU','E_EREAD');
  Exit(E_EREAD);
 end;

 Result:=0;
end;

function ReadHeader(hArcData:PArchFile;HeaderData:PHeaderData):Integer; stdcall;
var
 data:tHeaderDataU;
begin
 if (hArcData=nil)   or (ptrint(hArcData)=-1)   then Exit(E_EREAD);
 if (HeaderData=nil) or (ptrint(HeaderData)=-1) then Exit(E_EREAD);

 HeaderData^:=Default(tHeaderData);
 data:=Default(tHeaderDataU);

 if (hArcData^.state<>rsNextHeader) then
 begin
  Result:=ProcessFileU(hArcData,PK_SKIP,'','');
  if (Result<>E_SUCCESS) then Exit;
 end;

 Result:=ReadHeaderU(hArcData,@data);
 if (Result=E_SUCCESS) then
 begin
  HeaderData^.ArcName :=Utf8toAnsi(hArcData^.ArcName);
  HeaderData^.FileName:=Utf8toAnsi(data.FileName);

  HeaderData^.PackSize:=Integer(data.FileSize);
  HeaderData^.UnpSize :=Integer(data.FileSize);

  HeaderData^.FileTime:=data.FileTime;
  HeaderData^.FileAttr:=PK_FILE_ATTR_ARCHIVE;
 end;
end;

function ReadHeaderEx(hArcData:PArchFile;HeaderData:PHeaderDataEx):Integer; stdcall;
var
 data:tHeaderDataU;
begin
 if (hArcData=nil)   or (ptrint(hArcData)=-1)   then Exit(E_EREAD);
 if (HeaderData=nil) or (ptrint(HeaderData)=-1) then Exit(E_EREAD);

 HeaderData^:=Default(tHeaderDataEx);
 data:=Default(tHeaderDataU);

 if (hArcData^.state<>rsNextHeader) then
 begin
  Result:=ProcessFileU(hArcData,PK_SKIP,'','');
  if (Result<>E_SUCCESS) then Exit;
 end;

 Result:=ReadHeaderU(hArcData,@data);
 if (Result=E_SUCCESS) then
 begin
  HeaderData^.ArcName :=Utf8toAnsi(hArcData^.ArcName);
  HeaderData^.FileName:=Utf8toAnsi(data.FileName);

  PInt64(@HeaderData^.PackSize)^:=data.FileSize;
  PInt64(@HeaderData^.UnpSize )^:=data.FileSize;

  HeaderData^.FileTime:=data.FileTime;
  HeaderData^.FileAttr:=PK_FILE_ATTR_ARCHIVE;
 end;
end;

function ReadHeaderExW(hArcData:PArchFile;HeaderData:PHeaderDataExW):Integer; stdcall;
var
 data:tHeaderDataU;
begin
 if (hArcData=nil)   or (ptrint(hArcData)=-1)   then Exit(E_EREAD);
 if (HeaderData=nil) or (ptrint(HeaderData)=-1) then Exit(E_EREAD);

 HeaderData^:=Default(tHeaderDataExW);
 data:=Default(tHeaderDataU);

 if (hArcData^.state<>rsNextHeader) then
 begin
  Result:=ProcessFileU(hArcData,PK_SKIP,'','');
  if (Result<>E_SUCCESS) then Exit;
 end;

 Result:=ReadHeaderU(hArcData,@data);
 if (Result=E_SUCCESS) then
 begin
  HeaderData^.ArcName :=Utf8Decode(hArcData^.ArcName);
  HeaderData^.FileName:=Utf8Decode(data.FileName);

  PInt64(@HeaderData^.PackSize)^:=data.FileSize;
  PInt64(@HeaderData^.UnpSize )^:=data.FileSize;

  HeaderData^.FileTime:=data.FileTime;
  HeaderData^.FileAttr:=PK_FILE_ATTR_ARCHIVE;
 end;
end;

function ProcessFile(hArcData:PArchFile;Operation:Integer;DestPath,DestName:PAnsiChar):Integer; stdcall;
begin
 if (hArcData=nil) or (ptrint(hArcData)=-1) then Exit(E_EREAD);

 if (hArcData^.state<>rsNextFile) then
 begin
  Result:=ReadHeaderU(hArcData,nil);
  if (Result<>E_SUCCESS) then Exit;
 end;

 Result:=ProcessFileU(hArcData,Operation,AnsiToUtf8(DestPath),AnsiToUtf8(DestName));
end;

function ProcessFileW(hArcData:PArchFile;Operation:Integer;DestPath,DestName:PWideChar):Integer; stdcall;
begin
 if (hArcData=nil) or (ptrint(hArcData)=-1) then Exit(E_EREAD);

 if (hArcData^.state<>rsNextFile) then
 begin
  Result:=ReadHeaderU(hArcData,nil);
  if (Result<>E_SUCCESS) then Exit;
 end;

 Result:=ProcessFileU(hArcData,Operation,UTF8Encode(WideString(DestPath)),UTF8Encode(WideString(DestName)));
end;

exports
 OpenArchive,
 OpenArchiveW,
 CloseArchive,
 SetChangeVolProc,
 SetChangeVolProcW,
 SetProcessDataProc,
 SetProcessDataProcW,
 ReadHeader,
 ReadHeaderEx,
 ReadHeaderExW,
 ProcessFile,
 ProcessFileW;

begin
end.

