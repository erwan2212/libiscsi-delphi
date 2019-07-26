//delphi unit for https://github.com/sahlberg/libiscsi

{
/*
 * Syntax for normal and portal/discovery URLs.
 */
#define ISCSI_URL_SYNTAX "\"iscsi://[<username>[%<password>]@]" \
  "<host>[:<port>]/<target-iqn>/<lun>\""
#define ISCSI_PORTAL_URL_SYNTAX "\"iscsi://[<username>[%<password>]@]" \
  "<host>[:<port>]\""
}

//enum scsi_opcode
{
	SCSI_OPCODE_TESTUNITREADY      = 0x00,
	SCSI_OPCODE_READ6              = 0x08,
	SCSI_OPCODE_INQUIRY            = 0x12,
	SCSI_OPCODE_MODESELECT6        = 0x15,
	SCSI_OPCODE_RESERVE6           = 0x16,
	SCSI_OPCODE_RELEASE6           = 0x17,
	SCSI_OPCODE_MODESENSE6         = 0x1a,
	SCSI_OPCODE_STARTSTOPUNIT      = 0x1b,
	SCSI_OPCODE_PREVENTALLOW       = 0x1e,
	SCSI_OPCODE_READCAPACITY10     = 0x25,
	SCSI_OPCODE_READ10             = 0x28,
	SCSI_OPCODE_WRITE10            = 0x2A,
	SCSI_OPCODE_WRITE_VERIFY10     = 0x2E,
	SCSI_OPCODE_VERIFY10           = 0x2F,
	SCSI_OPCODE_PREFETCH10         = 0x34,
	SCSI_OPCODE_SYNCHRONIZECACHE10 = 0x35,
	SCSI_OPCODE_READ_DEFECT_DATA10 = 0x37,
	SCSI_OPCODE_WRITE_SAME10       = 0x41,
	SCSI_OPCODE_UNMAP              = 0x42,
	SCSI_OPCODE_READTOC            = 0x43,
	SCSI_OPCODE_SANITIZE           = 0x48,
	SCSI_OPCODE_MODESELECT10       = 0x55,
	SCSI_OPCODE_MODESENSE10        = 0x5A,
	SCSI_OPCODE_PERSISTENT_RESERVE_IN  = 0x5E,
	SCSI_OPCODE_PERSISTENT_RESERVE_OUT = 0x5F,
	SCSI_OPCODE_EXTENDED_COPY      = 0x83,
	SCSI_OPCODE_RECEIVE_COPY_RESULTS = 0x84,
	SCSI_OPCODE_READ16             = 0x88,
	SCSI_OPCODE_COMPARE_AND_WRITE  = 0x89,
	SCSI_OPCODE_WRITE16            = 0x8A,
	SCSI_OPCODE_ORWRITE            = 0x8B,
	SCSI_OPCODE_WRITE_VERIFY16     = 0x8E,
	SCSI_OPCODE_VERIFY16           = 0x8F,
	SCSI_OPCODE_PREFETCH16         = 0x90,
	SCSI_OPCODE_SYNCHRONIZECACHE16 = 0x91,
	SCSI_OPCODE_WRITE_SAME16       = 0x93,
	SCSI_OPCODE_WRITE_ATOMIC16     = 0x9C,
	SCSI_OPCODE_SERVICE_ACTION_IN  = 0x9E,
	SCSI_OPCODE_REPORTLUNS         = 0xA0,
	SCSI_OPCODE_MAINTENANCE_IN     = 0xA3,
	SCSI_OPCODE_READ12             = 0xA8,
	SCSI_OPCODE_WRITE12            = 0xAA,
	SCSI_OPCODE_WRITE_VERIFY12     = 0xAE,
	SCSI_OPCODE_VERIFY12           = 0xAF,
	SCSI_OPCODE_READ_DEFECT_DATA12 = 0xB7
}

//enum scsi_status
{
	SCSI_STATUS_GOOD                 = 0,
	SCSI_STATUS_CHECK_CONDITION      = 2,
	SCSI_STATUS_CONDITION_MET        = 4,
	SCSI_STATUS_BUSY                 = 8,
	SCSI_STATUS_RESERVATION_CONFLICT = 0x18,
	SCSI_STATUS_TASK_SET_FULL        = 0x28,
	SCSI_STATUS_ACA_ACTIVE           = 0x30,
	SCSI_STATUS_TASK_ABORTED         = 0x40,
	SCSI_STATUS_REDIRECT             = 0x101,
	SCSI_STATUS_CANCELLED            = 0x0f000000,
	SCSI_STATUS_ERROR                = 0x0f000001,
	SCSI_STATUS_TIMEOUT              = 0x0f000002
}


