# SQUINT Sources

- [`AutoComplete.pb`][AutoComplete.pb] — [Scintilla autocomplete example].
- [`FindStrings.pb`][FindStrings.pb] — [strings-finding example].
- [`Squint.pbi`][Squint.pbi] — the [SQUINT module].
- [`SquintMap.pb`][SquintMap.pb] — [benchmarking SQUINT vs Map].
- [`words.txt`][words.txt] — dictionary entries (~86,000).

# The SQUINT Module

- [`Squint.pbi`][Squint.pbi]

To use it in your own programs, add the following lines to your code:

```purebasic
IncludeFile "Squint.pbi"
UseModule SQUINT
```

> __TBD__ — Documentation on how to use SQUINT will be added here, at some point in the future.

# Benchmarking

- [`SquintMap.pb`][SquintMap.pb]
- [`words.txt`][words.txt]

This program benchmarks SQUINT's performance against [PureBasic's Map].

Compile as console application, with Debugger disabled.

# Examples

## Finding Stings

- [`FindStrings.pb`][FindStrings.pb]

This example demonstrates how to use SQUINT to find multiple occurrences of tokens and return their positions.

Run it from the IDE with Debugger enabled.

## Scintilla Autocomplete

- [`AutoComplete.pb`][AutoComplete.pb]
- [`words.txt`][words.txt]

This example demonstrates how to use SQUINT to provide autocomplete functionality for the [Scintilla gadget].
The autocompletion entries (~86,000) are loaded from [`words.txt`][words.txt].

> __NOTE__ — Windows users will need to copy the `Scintilla.dll` from PureBasic's `Compilers/` folder in order to run the example.

<!-----------------------------------------------------------------------------
                               REFERENCE LINKS
------------------------------------------------------------------------------>

[Scintilla gadget]: https://www.purebasic.com/documentation/scintilla/index.html "See PureBasic online documentation for 'Scintilla'"
[PureBasic's Map]: https://www.purebasic.com/documentation/map/index.html "See PureBasic online documentation for 'Map'"

<!-- project files -->

[AutoComplete.pb]: ./AutoComplete.pb
[FindStrings.pb]: ./FindStrings.pb
[Squint.pbi]: ./Squint.pbi
[SquintMap.pb]: ./SquintMap.pb
[words.txt]: ./words.txt

<!-- XRefs -->

[benchmarking SQUINT vs Map]: #benchmarking
[Scintilla autocomplete example]: #scintilla-autocomplete
[SQUINT module]: #the-squint-module
[strings-finding example]: #finding-stings
