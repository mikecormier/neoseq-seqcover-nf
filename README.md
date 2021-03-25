# neoseq-seqcover-nf

A workflow to run seqcover on NeoSeq samples. 

[NeoSeq](https://uofuhealth.utah.edu/center-genomic-medicine/research/utah-neoseq-project.php) is a initiative at the University of Utah aimed
at providing **RAPID NICU Genetic Sequencing, Analysis, and Diagnosis** for critically ill infants. This workflow runs the [seqcover](https://github.com/brentp/seqcover)
program, the successor to [mosdepth_region_vis](https://github.com/mikecormier/mosdepth_region_vis), to provide a interactive html report 
to explore difference in coverage and coverage QC for genes of interest. 


### Flow of the workflow:

1) Mosdepth 

This workflow will run [Mosdepth](https://github.com/brentp/mosdepth) to generate per-base depth of coverage files for each sample of interest 
in the NeoSeq project.

2) Background

Using seqcover, this workflow will then create a per-base depth of coverage background at a percentile of coverage to identify outliers using  
d4 per-base depth of coverage files from previous NeoSeq samples.

3) HTML report

Using seqcover, this workflow will create an interactive html report for coverage QC and exploration based on a set of genes provided to the workflow
called `seqcover_report.html`.


### Parameters:

Here is a list of parameters required and/or optional by the workflow.

To get this list on the command line, run:

```
nextflow run mikecormier/neoseq-seqcover-nf -revision main --help
```

Parameters:
```
neoseq-seqcover-nf
==================
Nextflow workflow to run seqcover for the NeoSeq project:
https://uofuhealth.utah.edu/center-genomic-medicine/research/utah-neoseq-project.php

Documentation and issues can be found at:
https://github.com/mikecormier/neoseq-seqcover-nf
seqcover is available at:
https://github.com/brentp/seqcover

Required arguments:
-------------------
--crams               NeoSeq sample's aligned sequences in .bam and/or .cram format.
                      Indexes (.bai/.crai) must be present.
                      NOTE: the file path must be in quotes. 
                      e.g. ` "path/to/crams/*.cram" ` If quotes are not used the
                      workflow will only use the first cram file.

--reference           Reference FASTA file. Index (.fai) must exist in same directory.

--d4background        The directory path to the NeoSeq sample d4 per base coverage 
                      files to use for background coverage. 
                      NOTE: the file path must be in quotes. 
                      e.g. ` "path/to/d4background/*.d4" ` If quotes are not used the
                      workflow will fail.



One required argument:
----------------------
--genesfile           A file of genes with one gene per line across which to show 
                      coverage. e.g. "gene_list.txt". Required if '--geneslist' is
                      not used. If both '--genesfile' and '--geneslist' are provided, 
                      the two gene sets will be combined. 

--geneslist           A comma separated list of genes across which to show coverage, 
                      e.g. "PIGA,KCNQ2,ARX,DNM1,SLC25A22,CDKL5". Required if `--genesfile` 
                      is not used. If both '--genesfile' and '--geneslist' are provided, 
                      the two gene sets will be combined.

Optional:
---------
--outdir              The directory for output seqcover report.
                      Default: '/.results'

--cpus                The number of cpus to use for `mosdepth` calls.
                      Default: 4

--percentile          The background percentile used in seqcover report.
                      More info is available at:
                      https://github.com/brentp/seqcover#outlier
                      Default: 5


```

### Containers

This workflow uses a Docker container for software requirements. This means a 
user does not have to worry about install software the workflow requires. Rather,
a user needs to make sure that either Docker or Singularity work on their system. 

For both docker and singularity, a user needs to configure container usage within 
the nextflow profile config file commonly located at `~/.nextlfow/config`. 

Once the configuration has been set up, a user can use the desired profile
for running the workflow. 

For example, if you are on a platform that only allows singularity you would
do the following. 

1) Ensure singularity is available and active 
```
## If singularity is set up within a module system 

module load singularity 
```

2) Designate the singularity profile in the nextflow config file. 

Here, we are using a profile named "singularity" in our config file
```
nextflow run mikecormier/neoseq-seqcover-nf -revision main -profile singularity ...

```

### Running the workflow

This workflow does not need to be downloaded in order to run. Although one can clone the repository 
and run it locally, nextflow is capable of running workflows from GitHub repositories. 

The only software requirements are
  - nextflow
  - docker or singularity 

To install nextflow see the [nextflow installation page](https://www.nextflow.io/docs/latest/getstarted.html#installation)


Here is an example of running the workflow using this GitHub repo.

```
module load singularity 

nextflow run mikecormier/neoseq-seqcover-nf -revision main -profile singularity \
    --crams "path/to/crams/*.crams" \
    --reference path/to/reference/reference.fa \
    --d4background "path/to/d4/coverage/files/*.d4" \
    --genesfile gene_list.txt \
    --percentile 5 \
    --cpus 4 \
    --outdir path/to/results/
```

The `-revision main` argument is required in order to run it from the "main" GitHub repo branch.

> **_NOTE:_** The `--crams` and the `--d4background` parameters require that path to be in quotes. If the path is not provided in quotes then bash will expand the directory prior to the required nextflow expansion, causing an issue with collecting the cram and d4 files.

### Resuming failed workflows 

There may be times where the nextflow workflow fails for reasons not related to the actual process of the workflow. 
For example, this workflow uses seqcover which uses the mygene.info API. If for some reason their is a slight gap in
a GET request that causes seqcover to fail, the workflow may fail too. If this happens nextflow allows you to start 
the workflow from the last successful process. To do this one needs to add the `-resume` parameter to the nextflow 
command. 

```
nextflow run mikecormier/neoseq-seqcover-nf -revision main -profile singularity -resume \
    --crams "path/to/crams/*.crams" \
    --reference path/to/reference/reference.fa \
    --d4background "path/to/d4/coverage/files/*.d4" \
    --genesfile gene_list.txt \
    --percentile 5 \
    --cpus 4 \
    --outdir path/to/results/
```


### Example config profile 

Here is simple example of a config profile that can be created. 

Refer to the [Nextflow docs](https://www.nextflow.io/docs/latest/config.html?#config-profiles) for more information. 

This config file should be in your home directory in the .nextflow directory 

```
cd ~/.nextflow/
vim config

```

config profile: 
```
profiles {
    // Cluster profile
    Cluster {
        process {
            // submit process jobs to slurm, not on current node
            executor = 'slurm'
            // use your slurm-account
            queue = 'slurm-account'
            // SLURM options: use the "slurm-account" account
            clusterOptions = '--account=slurm-account --ntasks=1'
        }
        singularity {
            // use the container defined by the process rather than local software installs
            enabled = true
            // make the Cluster storage locations available within the Singularity container
            runOptions = '--bind /scratch --bind /root'
        }
        executor {
            submitRateLimit = '1 sec'
        }
    }
    // do not submit my processes to SLURM, just run on the interactive node I'm logged into
    interactive {
        process {
            executor = 'local'
            scratch = false
            cleanup = false
        }
        // still use Singularity for software dependencies
        singularity {
            enabled = true
            runOptions = '--bind /scratch --bind /uufs'
        }
        docker {
            enabled = false
        }
    }
}

```
