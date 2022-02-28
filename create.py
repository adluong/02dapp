import hashlib
import os
import sys

f = open("officialC.zok", "w")
f.write('import "hashes/mimcSponge/mimcFeistel" as mimcFeistel\n\n')
f.write("def main(private field a, private field b, private field c, field d):\n")
f.write("     field[2] h = mimcFeistel(a,b,c)\n")
f.write("     field[2] h1 = mimcFeistel(a+1,b+1,c+1)\n")
r = 4999

f.write("     field[" + str(r+1)+ "] x = [")
f.write("15265272786498693879089420560795707140585898754184445383953035835695375232586,")
for x in range(r):
  x+=1
  h = hashlib.sha256(str(x).encode('utf-8'))
  h1 = h.hexdigest()
  s1 = h1[:len(h1)-1]
  o1 = int(s1, 16)
  if(x==r):
    f.write(str(o1))
  else:
    f.write(str(o1) +",")
f.write("]\n\n")

f.write("     bool part1 = false\n")
f.write("     bool res1 = false\n")
f.write("     for u32 i in 0.." + str(r+1) + " do\n")
f.write("          part1 = if h[0] == x[i] then true else false fi\n")
f.write("          res1 = res1 || part1\n")
f.write("     endfor\n")
f.write("     assert(res1 && (h1[0] == d))\n")
f.write("     return\n")
f.close()
