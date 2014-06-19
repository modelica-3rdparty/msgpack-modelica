within MessagePack;

package Examples

model TestCreateAndReadFile
protected
  function createFile
    input String file;
  protected
    import MessagePack.Pack;
    Pack.SimpleBuffer.SimpleBuffer sbuffer = Pack.SimpleBuffer.SimpleBuffer();
    Pack.Packer packer = Pack.Packer(sbuffer);
  algorithm
    Pack.integer(packer,-65538);
    Pack.string(packer,"Modelica");
    Pack.map(packer, 1);
    Pack.double(packer,1.0);
    Pack.bool(packer,true);
    Pack.sequence(packer, 2);
    Pack.integer(packer,65538);
    Pack.double(packer,2.0);
    Pack.bool(packer,false);
    Pack.string(packer,"Modelica");
    Pack.SimpleBuffer.writeFile(sbuffer,file);
  end createFile;

  function readFile
    input String file;
    output String result;
  protected
    import MessagePack.Utilities.Stream;
    import MessagePack.Unpack;
    Unpack.Deserializer deserializer = Unpack.Deserializer(file);
    Stream.Stream ss = Stream.Stream();
    Integer offset = 0, i;
    String s;
    Boolean success;
  algorithm
    (i,offset) := Unpack.integer(deserializer,offset);
    (s,offset) := Unpack.string(deserializer,offset);
    offset := Unpack.toStream(deserializer,ss,offset);
    success := true;
    while success loop
      (offset,success) := Unpack.toStream(deserializer,ss,offset);
      Stream.append(ss,"\n");
    end while;
    result := Stream.get(ss);
  end readFile;

  function createAndReadFile
    input String filename;
  algorithm
    createFile(filename);
    terminate("Succeeded to write and read msgpack data from file " + filename + ": " + readFile(filename));
  end createAndReadFile;

initial algorithm
  createAndReadFile("msgpack.out");
  annotation(experiment(StopTime=1.0));
end TestCreateAndReadFile;

end Examples;