unit libiscsi;

interface

uses windows,sysutils,winsock;

  type
  UINT8 = System.Byte;
  UINT16 = System.Word;
  UINT32 = System.Longword;
{$IFNDEF UINT64}
  UINT64 = System.INT64;
{$ENDIF}
  INT16 = System.Smallint;
  INT32 = System.Longint;
  INT64 = System.INT64;
  TUINT32Array = array of UINT32;
  PUINT32 = ^UINT32;
  PBYTE = ^byte;

 const
  MAX_STRING_SIZE =255;
  SCSI_CDB_MAX_SIZE =16;

  ISCSI_SESSION_DISCOVERY = 1;
  ISCSI_SESSION_NORMAL    = 2;

  ISCSI_HEADER_DIGEST_NONE        = 0;
	ISCSI_HEADER_DIGEST_NONE_CRC32C = 1;
	ISCSI_HEADER_DIGEST_CRC32C_NONE = 2;
	ISCSI_HEADER_DIGEST_CRC32C      = 3;

type tiscsi_target_portal =record
       next :pointer;
       portal:pchar
end;
piscsi_target_portal = ^tiscsi_target_portal;

type tiscsi_discovery_address =record
       next:pointer;
       target_name:pchar;
       portals:pointer;
end;
Piscsi_discovery_address = ^tiscsi_discovery_address;


{/* struct scsi_iovec follows the POSIX struct iovec
   definition and *MUST* never change. */}
type tscsi_iovec =record
    iov_base:pointer;
    iov_len:integer;
end;
Pscsi_iovec = ^tscsi_iovec;

type tiscsi_url =record
       portal:array [0..MAX_STRING_SIZE ] of char;
       target:array [0..MAX_STRING_SIZE ] of char;
       user:array [0..MAX_STRING_SIZE ] of char;
       passwd:array [0..MAX_STRING_SIZE ] of char;
       target_user:array [0..MAX_STRING_SIZE ] of char;
       target_passwd:array [0..MAX_STRING_SIZE ] of char;
       lun:integer;
       iscsi:pointer;
       transport:integer; //enum iscsi_transport_type
end;
Piscsi_url = ^tiscsi_url;

//The packed keyword tells Delphi to minimise the storage taken up by the defined object.
type tscsi_sense = record
	error_type:byte;
	key:integer;
	ascq:integer;

	{/*
	 * Sense specific descriptor. See also paragraph "Sense key specific
	 * sense data descriptor" in SPC.
	 */}
	            {
              sense_specific:byte;
	            ill_param_in_cdb:byte;
	            bit_pointer_valid:byte;
              }
              sense_bits:word;
	            bit_pointer:byte;
	            field_pointer:uint16;
end;

type tscsi_data = record
       size:uint;
       data:array [0..0] of byte;
end ;
Pscsi_data = ^tscsi_data;

type tscsi_task= record
   status:integer;
 	 cdb_size:integer;
	 xfer_dir:integer;
	 expxferlen:integer;
   cdb:array [0..SCSI_CDB_MAX_SIZE-1] of byte;
   residual_status:integer; //enum
   residual:integer;
   sense:tscsi_sense;
	 datain:tscsi_data;
end;
Pscsi_task = ^tscsi_task;

//struct scsi_task
{
	int status;

	int cdb_size;
	int xfer_dir;
	int expxferlen;
	unsigned char cdb[SCSI_CDB_MAX_SIZE];

	enum scsi_residual residual_status;
	size_t residual;
	struct scsi_sense sense;
	struct scsi_data datain;
	struct scsi_allocated_memory *mem;

	void *ptr;

	uint32_t itt;
	uint32_t cmdsn;
	uint32_t lun;

	struct scsi_iovector iovector_in;
	struct scsi_iovector iovector_out;
}




type tSCSI_ReadCapacity10=record
 lun:UINT32;
 lba:UINT32;
 end;
