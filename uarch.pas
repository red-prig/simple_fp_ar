unit uarch;

{$mode objfpc}{$H+}

interface

type
 Parch_sig=^Tarch_sig;
 Tarch_sig=array[0..7] of AnsiChar;

 Parch_header=^Tarch_header;
 Tarch_header=packed record
  FileName :array[0..15] of AnsiChar;
  timestamp:array[0..11] of AnsiChar;
  OwnerID  :array[0..5]  of AnsiChar;
  GroupID  :array[0..5]  of AnsiChar;
  FileMode :array[0..7]  of AnsiChar; //octet
  FileSize :array[0..9]  of AnsiChar;
  Ending   :array[0..1]  of AnsiChar;
 end;

const
 arch_sig:Tarch_sig='!<arch>'#$0A;
 hend_sig:array[0..1] of AnsiChar=#$60#$0A;
 fspc_sig:array[0..1] of AnsiChar='/'#$20;
 ftbl_sig:array[0..2] of AnsiChar='//'#$20;

function get_time_stamp (hdr:Parch_header):Int64;
function get_file_size  (hdr:Parch_header):Int64;
function get_next_offset(hdr:Parch_header):Int64;
function get_file_name  (hdr:Parch_header):RawByteString;
function get_sysv_offset(hdr:Parch_header):Int64;
function get_sysv_name  (P:PAnsiChar;size,offset:Integer):RawByteString;

implementation

uses
 SysUtils;

function get_time_stamp(hdr:Parch_header):Int64;
begin
 if not TryStrToQWORD(Trim(hdr^.timestamp),QWORD(Result)) then Exit(0);
end;

function get_file_size(hdr:Parch_header):Int64;
begin
 if not TryStrToQWORD(Trim(hdr^.FileSize),QWORD(Result)) then Exit(0);
end;

function get_next_offset(hdr:Parch_header):Int64;
begin
 if not TryStrToQWORD(Trim(hdr^.FileSize),QWORD(Result)) then Exit(0);
 Result:=(Result+1) and (not Int64(1)); //align 2
end;

function TrimName(const S:RawByteString):RawByteString;
var
 Ofs, Len: sizeint;
begin
 len := Length(S);
 while (Len>0) and (S[Len]<=' ') do
 begin
  Dec(Len);
 end;
 if (S[Len]='/') then
 begin
  Dec(Len);
 end;
 Ofs := 1;
 while (Ofs<=Len) and (S[Ofs]<=' ') do
 begin
  Inc(Ofs);
 end;
 if (S[Ofs]='/') then
 begin
  Inc(Ofs);
 end;
 result := Copy(S, Ofs, 1 + Len - Ofs);
end;

function get_file_name(hdr:Parch_header):RawByteString;
begin
 Result:=TrimName(hdr^.FileName);
end;

function TrimOffset(const S:RawByteString):RawByteString;
begin
 Result:=S;
 if (Result[1]='/') then
 begin
  Delete(Result,1,1);
 end;
 Result:=Trim(Result);
end;

function get_sysv_offset(hdr:Parch_header):Int64;
begin
 if not TryStrToQWORD(TrimOffset(hdr^.FileName),QWORD(Result)) then Exit(0);
end;

function get_sysv_name(P:PAnsiChar;size,offset:Integer):RawByteString;
var
 i:sizeint;
begin
 Result:='';
 Inc(P   ,offset);
 Dec(size,offset);
 i:=0;
 while (i<size) do
 begin
  if (P[i]=#$0A) then Break;
  Inc(i);
 end;

 SetLength(Result,i);
 Move(P^,PAnsiChar(Result)^,i);

 Result:=TrimName(Result);
end;

end.

