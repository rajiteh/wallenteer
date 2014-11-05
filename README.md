# Wallenteer

## What 
A set of scripts to manage multiple bitcoind based mining daemons.

## Tools
* Dropbox-Uploader : https://github.com/andreafabrizi/Dropbox-Uploader.git
* truecrypt (Outdated!)

## Scripts

* `walletcontrol.sh` - Starting/Stopping a set of bitcoind based miner daemons stored in `deamons/` folder.
* `walletsync.sh` - Downloads/Uploads a truecrypt archive stored in Dropbox to a memdrive. Timestamps and copies the wallet.dat files for each miner to the truecrypt archive.
* `walletcompile.sh` - The most incomplete script. Will download a git repo of a coin miner, compile it without ui and store it in the `daemons/` folder for other scripts to consume.

This README will be updated whenever I get time.


The MIT License.  
Copyright (C) 2014 Raj Perera <rajiteh@gmail.com>