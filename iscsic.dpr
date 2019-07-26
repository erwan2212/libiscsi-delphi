program iscsic;

{$APPTYPE CONSOLE}

uses
  SysUtils,windows,
  libiscsi in 'libiscsi.pas';

var
log:boolean=false;

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

function read(iscsi_url:string;pos:int64=0):boolean;
var
data:pointer;
lun,status,bytesread:integer;
ptr,size,i:dword;
lba:int64;
hFile:thandle;
byteswritten:cardinal;
begin
if iscsi =nil then exit;



lun:=Piscsi_url(url)^.lun ;
pos:=0;lba:=0;
data:=nil;
size:=1024*256;

hFile := CreateFile(PChar('disk.img'), GENERIC_WRITE, FILE_SHARE_WRITE, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);


while lba<=total_lba do
begin

data:=allocmem(size);
status:=read16(lun,lba,size,data,bytesread);

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
    //for i:=0 to size -1 do write(pchar(pointer(dword(data)+1)));
    if WriteFile(hFile, data^, bytesread, byteswritten, nil)=false then
      begin
      writeln('writefile error');
      break;
      end;
    freemem(data,bytesread);
    end;//if bytesread>0 then
  end;//if status<>0 then
inc(pos,size);
lba:=pos div block_size;
end; //while 1=1 do
closehandle(hfile);
writeln('done');
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
//url := iscsi_parse_portal_url(iscsi, pchar(txturl.text));
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
    writeln('target:'+'iscsi://'+portal+'/'+Piscsi_discovery_address(da)^.target_name );
    next:=Piscsi_discovery_address(da)^.next ;
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
  writeln('iscsic discover iscsi-url');
  exit;
  end;

  if lowercase(paramstr(1))='discover' then
    begin
    if paramcount=2 then discover(paramstr(2));
    end;

  if lowercase(paramstr(1))='capacity' then
    begin
    if paramcount=2 then
      begin
      if connect(paramstr(2))=false then exit;
      capacity(paramstr(2));
      end;
    end;

  if lowercase(paramstr(1))='read' then
    begin
    if paramcount=2 then
      begin
      if connect(paramstr(2))=false then exit;
      if readcapacity10(Piscsi_url(url)^.lun)<>0 then exit;      
      read(paramstr(2));
      end;
    end;

//
terminate;
end.
