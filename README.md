# unitron 

Unit testing in Picotron.

![Screenshot](label.png "unitron")

## How to use?

* download cart from [releases page](https://github.com/elgopher/unitron/releases) and put it somewhere on Picotron drive (desktop for example)
* run the cart
* create a file with test code:

```lua
assert_eq("hello", "hello")
```

* drag'n'drop the file to unitron window
* see [examples](examples) folder for details how to write tests

## Development - how to work on unitron

* clone repository to Picotron drive and name it unitron.src.p64
    * `git clone https://github.com/elgopher/unitron unitron.src.p64`
    * edit the source code in editor of choice (such as VS Code with sumneko's Lua Language Server)
* to release cartridge
    * go to Picotron terminal and type
        * `cp unitron.src.p64 unitron.p64.png`
    * publish post on BBS