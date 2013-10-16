OkORF
=====

Predict ORFs in transcriptome sequences, e.g. RNA-seq de novo assembly.

OkORF is a sort of modification of TransDecoder by B. Haas. Many codes of TransDecoder are borrowed.

## How to use?

1) 

```
$ cp OkORF/run.conf.yml.example ./run.conf.yml
$ cp OkORF/run.rb ./
```

edit `run.conf.yml`

```
$ ruby run.rb
```

6 shell scripts are generated.

- run_script_1.sh
- run_script_2.sh
- run_script_3.sh
- run_script_4.sh
- run_script_5.sh
- sge_submit_Mcra_131016p3.sh


submit scripts to SGE by running `sge_submit_Mcra_131016p3.sh`.

```
sge_submit_Mcra_131016p3.sh
```
