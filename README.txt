A toolkit that facilitates submission to the European Nucleotide Archive (ENA)
==============================================================================

A small toolset to create the XML files needed in programmatic submission to the European Nucleotide Archive (ENA). 
The scripts allows to rapidely build XML files containing a large number of objects for samples, experiments and runs.

## Resources:

* Git clone URL: https://github.com/alexisrapin/ena-submission-toolkit.git
* Documentation: https://github.com/alexisrapin/ena-submission-toolkit
* ENA documentation: https://ena-docs.readthedocs.io/en/latest/programmatic.html
* License: All files in this repository are provided under the MIT license (See LICENSE.txt for details)

## Installation

The `install.sh` script adds the binaries to the PATH using `.bashrc` (or `.bash_profile` on mac).

```
# install:
$ chmod 755 install.sh && ./install.sh
$ source $HOME/.bashrc

# uninstall:
$ ./install.sh uninstall
```

## Usage

### `create_sample_xml.py`

```
usage: Creates a XML file to submit sample objects to the ENA (more details:https://ena-docs.readthedocs.io/en/latest/prog_03.html).

required arguments:
  -m MAP_FP, --map_fp MAP_FP
                        Path to a table file in tab-delimited text format
                        containing metadata. Rules: First line as header,
                        following lines as samples metadata. Use one line per
                        sample. At least one column must contain a unique
                        sample name which will be used for the <SAMPLE_NAME>
                        field. One column must contain a title which will be
                        used for the <TITLE> field (i.e. a brief description
                        of the sample). Additional columns may contain any
                        additional metadata that will be added to the XML file
                        as <SAMPLE_ATTRIBUTE> fields. Use as many additional
                        columns as needed. Each header must be unique.
  -n NAME, --name NAME  Name of the column containing the <SAMPLE_NAME> field.
  -t TITLE, --title TITLE
                        Name of the column containing the <TITLE> field.

optional arguments:
  -o OUTPUT, --output OUTPUT
                        Path to output file.
```

### `create_experiment_xml.sh`

```
# usage: Creates a XML file to submit experiment objects to the ENA
#        (more details:https://ena-docs.readthedocs.io/en/latest/prog_04.html).
#        A template XML snippet will be used to create a new experiment object
#        for each sample found in a separate TXT table. Edit both XML template
#        and TXT table before using this script.
#        !CAUTION!: Do not spread a XML field over multiple lines but use only
#                   one line per field.
# required arguments:
#  (1)  Path to a template experiment XML snippet.
#       (See etc/experiment_template.xml for an example)
#  (2)  Path to a template run XML snippet.
#       (See etc/run_template.xml for an example)
#  (3)  Path to a tab-delimited text table containing sample
#       names in the first column (The first line will be ignored)
#  (4)  Path to the directory containing the fastq files
#  (5)  Path to the experiment XML output file
#  (6)  Path to the run XML output file
```
