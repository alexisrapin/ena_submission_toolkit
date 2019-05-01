#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-
#create_sample_xml.py

import os, argparse, re, collections
import pandas as pd
from dicttoxml import dicttoxml
import xml.dom.minidom

def Error(f=__file__, msg=''):

    print 'Error ['+ os.path.basename(f) +']: '+ msg
    raise SystemExit(1)

def Wrng(f=__file__, msg=''):

    print 'Warning ['+ os.path.basename(f) +']: '+ msg

def CurateXML(xml=''):
    return re.sub('</SAMPLE alias=.*">',
                  '</SAMPLE>',
                  re.sub('</*item>',
                         '',
                         xml))
    
class Parameters(object):
    """Parameters passed in command line"""

    def __init__(self):
        """Create a dictionary containing CLI arguments"""

        # Set authorized arguments for cli
        argument_parser = argparse.ArgumentParser(usage='Creates a XML file \
to submit sample objects to the ENA \
(more details:https://ena-docs.readthedocs.io/en/latest/prog_03.html).')
        argument_parser._action_groups.pop()
        required_arguments = argument_parser.add_argument_group('required \
arguments')
        optional_arguments = argument_parser.add_argument_group('optional \
arguments')
        required_arguments.add_argument('--table_fp',
                                     required=True,
                                     help='\
Path to a table file in tab-delimited text format containing metadata. \
Rules: First line as header, following lines as samples metadata. \
Use one line per sample. \
At least one column must contain a unique sample name which will be used for \
the <SAMPLE_NAME> field. \
One column must contain a title which will be used for the <TITLE> field \
(i.e. a brief description of the sample). \
The columns containing sub-categories of the <SAMPLE_NAME> field \
(<TAXON_ID>, <SCIENTIFIC_NAME> and <COMMON_NAME>) are optional and can be \
specified in the CLI arguments.\
Additional columns may contain any additional metadata that will be added to \
the XML file as <SAMPLE_ATTRIBUTE> fields. \
Use as many additional columns as needed. \
Each header must be unique.',
                                     nargs=1,
                                     type=str)
        required_arguments.add_argument('-n',
                                     '--name',
                                     required=True,
                                     help='Name of the column containing \
the alias argument.',
                                     nargs=1,
                                     type=str)
        required_arguments.add_argument('--title',
                                     required=True,
                                     help='Name of the column containing \
the <TITLE> field.',
                                     nargs=1,
                                     type=str)
        optional_arguments.add_argument('--taxon_id',
                                     required=False,
                                     help='Name of the column containing \
the <TAXON_ID> field.',
                                     nargs=1,
                                     type=str)
        optional_arguments.add_argument('-s',
                                     '--scientific_name',
                                     required=False,
                                     help='Name of the column containing \
the <SCIENTIFIC_NAME> field.',
                                     nargs=1,
                                     type=str)
        optional_arguments.add_argument('-c',
                                     '--common_name',
                                     required=False,
                                     help='Name of the column containing \
the <COMMON_NAME> field.',
                                     nargs=1,
                                     type=str)
        optional_arguments.add_argument('-o',
                                     '--output',
                                     required=False,
                                     default=['sample.xml'],
                                     help='Path to output file. \
(default: sample.xml)',
                                     nargs=1,
                                     type=str)

        self.params = {k: (v[0] if v is not None else None) for k, v in\
                       argument_parser.parse_args().__dict__.items()}
        
class Sample(object):
    """An XML object representing a sample"""

    def __init__(self,
                 title='',
                 name='',
                 taxon_id='',
                 scientific_name='',
                 common_name='',
                 attributes=[]):
        """Create a dictionary and an XML string"""
        self.dict=collections.OrderedDict([('TITLE', title)])
        sample_name={'TAXON_ID':taxon_id,
                     'SCIENTIFIC_NAME':scientific_name,
                     'COMMON_NAME':common_name}
        for k, v in sample_name.items():
            if v is None:
                sample_name.pop(k)
        if len(sample_name) != 0:
            self.dict['SAMPLE_NAME']=sample_name
        if len(attributes) != 0:
            self.dict['SAMPLE_ATTRIBUTES']=attributes
        self.xml=CurateXML(dicttoxml(self.dict,
                                     custom_root='SAMPLE alias="'+name+'"',
                                     attr_type=False))

class SampleSet(object):
    """A collection of samples"""
    
    def __init__(self, samples=[]):
        """Create a dictionary and an XML string"""
        self.samples=samples
        self.dict={'SAMPLE_SET': [s.dict for s in samples]}
        self.xml='<SAMPLE_SET>'+\
        ''.join([re.sub('<\?xml version=.*\?>', '', s.xml) for s in samples])+\
        '</SAMPLE_SET>'

def main():
    params=Parameters().params
    if os.path.exists(params['table_fp']):
        samples=[]
        for index, row in pd.read_table(params['table_fp']).iterrows():
            row=dict(row)
            attributes=[]
            for key, value in {k: row[k] for k in row if k not in \
                               [params['name'],
                                params['title'],
                                params['taxon_id'],
                                params['scientific_name'],
                                params['common_name']]}.iteritems():
                attributes.append({'SAMPLE_ATTRIBUTE':{'TAG':key,
                                                       'VALUE':value}})
            samples.append(Sample(name=row.get(params['name']),
                         title=row.get(params['title']),
                         taxon_id=row.get(params['taxon_id']),
                         scientific_name=row.get(params['scientific_name']),
                         common_name=row.get(params['common_name']),
                         attributes=attributes))
        sample_set=SampleSet(samples)
        output=open(params['output'], 'w')
        output.write(xml.dom.minidom.parseString(sample_set.xml)\
                     .toprettyxml(indent='  ', encoding='UTF-8'))
        output.close()
    else:
        Error(msg=params['table_fp']+' not found.')
    return 0

if __name__ == "__main__":
    main()

exit()
