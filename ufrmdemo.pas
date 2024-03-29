unit ufrmdemo;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,libiscsi;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Memo1: TMemo;
    txturl: TEdit;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Memo1DblClick(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;





type tarray4 =  array[0..3] of byte;

var
  Form1: TForm1;

implementation

{$R *.dfm}

{
| is called bitwise OR operator.
|| is called logical OR operator.
}



function scsi_get_uint32(d:dword):dword;
var
val:dword;
c:tarray4;
begin
copymemory(@c[0],@d,4);
	val := c[0];
	val := (val shl 8) or c[1];
	val := (val shl 8) or c[2];
	val := (val shl 8) or c[3];
	result:= val;
end;



procedure iscsi_co_generic_cb(iscsi_:pointer;status:integer;command_data:pointer;opaque:pointer);cdecl;
var
task:pointer;
begin
form1.Memo1.Lines.Add('iscsi_co_generic_cb');
task:= command_data;
if status<>0 then
  begin
  form1.Memo1.Lines.Add('status:'+inttohex(status,8));
  form1.memo1.Lines.Add('error:'+strpas(iscsi_get_error(iscsi_)));
  if task<>nil then
    begin
    if Pscsi_task(task)^.cdb_size >0
      then form1.Memo1.Lines.Add (inttohex(Pscsi_task(task)^.cdb [0],1));
    end;
  scsi_free_scsi_task (task);
  end;

if status=0 then
  begin
  form1.Memo1.Lines.Add('success'); 
  end;

//write successfull
//free task
//send another write task
//set iov

//read
//look in datain.data ?

end;

{/*
 * This function is to set the debugging level where level is
 *
 * 0  = disabled (default)
 * 1  = errors only
 * 2  = connection related info
 * 3  = user set variables
 * 4  = function calls
 * 5  = ...
 * 10 = everything
 */}

procedure iscsi_log_to_stderr(level:integer;msg:pchar);cdecl;
begin
form1.Memo1.Lines.Add('log:'+strpas(msg));
end;





procedure TForm1.Button1Click(Sender: TObject);
var
ret,lun,i:integer;

portal,target:pchar;
returned_lba:int64;

begin
memo1.Clear ;
init;

//
if iscsi=nil then iscsi := iscsi_create_context('iqn.2007-10.com.github:erwan');

if iscsi_is_logged_in(iscsi)=1 then
  begin
  memo1.Lines.Add('please disconnect first');
  exit;
  end;

iscsi_set_log_level(iscsi,10);
iscsi_set_log_fn(iscsi,@iscsi_log_to_stderr);
//
url := iscsi_parse_full_url(iscsi, pchar(txturl.text));
if url=nil then
  begin
  memo1.Lines.Add('could not parse '+ txturl.text);
  exit;
  end;

portal:=Piscsi_url(url)^.portal ;
target:=Piscsi_url(url)^.target ;
lun:=Piscsi_url(url)^.lun ;

if iscsi_set_targetname(iscsi,target )<>0 then memo1.Lines.Add('iscsi_set_targetname failed');
if iscsi_set_session_type(iscsi, ISCSI_SESSION_NORMAL)<>0 then memo1.Lines.Add('iscsi_set_targetname failed');
if iscsi_set_header_digest(iscsi, ISCSI_HEADER_DIGEST_CRC32C_NONE)<>0 then memo1.Lines.Add('iscsi_set_targetname failed');
//
//ret:=iscsi_connect_sync(iscsi,portal);
//below is quicker
//will connect to the portal, login, and verify that the lun is available
ret:=iscsi_full_connect_sync (iscsi,portal,lun);
if ret<>0 then
  begin
  memo1.Lines.Add('error:'+strpas(iscsi_get_error(iscsi)));
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

if readcapacity10(lun)=0 then
begin
  Memo1.Lines.Add('lba size:'+inttostr(total_lba));
  Memo1.Lines.Add('block size:'+inttostr(block_size));
  Memo1.Lines.Add('total size:'+inttostr((total_lba+1)*block_size));
end
else memo1.Lines.Add('error:'+strpas(iscsi_get_error(iscsi)));

end;

procedure TForm1.Button2Click(Sender: TObject);
begin
if iscsi =nil then exit;
//
if url<>nil then iscsi_destroy_url(url);
iscsi_disconnect(iscsi);
//
iscsi_destroy_context(iscsi);
iscsi:=nil;
end;

procedure TForm1.Button3Click(Sender: TObject);
var
ret,lun,i:integer;
task:pointer;
buffer:array [0..512-1] of byte;
buffer2:array [0..2048-1] of byte;
pv:pointer;
iov:tscsi_iovec ;

begin
if iscsi =nil then exit;
if iscsi_is_logged_in(iscsi)<>1 then
  begin
  Memo1.Lines.Add('not logged in');
  exit;
  end;

lun:=Piscsi_url(url)^.lun ;


//write attempt
fillchar(buffer,512,$ff);
//printf("write the block using an iovector\n");
for i:=0 to 512-1 do buffer[i] := (511 - i) and $ff;

task:=nil;
//getmem(pv,512);
//task:=iscsi_write16_task(iscsi,lun,0,@buffer[0],sizeof(buffer),512,0,0,0,0,0,@iscsi_co_generic_cb,nil);
task:=iscsi_write16_sync(iscsi,lun,0,@buffer[0],sizeof(buffer),block_size,0,0,0,0,0);

//task:=iscsi_write10_task(iscsi,lun,0,nil,sizeof(buffer),512,0,0,0,0,0,@iscsi_co_generic_cb,nil);
//scsi_task_set_iov_out(task, @iov, 1); will be needed in the CB  if write buffer=nil
iov.iov_base :=@buffer[0];
iov.iov_len :=sizeof(buffer);
//task:=iscsi_write10_iov_task (iscsi,lun,0,nil,sizeof(buffer),512,0,0,0,0,0,@iscsi_co_generic_cb,nil,@iov,1);
if task=nil then
  begin
  memo1.Lines.Add('task=nil');
  memo1.Lines.Add('error:'+strpas(iscsi_get_error(iscsi)));
  end
  else
  begin
  memo1.Lines.Add('status:'+inttostr(Pscsi_task(task)^.status));
  memo1.Lines.Add('bytes written:'+inttostr(Pscsi_task(task)^.expxferlen));
  scsi_free_scsi_task(task);
  end;
//if write buffer is nil
//scsi_task_set_iov_out(task, @iov, 1);


end;

procedure TForm1.Memo1DblClick(Sender: TObject);
begin
memo1.Clear ;
end;

procedure TForm1.Button4Click(Sender: TObject);
var
i,lun:integer;
iov:tscsi_iovec ;
task,data:pointer;
buffer:array [0..512-1] of byte;
ptr:dword;
begin
if iscsi =nil then exit;
if iscsi_is_logged_in(iscsi)<>1 then
  begin
  Memo1.Lines.Add('not logged in');
  exit;
  end;
  
lun:=Piscsi_url(url)^.lun ;
//read attempt

fillchar(buffer,512,$ff);
task:=nil;
i:=0;
//for i:=0 to 511-1 do
task:=iscsi_read16_sync  (iscsi,lun,0,sizeof(buffer),block_size,0,0,0,0,0);
//iov.iov_base :=@buffer[0];
//iov.iov_len :=sizeof(buffer);
//task:=iscsi_read10_iov_task(iscsi,lun,0,sizeof(buffer),512,0,0,0,0,0,@iscsi_co_generic_cb,nil,@iov,1);
if task=nil then
  begin
  memo1.Lines.Add('task=nil');
  memo1.Lines.Add('error:'+strpas(iscsi_get_error(iscsi)));
  exit;
  end
  else
  begin
  memo1.Lines.Add('status:'+inttostr(Pscsi_task(task)^.status));
  memo1.Lines.Add('bytes read:'+inttostr(Pscsi_task(task)^.datain.size ));
  //lets get a point to our data
  CopyMemory(@ptr,@Pscsi_task(task)^.datain.data[0],4);
  //SetLength (buffer,Pscsi_task(task)^.datain.size);
  CopyMemory(@buffer[0],pointer(ptr),Pscsi_task(task)^.datain.size);
  //if buffer[0]=0 then ;
  //data:=allocmem(Pscsi_task(task)^.datain.size);
  //getmem(data,Pscsi_task(task)^.datain.size);
  //CopyMemory(data,pointer(ptr),Pscsi_task(task)^.datain.size);
  //freemem(data);
  scsi_free_scsi_task(task);
  end;

end;

procedure TForm1.Button5Click(Sender: TObject);
var
task,data:pointer;
lun,status,bytesread:integer;
ptr,size:dword;
lba,pos:int64;
begin
if iscsi =nil then exit;

lun:=Piscsi_url(url)^.lun ;
pos:=0;lba:=0;
size:=1024*256;

//1073741824
while lba<=total_lba do
begin

//task:=iscsi_read16_sync  (iscsi,lun,lba,size,512,0,0,0,0,0);
status:=read16(lun,lba,size,data,bytesread); 

//if task=nil then
if status<>0 then
  begin
  memo1.Lines.Add('status='+inttostr(status));
  memo1.Lines.Add('error:'+strpas(iscsi_get_error(iscsi)));
  exit;
  end
  else
  begin
  memo1.Lines.Add('status:'+inttostr(status));
  memo1.Lines.Add('bytes read:'+inttostr(bytesread ));
  memo1.Lines.Add('pos:'+inttostr(pos));
  if bytesread>0 then
    begin


    freemem(data,bytesread);
    end;

  end;
inc(pos,size);
lba:=pos div block_size;
end; //while 1=1 do

end;

procedure TForm1.Button6Click(Sender: TObject);
var
//task,
data:pointer;
lun,status,byteswritten:integer;
size:dword;
lba,pos:int64;
begin
if iscsi =nil then exit;

lun:=Piscsi_url(url)^.lun ;
size:=1024*256; //256k max, above will crash iscsi service
data:=allocmem(size);

pos:=0;lba:=0;

while lba<=total_lba do
begin



//task:=iscsi_write16_sync(iscsi,lun,lba,data,size,512,0,0,0,0,0);

status:=write16(lun,lba,data,size,byteswritten);

//if task=nil then
if status<>0 then
  begin
  //memo1.Lines.Add('task=nil');
  memo1.Lines.Add('status='+inttostr(status));
  memo1.Lines.Add('error:'+strpas(iscsi_get_error(iscsi)));
  exit;
  end
  else
  begin
  memo1.Lines.Add('status:'+inttostr(status));
  memo1.Lines.Add('bytes written:'+inttostr(byteswritten));
  memo1.Lines.Add('pos:'+inttostr(pos));

  end;

inc(pos,size);
lba:=pos div block_size;
end; //while 1=1 do

freemem(data,size);

end;

procedure TForm1.Button7Click(Sender: TObject);
var
ret,i:integer;
task:pointer;
portal:pchar;
returned_lba:int64;
da,next:pointer;
begin
memo1.Clear ;
init;

//
if iscsi=nil then iscsi := iscsi_create_context('iqn.2007-10.com.github:erwan');

if iscsi_is_logged_in(iscsi)=1 then
  begin
  memo1.Lines.Add('please disconnect first');
  exit;
  end;

iscsi_set_log_level(iscsi,10);
iscsi_set_log_fn(iscsi,@iscsi_log_to_stderr);
//
url := iscsi_parse_portal_url(iscsi, pchar(txturl.text));
//url := iscsi_parse_full_url(iscsi, pchar(txturl.text));

portal:=Piscsi_url(url)^.portal ;

//
if iscsi_set_session_type(iscsi, ISCSI_SESSION_DISCOVERY )<>0 then memo1.Lines.Add('iscsi_set_targetname failed');
//
ret:=iscsi_connect_sync(iscsi,portal);
if ret<>0 then
  begin
  memo1.Lines.Add('error:'+strpas(iscsi_get_error(iscsi)));
  exit;
  end;
//
ret:=iscsi_login_sync(iscsi);
if ret<>0 then
  begin
  memo1.Lines.Add('error:'+strpas(iscsi_get_error(iscsi)));
  exit;
  end;
//
da:=iscsi_discovery_sync(iscsi);
if da<>nil then
  begin
  next:=da;
  while next<>nil do
    begin
    memo1.Lines.Add('iscsi://'+portal+'/'+Piscsi_discovery_address(da)^.target_name );
    {//only in a normal session
    task:=iscsi_reportluns_sync(iscsi,0,16);
    if task<>nil then
      begin
      memo1.Lines.Add(inttostr(Pscsi_task(task)^.datain.size ));
      scsi_free_scsi_task(task);
      end;
    }
    next:=Piscsi_discovery_address(da)^.next ;
    {
    if Piscsi_discovery_address(da)^.portals <>nil
      then memo1.Lines.Add(piscsi_target_portal(Piscsi_discovery_address(da)^.portals)^.portal );
    }
    end;
  iscsi_free_discovery_data(iscsi,da);
  end;
//
//memo1.Lines.Add('ok');
end;




end.
