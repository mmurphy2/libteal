# libteal

Shell code function library to support other projects (unfinished).


## Conclusions

After doing quite a bit of experimentation with shell code, Python code, and various installation
projects, I have come to conclusion that shell code isn't the way to write applications (despite
its popularity in segments of the Linux community). The lack of data structures other than strings
cripples designs, while the need to utilize external commands like sed and awk create performance
issues in these days of Spectre and Meltdown mitigations (adding to the already relatively high
cost of context switching).

The flip side is that shell programming is quite convenient whenever a number of external commands
need to be run. Python has traditionally been cumbersome in this regard, since the subprocess module
makes running even a simple command and obtaining its standard output significantly more verbose
than the shell equivalent. I am therefore going to take a stab at solving that problem, the progress
of which may be found in my python3-libteal repository.

Depending on the results of that experiment, I will either archive or continue development on
shell libteal (this repository).