PSCSI_ReadCapacity10 = ^tSCSI_ReadCapacity10;

type tscsi_readcapacity16 = record
       returned_lba_low:int32;
       returned_lba_high:int32; //(rc16->task_get_uint32(task, 0) << 32) | task_get_uint32(task, 4);
       block_length:UINT32;//8-11
       p_type:UINT8;
       prot_en:UINT8;
       p_i_exp:UINT8;
       lbppbe:UINT8;
       lbpme:UINT8;
       lbprz:UINT8;
       lalba:UINT16;
end;
pscsi_readcapacity16 = ^tscsi_readcapacity16;  

procedure init;
function readcapacity10(lun:integer):integer;
function write16(lun:integer;lba:int64;data:pointer;size:integer;var byteswritten:integer):integer;
function read16(lun:integer;lba:int64;size:integer;data:pointer;var bytesread:integer):integer;

var
  //
  iscsi:pointer=nil;
  url:pointer=nil;
  //
  block_size:dword=0;
  total_lba:dword=0;
  //external functions
  iscsi_connect_sync:function(iscsi_context:pointer;portal:pchar):integer;cdecl;
  iscsi_full_connect_sync:function(iscsi_context:pointer;portal:pchar;lun:integer):integer;cdecl;
  iscsi_create_context:function(initiator_name:pchar):pointer;cdecl;
  iscsi_is_logged_in:function(iscsi_context:pointer):integer;cdecl;

  iscsi_parse_portal_url:function(iscsi_context:pointer; url:pchar):pointer;cdecl;
  iscsi_parse_full_url:function(iscsi_context:pointer; url:pchar):pointer;cdecl;
  iscsi_destroy_url:procedure(iscsi_url:pointer);cdecl;

  iscsi_readcapacity10_sync:function(iscsi_context:pointer; lun:integer;lba:integer;pmi:integer):pointer;cdecl;
  iscsi_readcapacity16_sync:function(iscsi_context:pointer; lun:integer):pointer;cdecl;

  iscsi_get_error:function(iscsi_context:pointer):pointer;cdecl;
  iscsi_destroy_context:function(iscsi_context:pointer):integer;cdecl;
  iscsi_set_session_type:function(iscsi_context:pointer;session_type:integer):integer;cdecl;
  iscsi_set_header_digest:function(iscsi_context:pointer;header_digest:integer):integer;cdecl;
  iscsi_login_sync:function(iscsi_context:pointer):integer;cdecl;
  iscsi_set_targetname:function(iscsi_context:pointer; targetname:pchar):integer;cdecl;
  iscsi_disconnect:function(iscsi_context:pointer):integer;cdecl;

  iscsi_write16_sync:function(iscsi_context:pointer;lun:integer;lba:uint64;data:pointer;datalen:uint32;blocksize:integer;
		   wrprotect:integer;dpo:integer;fua:integer;fua_nv:integer;group_number:integer):pointer;cdecl;
  iscsi_write16_task:function(iscsi_context:pointer;lun:integer;lba:uint64;data:pointer;datalen:uint32;blocksize:integer;
		   wrprotect:integer;dpo:integer;fua:integer;fua_nv:integer;group_number:integer;cb:pointer;private_data:pointer):pointer;cdecl;
  iscsi_write10_task:function(iscsi_context:pointer;lun:integer;lba:uint32;data:pointer;datalen:uint32;blocksize:integer;
		   wrprotect:integer;dpo:integer;fua:integer;fua_nv:integer;group_number:integer;cb:pointer;private_data:pointer):pointer;cdecl;
  iscsi_write10_iov_task:function(iscsi_context:pointer;lun:integer;lba:uint32;data:pointer;datalen:uint32;blocksize:integer;
		   wrprotect:integer;dpo:integer;fua:integer;fua_nv:integer;group_number:integer;cb:pointer;private_data:pointer;
       iov:pointer;niov:integer):pointer;cdecl;

  iscsi_read10_task:function(iscsi_context:pointer;lun:integer;lba:dword;
		  datalen:dword;  blocksize:integer;
		  rdprotect:integer;dpo:integer;fua:integer;fua_nv:integer;group_number:integer;
		  cb:pointer;private_data:pointer):pointer;cdecl;
  iscsi_read10_iov_task:function(iscsi_context:pointer;lun:integer;lba:dword;
		  datalen:dword;  blocksize:integer;
		  rdprotect:integer;dpo:integer;fua:integer;fua_nv:integer;group_number:integer;
		  cb:pointer;private_data:pointer;
      iov:pointer;niov:integer):pointer;cdecl;
  iscsi_read16_sync:function(iscsi_context:pointer;lun:integer;lba:uint64;datalen:uint32;blocksize:integer;
		  rdprotect:integer;dpo:integer;fua:integer;fua_nv:integer;group_number:integer):pointer;cdecl;
  iscsi_read16_task:function(iscsi_context:pointer;lun:integer;lba:uint64;data:pointer;datalen:uint32;blocksize:integer;
		  rdprotect:integer;dpo:integer;fua:integer;fua_nv:integer;group_number:integer;
      cb:pointer;private_data:pointer):pointer;cdecl;

  scsi_task_set_iov_out:procedure(iscsi_context:pointer; iov:pointer; niov:integer);cdecl;
  scsi_task_set_iov_in:procedure(iscsi_context:pointer; iov:pointer; niov:integer);cdecl;


  scsi_free_scsi_task:procedure(task:pointer);cdecl;

  iscsi_set_log_fn:procedure(iscsi_context:pointer; fn:pointer);cdecl;
  iscsi_set_log_level:procedure(iscsi_context:pointer;level:integer);cdecl;

  iscsi_reconnect_sync:function(iscsi_context:pointer):integer;cdecl;
  iscsi_set_noautoreconnect:procedure(iscsi_context:pointer;state:integer);cdecl;
  iscsi_set_reconnect_max_retries:procedure(iscsi_context:pointer; count:integer);cdecl;

  iscsi_discovery_sync:function(iscsi_context:pointer):pointer;cdecl;
  iscsi_free_discovery_data:procedure(iscsi_context:pointer;da:pointer);cdecl;

