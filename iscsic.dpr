program iscsic;

{$APPTYPE CONSOLE}

uses
  SysUtils,windows,
  libiscsi in 'libiscsi.pas';

var
log:boolean=false;
len:int64=0;
offset:int64=0;
fname:string='';

function GetEnvVarValue(const VarName: string): string;
var
  BufSize: Integer;  // buffer size required for value
begin
  // Get required buffer size (inc. terminal #0)
  BufSize := GetEnvironmentVariable(
    PChar(VarName), nil, 0);
  if BufSize > 0 then
  begin
    // Read env var value into result string
    SetLength(Result, BufSize - 1);
    GetEnvironmentVariable(PChar(VarName),
      PChar(Result), BufSize);
  end
  else
    // No such environment variable
    Result := '';
end;

procedure iscsi_log_to_stderr(level:integer;msg:pchar);cdecl;
begin
writeln('log:'+strpas(msg));
end;

function connect(iscsi_url:string):boolean;
var
portal,target:pchar;
lun:integer;
begin

if iscsi_url='' then exit;
init;

//
if iscsi=nil then iscsi := iscsi_create_context('iqn.2007-10.com.github:erwan');

if iscsi_is_logged_in(iscsi)=1 then
  begin
  writeln('please disconnect first');
  exit;
  end;

if log=true then
begin
iscsi_set_log_level(iscsi,10);
iscsi_set_log_fn(iscsi,@iscsi_log_to_stderr);
end;
//

url := iscsi_parse_full_url(iscsi, pchar(iscsi_url));
if url=nil then
  begin
  writeln('could not parse '+ iscsi_url);
  exit;
  end;

portal:=Piscsi_url(url)^.portal ;
target:=Piscsi_url(url)^.target ;
lun:=Piscsi_url(url)^.lun ;

if iscsi_set_targetname(iscsi,target )<>0 then writeln('iscsi_set_targetname failed');
if iscsi_set_session_type(iscsi, ISCSI_SESSION_NORMAL)<>0 then writeln('iscsi_set_targetname failed');
if iscsi_set_header_digest(iscsi, ISCSI_HEADER_DIGEST_CRC32C_NONE)<>0 then writeln('iscsi_set_targetname failed');
//
//ret:=iscsi_connect_sync(iscsi,portal);
//below is quicker
//will connect to the portal, login, and verify that the lun is available
if iscsi_full_connect_sync (iscsi,portal,lun)<>0 then
  begin
  writeln('error:'+strpas(iscsi_get_error(iscsi)));
  exit;
  end;

//
{
//not needed if you used iscsi_full_connect_sync
ret:=iscsi_login_sync(iscsi);
if ret<>0 then
  begin
  memo1.Lines.Add(strpas(iscsi_get_error(iscsi)));
  exit;
  end;
}
result:=true;
end;


function iscsi_write(iscsi_url:string;offset:int64=0;len:int64=0;filename:string=''):boolean;
var
//task,
data:pointer;
lun,status,byteswritten:integer;
buf_size:dword;
lun_size,lba,total:int64;
fn:string;
hfile:thandle;
bytesread:cardinal;
begin
if iscsi =nil then exit;

lun:=Piscsi_url(url)^.lun ;
buf_size:=1024*256; //256k max, above will crash iscsi service
lba:=offset div block_size ;
lun_size:=(total_lba+1)*block_size;
if len=0 then else lun_size:=offset+len;
total:=0;

data:=allocmem(buf_size);

fn:='lun#'+inttostr(lun)+'.img';
if filename<>'' then fn:=filename;
hFile := CreateFile(PChar(fn), GENERIC_READ, FILE_SHARE_WRITE, nil, OPEN_EXISTING , FILE_ATTRIBUTE_NORMAL, 0);
if not FileExists(fn) then
  begin
  writeln(filename+' does not exist');
  exit;
  end;

//note that offset applies to iscsi target, not to source file

while offset<lun_size   do  
begin

if readfile(hFile, data^, buf_size, bytesread, nil)=false then
      begin
      writeln('writefile error');
      break;
      end;

status:=write16(lun,lba,data,bytesread,byteswritten );

if status<>0 then
  begin
  writeln('status='+inttostr(status));
  writeln('error:'+strpas(iscsi_get_error(iscsi)));
  exit;
  end
  else
  begin
  write('.');
  total:=total+ byteswritten;
  end;

inc(offset,buf_size);
lba:=offset div block_size;
end; //while 1=1 do

freemem(data,buf_size);
closehandle(hfile);
writeln;
writeln('done ... '+inttostr(total)+ ' written to iscsi ...');


end;




function iscsi_read(iscsi_url:string;offset:int64=0;len:int64=0;filename:string=''):boolean;
var
data:pointer;
lun,status,bytesread:integer;
ptr,buf_size,i:dword;
lba,lun_size,total:int64;
hFile:thandle;
byteswritten:cardinal;
fn:string;
begin
if iscsi =nil then exit;



lun:=Piscsi_url(url)^.lun ;
lba:=offset div block_size ;
data:=nil;
buf_size:=1024*256;
lun_size:=(total_lba+1)*block_size;
if len=0 then  else lun_size:=offset+len;
total:=0;

fn:='lun#'+inttostr(lun)+'.img';
if filename<>'' then fn:=filename;


hFile := CreateFile(PChar(fn), GENERIC_WRITE, FILE_SHARE_WRITE, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);


while offset<lun_size   do  
begin
//not sure the below is needed...
//if offset+size>lun_size then size:=lun_size-offset;
//the below could be consuming, we could allocate the buffer only one?
data:=allocmem(buf_size);
status:=read16(lun,lba,buf_size,data,bytesread);
if bytesread <> buf_size then writeln('??');

