#!/usr/bin/env bash
#create_experiment_xml.sh
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


################
# Error function
# Args:
#  (1)  Error message
# Global vars:
#  __base  script name
################
err() {
  echo "Error [${__base}]: $@" >&2
  exit 1
}

################
# Create XML from template
# Args:
#  (1)  Path to a template experiment XML snippet
#       (See etc/experiment_template.xml for an example)
#  (2)  Path to a tab-delimited text table containing sample
#       names in the first column (The first line will be ignored)
#  (3)  Type (experiment or run)
#  (4)  Path to output file
#  (5)  Path to the directory containing the fastq files (when the type is run)
################
create_xml(){

  local template_xml_fp
  template_xml_fp="${1}"
  [[ ! -e "${template_xml_fp}" ]] && err "cannot find ${template_xml_fp}"

  local sample_txt_fp
  sample_txt_fp="${2}"
  [[ ! -e "${sample_txt_fp}" ]] && err "cannot find ${sample_txt_fp}"

  local xml_type
  xml_type="${3}"
  [[ ! " experiment run " =~ " ${xml_type} " ]] && err "xml_type must be experiment or run. Currently: ${xml_type}"

  local output_fp
  output_fp="${4}"

  local fastq_dir
  fastq_dir="${5}"
  if ([[ "${xml_type}" == 'run' ]] && [[ ! -d "${fastq_dir}" ]]); then
    err "cannot find ${fastq_dir}"
  fi

  printf '<?xml version="1.0" encoding="UTF-8"?>\n' \
  > "${output_fp}"
  case "${xml_type}" in
    'experiment' )
      printf '<EXPERIMENT_SET>\n' > "${output_fp}"
    ;;
    'run' )
      local checksum_1
      local checksum_2
      printf '<RUN_SET>\n' > "${output_fp}"
    ;;
  esac

  sed 1d "${sample_txt_fp}" | cut -f1 \
  | while read line; do
    case "${xml_type}" in
      'experiment' )
        sed "s/<EXPERIMENT\(.*\)alias=\".*\"/\
<EXPERIMENT\1alias=\"exp_${line}\"/g;\
             s/<SAMPLE_DESCRIPTOR\(.*\)refname=\".*\"/\
<SAMPLE_DESCRIPTOR\1refname=\"${line}\"/g" \
        "${template_xml_fp}" >> "${output_fp}"
      ;;
      'run' )
        if [ -e "${fastq_dir}"/${line}-R1.fastq.gz -a -e "${fastq_dir}"/${line}-R2.fastq.gz ]; then
          checksum_1=$(md5sum "${fastq_dir}"/${line}-R1.fastq.gz | cut -d' ' -f1)
          checksum_2=$(md5sum "${fastq_dir}"/${line}-R2.fastq.gz | cut -d' ' -f1)
          sed "s/<RUN\(.*\)alias=\".*\"/\
<RUN\1alias=\"run_${line}\"/g;\
               s/<EXPERIMENT_REF\(.*\)refname=\".*\"/\
<EXPERIMENT_REF\1refname=\"exp_${line}\"/g;\
               /<FILE .*>/d;\
               s/<FILES>/\
<FILES>\n\
              <FILE filename=\"${line}-R1.fastq.gz\" filetype=\"fastq\" \
checksum_method=\"MD5\" checksum=\"${checksum_1}\"\/>\n\
              <FILE filename=\"${line}-R2.fastq.gz\" filetype=\"fastq\" \
checksum_method=\"MD5\" checksum=\"${checksum_2}\"\/>/g" \
          "${template_xml_fp}" >> "${output_fp}"
        fi
      ;;
    esac
  done

  case "${xml_type}" in
    'experiment' )
      printf '</EXPERIMENT_SET>' >> "${output_fp}"
    ;;
    'run' )
      printf '</RUN_SET>' >> "${output_fp}"
    ;;
  esac

  return 0
}

################
# Main
# Args:
#  (1)  Path to a template experiment XML snippet.
#       (See etc/experiment_template.xml for an example)
#  (2)  Path to a template run XML snippet.
#       (See etc/run_template.xml for an example)
#  (3)  Path to a tab-delimited text table containing sample
#       names in the first column (The first line will be ignored)
#  (4)  Path to the directory containing the fastq files
#  (5)  Path to the experiment XML output file
#  (6)  Path to the run XML output file
################
main(){

  local experiment_template_xml_fp
  experiment_template_xml_fp="${1}"
  [[ ! -e "${experiment_template_xml_fp}" ]] && err "cannot find ${experiment_template_xml_fp}"

  local run_template_xml_fp
  run_template_xml_fp="${2}"
  [[ ! -e "${run_template_xml_fp}" ]] && err "cannot find ${run_template_xml_fp}"

  local sample_txt_fp
  sample_txt_fp="${3}"
  [[ ! -e "${sample_txt_fp}" ]] && err "cannot find ${sample_txt_fp}"

  local fastq_dir
  fastq_dir="${4}"
  [[ ! -d "${fastq_dir}" ]] && err "cannot find ${fastq_dir}"

  local output_experiment_fp
  output_experiment_fp="${5}"

  local output_run_fp
  output_run_fp="${6}"

  create_xml "${experiment_template_xml_fp}" "${sample_txt_fp}" 'experiment' "${output_experiment_fp}"
  create_xml "${run_template_xml_fp}" "${sample_txt_fp}" 'run' "${output_run_fp}" "${fastq_dir}"

  return 0
}

__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")"  && pwd)"
__search_dir="$(cd "${__dir}"/.. && pwd)"

main "${@}"

exit 0
