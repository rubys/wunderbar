Wunderbar Tutorial
===

The [Introduction](Introduction1.md) explains the rationale for the _Wunderbar 
way and leads new users through some tutorials implemented with Wunderbar.

- A simple [Hello World](HelloWorld1.md)
- [Hello World](HelloWorld2.md) with logic and style
- Basic [Chat](Chat.md) is easy to build
- [System commands](DiskUsage.md) can be directly output
- A simple [Wiki](Wiki.md) with previews
- Adding [modularity](Modularity.md) with common runtimes (Sinatra, polymer, etc.)
- Implementing the [AngularJS tutorial](AngularJS.md)
- Defining [Extensions](Extensions.md) to Wunderbar itself
- [Basic Calendar app](../demo/calendar/README.md) implemented in Wunderbar
- [_Suffix And Options CheatSheet](Suffix.md)

Wunderbar Code
---

Wunderbar features include [globals and environment vars](../README.md#globals-provided), 
[command line options](../README.md#command-line-options), and app [logging](../README.md#logging). 

- Wunderbar in `lib/wunderbar` is documented in the code
- Helper `tools` like [`web2script.rb`](tools/web2script.rb)
- Basic `test` scripts for core behavior in Wunderbar

Special Characters
---

As a general convention in output, underscores in element and attribute names are converted 
to dashes.  A few other special character conventions are used in Wunderbar.

- `_`: underscore generally refers to Wunderbar itself, but is used in 
      a variety of other contexts as well
- `_p "This emits a paragraph."` and is the most common usage
- `_.comment "This is a Wunderbar comment."` as a method on Wunderbar itself
- `_.system "git add #{file}"` executes the command and outputs results
- When used, jQuery is mapped to `~` instead of `$`, thus: `~'textarea'.readonly = true`

Method Suffixes:
- `!`: normally turns off all special processing, including indenting
- `?`: normally adds code to rescue exceptions and produce tracebacks 
- `_`: adds extra blank lines between this tag and siblings
