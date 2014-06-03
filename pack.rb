require 'msgpack'

def writePack(name, value)
   local_filename = "#{name}.msgpack"
   doc = value.to_msgpack
   File.open(local_filename, 'w') {|f| f.write(doc) }
end

writePack "Nil", nil

writePack "True", true
writePack "False", false

writePack "Double", 5672562398523.6523

writePack "Fixstr", "test"
writePack "Str16", "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed tempus aliquet augue a scelerisque. Ut viverra velit nisl, sit amet convallis arcu iaculis id. Curabitur semper, nibh ut ornare hendrerit, orci massa facilisis velit, eget tincidunt enim velit non tellus. Class aptent taciti sociosqu ad litora torquent metus."
str32 = File.open("/Users/davbeck/Dropbox/Documents/Development/Open Source/TUMessagePackSerialization/TUMessagePackSerializationTests/Str32.txt", "rb").read
writePack "Str32", str32

writePack "Fixarray", [1, "b", 3.5]
writePack "Array16", Array(1..200)
writePack "Array32", Array(1..82590)

writePack "Fixmap", { key: :value, one: 1, float: 2.8 }
writePack "Map16", Hash[Array(1..200).zip(Array(101..300))]
writePack "Map32", Hash[Array(1..82590).zip(Array(101..82690))]

