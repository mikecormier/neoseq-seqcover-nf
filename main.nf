nextflow.enable.dsl=2

params.help = false
if (params.help) {
    log.info """
    -----------------------------------------------------------------------
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
                          NOTE: the file path must be in qutoes. 
                          e.g. ` "path/to/crams/*.carm" ` If qutoes are not used the
                          workflow will only use the first cram file.

    --reference           Reference FASTA file. Index (.fai) must exist in same directory.

    --d4background        The directory path to the NeoSeq sample d4 per base coverage 
                          files to use for background coverage. 
                          NOTE: the file path must be in qutoes. 
                          e.g. ` "path/to/d4background/*.d4" ` If qutoes are not used the
                          workflow will fail.


    
    One required argument:
    ----------------------
    --genesfile           A file of genes with one gene per line across which to show 
                          coverage. e.g. "gene_list.txt". Required if '--geneslist' is
                          not used. If both '--genesfile' and '--geneslist' are provided, 
                          the two gene sets will be combined. 
    
    --geneslist           A comma separated list of genes across which to show coverage, 
                          e.g. "PIGA,KCNQ2,ARX,DNM1,SLC25A22,CDKL5". Required if `--genefile` 
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
    -----------------------------------------------------------------------
    """.stripIndent()
    exit 0
}

params.crams = false
params.reference = false
params.genesfile = false
params.geneslist = false
params.d4background = false
params.outdir = './results'
params.cpus = 4
params.percentile = 5
params.hg19 = false


//Check params
if(!params.crams) {
    exit 1, "--crams argument to NeoSeq samples like '/path/to/NeoSeq/Samples/*.cram' is required"
}

if(!params.reference) {
    exit 1, "--reference argument is required"
}

if(!params.d4background) {
    exit 1, "--d4background argument to previous d4 per base coverage files, '/path/to/NeoSeq/d4/*.d4', is required"
}

if(!params.genesfile && !params.geneslist) {
    exit 1, "--genesfiles or --geneslist argument, e.g. 'gene_list.txt' or 'PIGA,KCNQ2,ARX,DNM1', is required"
}


// Gather genes
def gene_list = []
if (params.genesfile) {
    
    new File(params.genesfile).eachLine { line ->
        gene_list << line
    }

}

def genes_string = gene_list.join(',')

if (params.geneslist) {

    if (genes_string.length() > 0) {

        genes_string = genes_string + "," + params.geneslist

    }
    else {

        genes_string =  params.geneslist

    }

}


// Create per base d4 coverage files for active NeoSeq project
crams = channel.fromPath(params.crams)
crais = crams.map { it -> it + ("${it}".endsWith('.cram') ? '.crai' : '.bai') }

process run_mosdepth {
    container "mikecormier/neoseq-seqcover-nf:v0.3.0"
    publishDir "${params.outdir}/mosdepth"
    cpus params.cpus

    input:
    path(cram)
    path(crai)
    path(reference)

    output:
    path("*.d4"), emit: d4

    script:
    """
    mosdepth -f $reference -x -t ${task.cpus} --d4 ${cram.getSimpleName()} $cram
    """
}


// Create background file
background_d4s = channel.fromPath(params.d4background).collect()

process seqcover_background {
    container "mikecormier/neoseq-seqcover-nf:v0.3.0"
    publishDir params.outdir

    input:
    path(d4s)
    path(reference)
    val(percentile)

    output:
    path("seqcover/*.d4"), emit: d4

    script:
    """
    seqcover generate-background -p $percentile -f $reference -o seqcover/ $d4s
    """
}


// Create seqcover html report
process seqcover_report {
    container "mikecormier/neoseq-seqcover-nf:v0.3.0"
    publishDir params.outdir

    input:
    path(d4)
    path(background)
    path(reference)
    val(genes)
    val(hg19)

    output:
    path("*.html"), emit: html

    script:

    genome_flag = hg19 ? "--hg19" : ""
    """
    seqcover report --fasta $reference --background $background --genes $genes $genome_flag $d4
    """
}

// Workflow order
workflow {
    run_mosdepth(crams, crais, params.reference)
    seqcover_background(background_d4s, params.reference, params.percentile)
    seqcover_report(run_mosdepth.output.d4.collect(), seqcover_background.output.d4, params.reference, genes_string, params.hg19)
}

