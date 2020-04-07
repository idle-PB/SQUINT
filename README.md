# SQUINT

SQUINT Sparse Quad Union Indexed Nibble Trie

Squint is the result of noting that you can reduce a trie from 256 nodes down to 16 nodes
at only the cost of 2 times the lookup and indexing the key by nibbles, then you realise you can
use a quad to store the indices to 16 offsets into a sparse Array and also reduce the structure
down to two control words per node. *vector,(squint.q | value.i): key->squint->*vector\e[offset]
resulting in a very compact trie With O(K*2) performance and a memory size 32 times smaller!
four times smaller than a fixed 16 node trie and eight times smaller again than a 256 node trie.
Overhead on x64 reduces to ~8 bytes per byte of input with Unicode16 strings
Overhead on x86 reduces to ~6 bytes per byte of input with Unicode16 strings
In pointer sizes thats ~1 word per word of input on x64 And ~1.5 words on x86
which are similar to the overheads of a QP Trie thats a 1/3 smaller than a Critbit.
In terms of speed it should be ~2 times that of a Map lookup on average but that's OK as it is O(k*2)
though if you're frequently looking up values that don't exist it will improve further as it will bail
out earlier, plus as it's also very cache friendly it may come in closer to 1:1 on lookups.
Enumerations are of course magnitudes faster, which is why you'd be using a trie in the 1st place

see https://dotat.at/prog/qp/blog-2015-10-04.html
    https://cr.yp.To/critbit.html
    https://en.wikipedia.org/wiki/Trie

Keys can either be numeric integers, UTF8 Or Unicode strings, Default is Unicode For convienence
And both can be used together, although UTF8 is better for speed.

Supports: Set, Get, Enum, Walk, Delete and Prune with a flag in Delete

todo: add in a string buffer so value can be used For something Else and still return the keys and value
