 module load python/3.5.2; module load snakemake/3.11.2; snakemake --cluster "qsub {params.sge_opts}"  -p -s  ~/projects/HGSVG/hgsvg/stitching/Stitching.Snakefile  -j 60  --jobscript  ~/projects/HGSVG/hgsvg/stitching/jobscript.sh  --latency-wait 60  --rerun-incomplete