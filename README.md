# SQUINT (Sparse Quad Union Indexed Nibble Trie)

Squint is the result of realising that you can reduce a Trie from 256 nodes down to 16 nodes at only a cost of twice the lookup by indexing the key by nibbles.
You then realise you can use a quad to store the indices of 16 offsets into a sparse array and then also reduce the structure down to two control words per node:

    *vector,(squint.q | value.i): key->squint->*vector\e[offset]

resulting in a very compact Trie with _O_(_K\*2_) performance and a memory size 32 times smaller!
Four times smaller than a fixed 16 node Trie and eight times smaller again than a 256 node Trie.

With UCS-2 Unicode strings, overhead reduces to ~8 bytes per byte of input on x64 and to ~6 bytes on x86.
In pointer sizes that's ~1 word per word of input on x64 and ~1.5 words on x86,
which are similar to the overheads of a QP Trie that's a 1/3 smaller than a Crit-Bit Trie.

In terms of speed it should be ~2 times that of a Map lookup on average but that's OK as it is _O_(_K\*2_) though if you're frequently looking up values that don't exist it will improve further as it will bail out earlier, plus as it's also very cache friendly it may come in closer to 1:1 on lookups.
Enumerations are of course magnitudes faster, which is why you'd be using a Trie in the 1st place.


Keys can either be numeric integers, UTF-8 or UCS-2 Unicode strings; default is UCS-2 Unicode for convenience and both can be used together, although UTF-8 is better for speed.

Supports: Set, Get, Enum, Walk, Delete and Prune with a flag in Delete.

# TODO

- Add in a string buffer so the value can be used for something else and still return the keys and value.

# References

- _[QP Tries: Smaller and Faster Than Crit-Bit Tries]_ — by [Tony Finch].
- _[Crit-Bit Trees]_ — by Daniel J. Bernstein.
- [Wikipedia » Trie][Trie]

<!-----------------------------------------------------------------------------
                               REFERENCE LINKS
------------------------------------------------------------------------------>

[QP Tries: Smaller and Faster Than Crit-Bit Tries]: https://dotat.at/prog/qp/blog-2015-10-04.html "Read full article, by Tony Finch"
[Crit-Bit Trees]: https://cr.yp.To/critbit.html "Read full article, by D. J. Bernstein"

[Trie]: https://en.wikipedia.org/wiki/Trie "See 'Trie' entry at Wikipedia"

[Tony Finch]: https://github.com/fanf2 "View Tony Finch's GitHub profile"
