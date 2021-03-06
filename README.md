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
-i 	interactive mode (array is possible, separate with spaces)
-r 	randomly select a mode
```

### Example

```
> namegen -r 5
  reclinem
  daniel-laroche
  Lillie-Nakagawa
  Melissa.Owens
  Dorothy-Nichols
```

### Interactive mode

```
>namegen -i 5
[0]  Dale Daniel
[1]  Catherine Hussain
[2]  Claude Hyler
[3]  Paul Pennington
[4]  Jammie Dallas

Enter result to copy to clipboard [0-9|q|n]:
```

Options:
```
n    generates new data
0-9  enter a valid number
q    quit
```

### Modes

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
| 11   | adjnoun    |
| 12   | adjfirst   |

To be continued.

## Aliases 

I use the following aliases for quick access of the most important functions: name generation and username generation.

```
alias namegen="usergen -m 0"
alias usergen="usergen -m '11 12'"
```

## History

This is a total rewrite of https://github.com/carterpage/census-name-generator
