# Salesforce Deploy Tool

Salesforce deploy tool is a command line tool that sits on top of ant to facilitate
salesforce deploys.

## Features

* push code / pull code / validate / destructive push support
* Easier than using ant
* Specify environment to deploy using a flag
* Exclude and include metadata and metadata types
* Destructive Changes autogeneration
* GIT integration
* Production / Test deployment support
* Fast deploy support
* Specify different ant libraries so to use different APIs

## Installation

    $ gem install salesforce-deploy-tool

## Quick Start

To generate a configuration file do

    $ sf config

## Example

For how to use this tool just run:

    $ sf pull -h
    $ sf push -h

### specific examples

```
$ sf pull -d
$ sf pull -d -s mySandbox
$ sf push -T
$ sf push -l /path/to/ant-salesforce.jar
$ sf push -s prod
$ sf push -i apexclass
$ sf push -i apexclass -e TestClass -d -s myOtherSandbox
$ sf push -a
```

## Contrib

Feel free to fork and request a pull, or submit a ticket
http://github.com/BreinsNet/salesforce-deploy-tool/issues

## License

This project is available under the MIT license. See LICENSE for details.
