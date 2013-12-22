cli-name-generator
==================

generates random usernames

## Dependencies

* you will need ```xsel``` for the interactive mode
* you will need some Perl modules 
* currently unix runs under unix system

## Install

* this will download the census data + wiktionary

```
namengen.pl -d 1
```

## Syntax

```
Usage: namegen.pl <# of names>
-m 	select mode
-d 	download the database
-i 	interactive mode
-r 	randomly select a mode
```

## Modes

| Mode | Example    |
| ---  |  ---       |
| 0    | First Last |
| 1    | First.Last |
| 2    | first.last |
| 3    | First-Last |
| 4    | first-last |
| 5    | FirstLast  |
| 6    | firstlast  |
| 7    | Word       |
| 8    | word       |
| 9    | Word.Word  |
| 10   | word.word  |

To be continued.

## History

This is a total rewrite of https://github.com/carterpage/census-name-generator
