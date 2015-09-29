within MessagePack;

encapsulated package Pack

package SimpleBuffer
  class SimpleBuffer
    extends ExternalObject;

    function constructor
      output SimpleBuffer buf;
    external "C" buf = msgpack_modelica_sbuffer_new() annotation(Include="#include <msgpack-modelica.h>", Library="msgpackc");
    end constructor;

    function destructor
      input SimpleBuffer buf;
    external "C" msgpack_modelica_sbuffer_free(buf) annotation(Include="#include <msgpack-modelica.h>", Library="msgpackc");
    end destructor;

  end SimpleBuffer;

  function writeFile
    input SimpleBuffer sbuffer;
    input String file;
    external "C" msgpack_modelica_sbuffer_to_file(sbuffer,file) annotation(Include="#include <../../../Include/msgpack-modelica.h>", IncludeDirectory="modelica://MessagePack/Resources/C-Sources/msgpack-c/include", Library={"msgpackc"}, __iti_dll = "ITI_msgpackc.dll", __iti_dllNoExport = true);
  end writeFile;

  function position
    input SimpleBuffer sbuffer;
    output Integer position;
    external "C" position=msgpack_modelica_sbuffer_position(sbuffer) annotation(Include="#include <../../../Include/msgpack-modelica.h>", IncludeDirectory="modelica://MessagePack/Resources/C-Sources/msgpack-c/include", Library={"msgpackc"}, __iti_dll = "ITI_msgpackc.dll", __iti_dllNoExport = true);
  end position;

end SimpleBuffer;

class Packer
  extends ExternalObject;

  function constructor
    input SimpleBuffer.SimpleBuffer buf;
    output Packer packer;
  external "C" packer = msgpack_modelica_packer_new_sbuffer(buf) annotation(Include="#include <../../../Include/msgpack-modelica.h>", IncludeDirectory="modelica://MessagePack/Resources/C-Sources/msgpack-c/include", Library={"msgpackc"}, __iti_dll = "ITI_msgpackc.dll", __iti_dllNoExport = true);
  end constructor;

  function destructor
    input Packer packer;
  external "C" msgpack_modelica_packer_free(packer) annotation(Include="#include <msgpack-modelica.h>", Library="msgpackc");
  end destructor;

end Packer;

function double
  input Packer packer;
  input Real dbl;
  output Boolean result;
  external "C" result=msgpack_modelica_pack_double(packer,dbl) annotation(Include="#include <msgpack-modelica.h>", Library="msgpackc");
end double;

function integer
  input Packer packer;
  input Integer i;
  output Boolean result;
  external "C" result=msgpack_modelica_pack_int(packer,i) annotation(Include="#include <msgpack-modelica.h>", Library="msgpackc");
end integer;

function bool
  input Packer packer;
  input Boolean bool;
  output Boolean result;
protected
  function msgpack_pack_true
    input Packer packer;
    output Boolean result;
    external "C" result=msgpack_modelica_pack_true(packer) annotation(Include="#include <msgpack-modelica.h>", Library="msgpackc");
  end msgpack_pack_true;
  function msgpack_pack_false
    input Packer packer;
    output Boolean result;
    external "C" result=msgpack_modelica_pack_false(packer) annotation(Include="#include <msgpack-modelica.h>", Library="msgpackc");
  end msgpack_pack_false;
algorithm
  result := if bool then msgpack_pack_true(packer) else msgpack_pack_false(packer);
end bool;

function sequence
  input Packer packer;
  input Integer len;
  output Boolean result;
external "C" result=msgpack_modelica_pack_array(packer,len) annotation(Include="#include <../../../Include/msgpack-modelica.h>", IncludeDirectory="modelica://MessagePack/Resources/C-Sources/msgpack-c/include", Library={"msgpackc"}, __iti_dll = "ITI_msgpackc.dll", __iti_dllNoExport = true);
end sequence;

function map
  input Packer packer;
  input Integer len;
  output Boolean result;
external "C" result=msgpack_modelica_pack_map(packer,len) annotation(Include="#include <../../../Include/msgpack-modelica.h>", IncludeDirectory="modelica://MessagePack/Resources/C-Sources/msgpack-c/include", Library={"msgpackc"}, __iti_dll = "ITI_msgpackc.dll", __iti_dllNoExport = true);
end map;

function string
  input Packer packer;
  input String str;
  output Boolean result;
  external "C" result=msgpack_modelica_pack_string(packer,str) annotation(Include="#include <../../../Include/msgpack-modelica.h>", IncludeDirectory="modelica://MessagePack/Resources/C-Sources/msgpack-c/include", Library={"msgpackc"}, __iti_dll = "ITI_msgpackc.dll", __iti_dllNoExport = true);
end string;

function nil
  input Packer packer;
  output Boolean result;
  external "C" result=msgpack_modelica_pack_nil(packer) annotation(Include="#include <../../../Include/msgpack-modelica.h>", IncludeDirectory="modelica://MessagePack/Resources/C-Sources/msgpack-c/include", Library={"msgpackc"}, __iti_dll = "ITI_msgpackc.dll", __iti_dllNoExport = true);
end nil;

end Pack;
