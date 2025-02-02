import os.path as path
import zlib
import sys

ifn = sys.argv[1]
with open(ifn, "rb") as iff, open(path.join(path.dirname(ifn), path.basename(ifn) + ".pickle"), "wb") as of:
    of.write(zlib.decompress(iff.read()))