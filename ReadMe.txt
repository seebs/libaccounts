LibAccounts is a handy tool to let you tell which accounts you're on,
using account-local SavedVariables to store magic cookies.

Call Library.LibAccounts.table_init() (at a time when player and shard
are available), then you can poke at the exposed variables:

  Library.LibAccounts.here = {
    chars = { char = acctid, ... },
    accounts = { acctid = { char = faction, ... }, ... }
  }

NOTE:  Please don't write to this.  Also, please don't look at other
fields; there may be some, but the ones that aren't documented here
aren't considered part of the stable API.

The other useful function, of interest mostly to altoholics:

	Library.LibAccounts.available_chars()

This produces a table:
	{ char, faction, acctid }, ...

of characters who are "available".  That's every character on this account,
plus any characters on other accounts who are of the same faction as at
least one character on this account, and so on recursively.

So if you have account #1:
	Defiant1
	Defiant2
	Defiant3
and account #2:
	Defiant4
	Guardian1
and account #3:
	Guardian1
	Guardian2
	Guardian3

All the characters are considered "available" to each other because you
could transfer items from Guardian3 to Guardian1 (via mail) to Defiant4
(via same-account mail, new in 1.6.1) to Defiant1.

You can use /accounts (it ignores any options you give it for now, but
again, please don't rely on that) for a dump of this shard's info.

LibAccounts doesn't currently expose cross-shard stuff.