//if task=nil then
if status<>0 then
  begin
  writeln('status='+inttostr(status));
  writeln('error:'+strpas(iscsi_get_error(iscsi)));
  break;
  end
  else
  begin
  //writeln('status:'+inttostr(status));
  //writeln('bytes read:'+inttostr(bytesread ));
  //writeln('pos:'+inttostr(pos));
  write('.');
  if bytesread>0 then
    begin
    if WriteFile(hFile, data^, bytesread, byteswritten, nil)=false then
      begin
      writeln('writefile error');
      break;
      end;
    total:=total+bytesread;
    freemem(data,bytesread);
    end;//if bytesread>0 then
  end;//if status<>0 then
inc(offset,buf_size);
lba:=offset div block_size;
end; //while 1=1 do
closehandle(hfile);
writeln;
writeln('done ...'+inttostr(total)+' read from iscsi ...');
end;



function capacity(iscsi_url:string):boolean;
var
lun:integer;

begin
result:=false;



lun:=Piscsi_url(url)^.lun ;

if readcapacity10(lun)=0 then
begin
  writeln('lba size:'+inttostr(total_lba));
  writeln('block size:'+inttostr(block_size));
  writeln('total size:'+inttostr((total_lba+1)*block_size));
  result:=true;
end
else writeln('error:'+strpas(iscsi_get_error(iscsi)));

end;

function discover(iscsi_url:string):boolean;
var
ret,lun:integer;
da,next:pointer;
portal:pchar;
begin
result:=false;
if iscsi_url='' then exit;

init;

//
if iscsi=nil then iscsi := iscsi_create_context('iqn.2007-10.com.github:erwan');

if iscsi_is_logged_in(iscsi)=1 then
  begin
  writeln('please disconnect first');
  exit;
  end;

if log=true then
  begin
  iscsi_set_log_level(iscsi,10);
  iscsi_set_log_fn(iscsi,@iscsi_log_to_stderr);
  end;
//
if pos('iscsi://',lowercase(iscsi_url))=0 then iscsi_url:='iscsi://'+iscsi_url;
//
url := iscsi_parse_portal_url(iscsi, pchar(iscsi_url));
if url=nil then
  begin
  writeln('could not parse '+ iscsi_url);
  exit;
  end;

portal:=Piscsi_url(url)^.portal ;
//
if iscsi_set_session_type(iscsi, ISCSI_SESSION_DISCOVERY )<>0 then
  begin
  writeln('iscsi_set_targetname failed');
  exit;
  end;
//
ret:=iscsi_connect_sync(iscsi,portal);
if ret<>0 then
  begin
  writeln('error:'+strpas(iscsi_get_error(iscsi)));
  exit;
  end;
//
ret:=iscsi_login_sync(iscsi);
if ret<>0 then
  begin
  writeln('error:'+strpas(iscsi_get_error(iscsi)));
  exit;
  end;
//
da:=iscsi_discovery_sync(iscsi);
if da<>nil then
  begin
  next:=da;
  while next<>nil do
    begin
    writeln('target:'+'iscsi://'+portal+'/'+Piscsi_discovery_address(next)^.target_name );
    next:=Piscsi_discovery_address(next)^.next ;
    {
    if Piscsi_discovery_address(da)^.portals <>nil
      then writeln(piscsi_target_portal(Piscsi_discovery_address(da)^.portals)^.portal );
    }
    end;
  iscsi_free_discovery_data(iscsi,da);
  end;
//
result:=true;
end;

procedure terminate;
begin
if iscsi =nil then exit;
//
if url<>nil then iscsi_destroy_url(url);
iscsi_disconnect(iscsi);
//
iscsi_destroy_context(iscsi);
iscsi:=nil;
end;

begin
  { TODO -oUser -cConsole Main : Insert code here }
  writeln('iscsic 0.1 by erwan2212@gmail.com');
  if paramcount=0 then
  begin
  writeln('iscsic discover iscsi-portal');
  writeln('iscsic capacity iscsi-url');
  writeln('iscsic read iscsi-url [offset] [len] [fname]');
  writeln('iscsic write iscsi-url [offset] [len] [fname]');
  writeln('set dos variable log=true to get verbosity'); 
  exit;
  end;

  //if pos('verbose',cmdline)>0 then log:=true;
  if GetEnvVarValue('log')='true' then log:=true;

  if lowercase(paramstr(1))='discover' then
    begin
    if paramcount>=2 then discover(paramstr(2));
    end;

  if lowercase(paramstr(1))='capacity' then
    begin
    if paramcount>=2 then
      begin
      if connect(paramstr(2))=false then exit;
      capacity(paramstr(2));
      end;
    end;

  if lowercase(paramstr(1))='read' then
    begin
    if paramcount>=2 then
      begin
      if connect(paramstr(2))=false then exit;
      if readcapacity10(Piscsi_url(url)^.lun)<>0 then exit;      
      if paramcount>=3 then offset:=strtoint64(paramstr(3));
      if paramcount>=4 then len:=strtoint64(paramstr(4));
      iscsi_read(paramstr(2),offset,len);
      end;
    end;

  if lowercase(paramstr(1))='write' then
    begin
    if paramcount>=2 then
      begin
      if connect(paramstr(2))=false then exit;
      if readcapacity10(Piscsi_url(url)^.lun)<>0 then exit;      
      if paramcount>=3 then offset:=strtoint64(paramstr(3));
      if paramcount>=4 then len:=strtoint64(paramstr(4));
      if paramcount>=5 then fname:=paramstr(5);
      iscsi_write(paramstr(2),offset,len,fname);
      end;
    end;

//
terminate;
end.