implementation

var
lib:thandle=thandle(-1);

function Swap16(ASmallInt : SmallInt) : SmallInt ; register ;
 asm  xchg al,ah  end ;

function Swap32(value : dword) : dword ; assembler ;
  asm  bswap eax  end ;

procedure init;
var
wsaData: TWSAData;
begin
lib:=LoadLibrary('libiscsi.dll');
if lib=thandle(-1) then exit;


@iscsi_parse_portal_url:=getprocaddress(lib,'iscsi_parse_portal_url');
@iscsi_parse_full_url:=getprocaddress(lib,'iscsi_parse_full_url');
@iscsi_destroy_url:=getprocaddress(lib,'iscsi_destroy_url');

@iscsi_create_context:=getprocaddress(lib,'iscsi_create_context');
@iscsi_connect_sync:=getprocaddress(lib,'iscsi_connect_sync');
@iscsi_full_connect_sync:=getprocaddress(lib,'iscsi_full_connect_sync');
@iscsi_is_logged_in :=getprocaddress(lib,'iscsi_is_logged_in');

@iscsi_readcapacity10_sync:=getprocaddress(lib,'iscsi_readcapacity10_sync');
@iscsi_readcapacity16_sync:=getprocaddress(lib,'iscsi_readcapacity16_sync');
@iscsi_get_error:=getprocaddress(lib,'iscsi_get_error');
@iscsi_destroy_context:=getprocaddress(lib,'iscsi_destroy_context');
@iscsi_set_session_type:=getprocaddress(lib,'iscsi_set_session_type');
@iscsi_set_header_digest:=getprocaddress(lib,'iscsi_set_header_digest');
@iscsi_login_sync:=getprocaddress(lib,'iscsi_login_sync');
@iscsi_set_targetname:=getprocaddress(lib,'iscsi_set_targetname');
@iscsi_disconnect:=getprocaddress(lib,'iscsi_disconnect');

@iscsi_write16_task:= getprocaddress(lib,'iscsi_write16_task');
@iscsi_write16_sync:= getprocaddress(lib,'iscsi_write16_sync');
@iscsi_write10_task:= getprocaddress(lib,'iscsi_write10_task');
@iscsi_write10_iov_task:= getprocaddress(lib,'iscsi_write10_iov_task');

@iscsi_read16_task:=getprocaddress(lib,'iscsi_read16_task');
@iscsi_read16_sync:=getprocaddress(lib,'iscsi_read16_sync');
@iscsi_read10_task:= getprocaddress(lib,'iscsi_read10_task');
@iscsi_read10_iov_task:=getprocaddress(lib,'iscsi_read10_iov_task');

@scsi_task_set_iov_out:= getprocaddress(lib,'scsi_task_set_iov_out');
@scsi_task_set_iov_in:= getprocaddress(lib,'scsi_task_set_iov_in');

@scsi_free_scsi_task:= getprocaddress(lib,'scsi_free_scsi_task');

@iscsi_set_log_fn:=getprocaddress(lib,'iscsi_set_log_fn');
@iscsi_set_log_level:=getprocaddress(lib,'iscsi_set_log_level');

@iscsi_reconnect_sync:=getprocaddress(lib,'iscsi_reconnect_sync');
@iscsi_set_noautoreconnect:=getprocaddress(lib,'iscsi_set_noautoreconnect');
@iscsi_set_reconnect_max_retries:=getprocaddress(lib,'iscsi_set_reconnect_max_retries');

@iscsi_discovery_sync:=getprocaddress(lib,'iscsi_discovery_sync');
@iscsi_free_discovery_data:=getprocaddress(lib,'iscsi_free_discovery_data');


if not assigned (iscsi_create_context) then raise exception.create('iscsi_create_context unassigned');
//
WSAStartup(MAKEWORD(2,2), wsaData);
//
end;

function read16(lun:integer;lba:int64;size:integer;data:pointer;var bytesread:integer):integer;
var
task:pointer;
ptr:dword;
begin
result:=-1;
task:=iscsi_read16_sync  (iscsi,lun,lba,size,block_size,0,0,0,0,0);
if task<>nil then
  begin
  result:=Pscsi_task(task)^.status;
  bytesread:=Pscsi_task(task)^.datain.size;
  if Pscsi_task(task)^.datain.size>0 then
    begin
    //lets get a point to our data
    CopyMemory(@ptr,@Pscsi_task(task)^.datain.data[0],4);
    //we alloc mem just in time, if needed
    if data=nil then data:=allocmem(Pscsi_task(task)^.datain.size);
    CopyMemory(data,pointer(ptr),Pscsi_task(task)^.datain.size);
    //we trust the caller to free memory
    //freemem(data,size);
    end;
  scsi_free_scsi_task(task);
  task:=nil;
  end;
end;

function write16(lun:integer;lba:int64;data:pointer;size:integer;var byteswritten:integer):integer;
var
task:pointer;
begin
result:=-1;
task:=iscsi_write16_sync(iscsi,lun,lba,data,size,block_size ,0,0,0,0,0);
if task<>nil then
  begin
  result:=Pscsi_task(task)^.status;
  byteswritten:=Pscsi_task(task)^.expxferlen;
  scsi_free_scsi_task(task);
  task:=nil;
  end;
end;

function readcapacity10(lun:integer):integer;
var
task:pointer;
ptr:dword;
//buffer:array [0..512-1] of byte;
begin
//
result:=-1;
task := iscsi_readcapacity10_sync(iscsi, lun, 0, 0);
//task := iscsi_readcapacity16_sync(iscsi, lun);

if task<>nil
  then
  begin
  //memo1.Lines.Add('status:'+inttostr(Pscsi_task(task)^.status ));
  //memo1.Lines.Add('cdb_size:'+inttostr(Pscsi_task(task)^.cdb_size  ));
  //memo1.Lines.Add('datain.size:'+inttostr(Pscsi_task(task)^.datain.size  ));
  //lets get a point to our data
  if Pscsi_task(task)^.datain.size>0 then
    begin
    CopyMemory(@ptr,@Pscsi_task(task)^.datain.data[0],4);
    copymemory(@total_lba,pointer(ptr),4); //is our lba size
    total_lba:=swap32(total_lba);
    copymemory(@block_size,pointer(ptr+4),4); //is our block size
    block_size:=swap32(block_size);
    //fillchar(buffer,sizeof(buffer),0);
    //CopyMemory(@buffer[0],task,512); //only to look at what is in the scsi task.
    //if buffer[0]=0 then ;
    end;
  result:=Pscsi_task(task)^.status;
  scsi_free_scsi_task(task);
  end;

//
end;


end.
