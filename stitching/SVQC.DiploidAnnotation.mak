PBS=/net/eichler/vol5/home/mchaisso/projects/PacBioSequencing/scripts
HGSVG=/net/eichler/vol5/home/mchaisso/projects/HGSVG/hgsvg
BLASR=/net/eichler/vol5/home/mchaisso/software/blasr_2/cpp/alignment/bin/blasr
REF=/net/eichler/vol2/eee_shared/assemblies/GRCh38/GRCh38.fasta
SAMPLE?="SAMPLE"
H0SAM?=contigs.h0.fasta.sam
H1SAM?=contigs.h1.fasta.sam
DIR?=stitching_hap_gaps
GAPS?=gaps.bed
NFIELDS=12
all: $(DIR)/hap0/$(GAPS) \
  $(DIR)/hap1/$(GAPS) \
  $(DIR)/hap0/insertions.bed \
  $(DIR)/hap1/insertions.bed \
  $(DIR)/diploid/insertions.bed \
  $(DIR)/diploid/deletions.bed \
  $(DIR)/diploid/deletion/NONE.bed \
  $(DIR)/diploid/insertion/NONE.bed \
  $(DIR)/diploid/sv_calls.bed \
  $(DIR)/diploid/deletions.annotated.bed \
  $(DIR)/diploid/insertions.annotated.bed \
  $(DIR)/diploid/sv_calls.vcf \
  $(DIR)/diploid/deletions.hap.bed \
  $(DIR)/diploid/insertions.hap.bed \
  $(DIR)/diploid/sv.exons.bed \
  $(DIR)/diploid/insertions.bb \
  $(DIR)/diploid/deletions.bb 
#  $(DIR)/diploid/deletions.hap.bb \
#  $(DIR)/diploid/insertions.hap.bb \
#  $(DIR)/diploid/indels.vcf \
#  $(DIR)/diploid/indels.bed \
#  $(DIR)/diploid/indels.exons.bed \


$(DIR)/hap0/insertions.bed: $(DIR)/hap0/$(GAPS)
	cd $(DIR)/hap0 && make -f $(HGSVG)/stitching/SVQC.AnnotationPipeline.mak GAPS=$(GAPS) ALIGNMENTS=$(PWD)/$(H0SAM)

$(DIR)/hap1/insertions.bed: $(DIR)/hap1/$(GAPS)
	cd $(DIR)/hap1 && make -f $(HGSVG)/stitching/SVQC.AnnotationPipeline.mak GAPS=$(GAPS) ALIGNMENTS=$(PWD)/$(H1SAM)

$(DIR)/hap0/deletions.bed: $(DIR)/hap0/$(GAPS) $(DIR)/hap0/insertions.bed
	cd $(DIR)/hap0 && make -f $(HGSVG)/stitching/SVQC.AnnotationPipeline.mak GAPS=$(GAPS) ALIGNMENTS=$(PWD)/$(H0SAM)

$(DIR)/hap1/deletions.bed: $(DIR)/hap1/$(GAPS) $(DIR)/hap0/insertions.bed
	cd $(DIR)/hap1 && make -f $(HGSVG)/stitching/SVQC.AnnotationPipeline.mak GAPS=$(GAPS) ALIGNMENTS=$(PWD)/$(H1SAM)


#$(DIR)/hap0/indels.bed: $(ALIGNMENTS)
#	cd $(DIR)/hap0 && make -f $(HGSVG)/stitching/AnnotationPipeline.mak GAPS=$(GAPS) ALIGNMENTS=$(PWD)/$(H0SAM) indels.bed
$(DIR)/hap1/indels.bed: $(ALIGNMENTS)
	cd $(DIR)/hap1 && make -f $(HGSVG)/stitching/AnnotationPipeline.mak GAPS=$(GAPS) ALIGNMENTS=$(PWD)/$(H1SAM) indels.bed

$(DIR)/diploid/indels.bed: $(DIR)/hap0/indels.bed $(DIR)/hap1/indels.bed
	-mkdir -p $(DIR)/diploid
	# Unfortunately must handle insertions and deletions separately
	grep insertion $(DIR)/hap0/indels.bed > $(DIR)/hap0/indels.insertions.bed
	grep insertion $(DIR)/hap1/indels.bed > $(DIR)/hap1/indels.insertions.bed
	bedtools intersect -a $(DIR)/hap0/indels.insertions.bed -b $(DIR)/hap1/indels.insertions.bed -r -f 0.5 -wao | \
    awk '{ if ($$12 != ".") print; }' | \
    cut -f 1-10 | \
    bedtools groupby -c 4 -o first -full > $(DIR)/diploid/indels.insertions.0.r.bed
	bedtools intersect -b $(DIR)/hap0/indels.insertions.bed -a $(DIR)/hap1/indels.insertions.bed -r -f 0.5 -wao | \
    awk '{ if ($$12 != ".") print; }' | \
    cut -f 1-10 | \
    bedtools groupby -c 4 -o first -full > $(DIR)/diploid/indels.insertions.1.r.bed
	bedtools intersect -v -a $(DIR)/hap0/indels.insertions.bed -b $(DIR)/diploid/indels.insertions.0.r.bed -r -f 1.0 > $(DIR)/diploid/indels.insertions.h0.bed
	bedtools intersect -v -a $(DIR)/hap1/indels.insertions.bed -b $(DIR)/diploid/indels.insertions.1.r.bed -r -f 1.0 > $(DIR)/diploid/indels.insertions.h1.bed
	cp $(DIR)/diploid/indels.insertions.0.r.bed $(DIR)/diploid/indels.insertions.hom.bed

	# deletions
	grep deletion $(DIR)/hap0/indels.bed > $(DIR)/hap0/indels.deletions.bed
	grep deletion $(DIR)/hap1/indels.bed > $(DIR)/hap1/indels.deletions.bed
	bedtools intersect -a $(DIR)/hap0/indels.deletions.bed -b $(DIR)/hap1/indels.deletions.bed -r -f 0.5 -wao | \
    awk '{ if ($$12 != ".") print; }' | \
    cut -f 1-10 | \
    bedtools groupby -c 4 -o first -full > $(DIR)/diploid/indels.deletions.0.r.bed
	bedtools intersect -b $(DIR)/hap0/indels.deletions.bed -a $(DIR)/hap1/indels.deletions.bed -r -f 0.5 -wao | \
    awk '{ if ($$12 != ".") print; }' | \
    cut -f 1-10 | \
    bedtools groupby -c 4 -o first -full > $(DIR)/diploid/indels.deletions.1.r.bed
	bedtools intersect -v -a $(DIR)/hap0/indels.deletions.bed -b $(DIR)/diploid/indels.deletions.0.r.bed -r -f 1.0 > $(DIR)/diploid/indels.deletions.h0.bed
	bedtools intersect -v -a $(DIR)/hap1/indels.deletions.bed -b $(DIR)/diploid/indels.deletions.1.r.bed -r -f 1.0 > $(DIR)/diploid/indels.deletions.h1.bed
	cp $(DIR)/diploid/indels.deletions.0.r.bed $(DIR)/diploid/indels.deletions.hom.bed

	cat $(DIR)/diploid/indels.insertions.h0.bed | awk '{ print $$0"\tHAP0";}' > $@
	cat $(DIR)/diploid/indels.insertions.h1.bed | awk '{ print $$0"\tHAP1";}' >> $@
	cat $(DIR)/diploid/indels.insertions.hom.bed | awk '{ print $$0"\tHOM";}' >> $@
	cat $(DIR)/diploid/indels.deletions.h0.bed | awk '{ print $$0"\tHAP0";}' >> $@
	cat $(DIR)/diploid/indels.deletions.h1.bed | awk '{ print $$0"\tHAP1";}' >> $@
	cat $(DIR)/diploid/indels.deletions.hom.bed | awk '{ print $$0"\tHOM";}' >> $@


$(DIR)/diploid/indels.vcf: $(DIR)/diploid/indels.bed
	module load pandas && $(HGSVG)/sv/utils/variants_bed_to_vcf.py --bed $(DIR)/diploid/indels.bed --ref $(REF) --sample $(SAMPLE) --type sv --vcf $@


$(DIR)/diploid/deletions.bed: $(DIR)/hap0/deletions.bed $(DIR)/hap1/deletions.bed
	$(HGSVG)/sv/utils/MergeHaplotypes.sh $(DIR)/hap0/deletions.bed $(DIR)/hap1/deletions.bed $@ "svType svLen svSeq qName qStart qEnd nAlt nRef"

$(DIR)/diploid/insertions.bed: $(DIR)/hap0/insertions.bed $(DIR)/hap1/insertions.bed
	$(HGSVG)/sv/utils/MergeHaplotypes.sh $(DIR)/hap0/insertions.bed $(DIR)/hap1/insertions.bed $@ "svType svLen svSeq qName qStart qEnd nAlt nRef"

$(DIR)/diploid/insertion/NONE.bed: $(DIR)/diploid/insertions.bed
	-mkdir $(DIR)/diploid/insertion
	-mkdir $(DIR)/diploid/insertion/rm
	touch $(DIR)/diploid/aln.sam
	touch $(DIR)/diploid/$(GAPS)
	# Fake prerequisites for insertions.bed
	cd $(DIR)/diploid && make -t -f $(HGSVG)/stitching/AnnotationPipeline.mak GAPS=$(GAPS) ALIGNMENTS=aln.sam insertions.bed
	cd $(DIR)/diploid && make -f $(HGSVG)/stitching/AnnotationPipeline.mak GAPS=$(GAPS) ALIGNMENTS=aln.sam insertion/NONE.bed

$(DIR)/diploid/deletion/NONE.bed: $(DIR)/diploid/deletions.bed
	-mkdir deletion
	-mkdir deletion/rm
	touch $(DIR)/diploid/$(GAPS)
	touch $(DIR)/diploid/aln.sam
	# Fake prerequisites for insertions.bed
	cd $(DIR)/diploid && make -t -f $(HGSVG)/stitching/AnnotationPipeline.mak GAPS=$(GAPS) ALIGNMENTS=aln.sam deletions.bed
#	cd $(DIR)/diploid && make -f $(HGSVG)/stitching/AnnotationPipeline.mak GAPS=$(GAPS) ALIGNMENTS=aln.sam deletion/L1.bed
	cd $(DIR)/diploid && make -f $(HGSVG)/stitching/AnnotationPipeline.mak GAPS=$(GAPS) ALIGNMENTS=aln.sam deletion/NONE.bed

$(DIR)/diploid/insertions.bb: $(DIR)/diploid/insertions.annotated.bed
	cut -f 1-3 $^ | bedtools sort  >  "$^".sorted
	module load ucsc; bedToBigBed "$^".sorted $(REF).fai $@

$(DIR)/diploid/deletions.bb: $(DIR)/diploid/deletions.annotated.bed
	cut -f 1-3 $^ | bedtools sort  > "$^".sorted
	module load ucsc; bedToBigBed "$^".sorted $(REF).fai $@

$(DIR)/diploid/deletions.annotated.bed:  $(DIR)/diploid/deletion/NONE.bed
	$(HGSVG)/sv/utils/CombineAnnotatedEvents.sh $@ $(DIR)/diploid/deletion/

$(DIR)/diploid/insertions.annotated.bed: $(DIR)/diploid/insertion/NONE.bed
	$(HGSVG)/sv/utils/CombineAnnotatedEvents.sh $@ $(DIR)/diploid/insertion/

$(DIR)/diploid/sv_calls.bed: $(DIR)/diploid/insertions.annotated.bed $(DIR)/diploid/deletions.annotated.bed
	$(HGSVG)/sv/utils/MergeFiles.py --files $(DIR)/diploid/insertions.annotated.bed $(DIR)/diploid/deletions.annotated.bed | \
	 bedtools sort -header > $@

$(DIR)/diploid/sv_calls.vcf: $(DIR)/diploid/sv_calls.bed
	module load pandas && $(HGSVG)/sv/utils/variants_bed_to_vcf.py --bed $(DIR)/diploid/sv_calls.bed --ref $(REF) --sample $(SAMPLE) --type sv --vcf $@

$(DIR)/diploid/insertions.hap.bed: $(DIR)/diploid/insertions.annotated.bed
	awk '{ col="0,0,255"; if ($$13 == "HAP0") {col="255,0,0";} if ($$13 == "HAP1") {col="0,255,0";} print $$1"\t"$$2"\t"$$3"\t"$$13"\t1000\t+\t"$$2"\t"$$3"\t"col}' <  $^ | sort -k1,1 -k2,2n > $@

$(DIR)/diploid/deletions.hap.bed: $(DIR)/diploid/deletions.annotated.bed
	awk '{ col="0,0,255"; if ($$13 == "HAP0") {col="255,0,0";} if ($$13 == "HAP1") {col="0,255,0";} print $$1"\t"$$2"\t"$$3"\t"$$13"\t1000\t+\t"$$2"\t"$$3"\t"col}' <  $^ | sort -k1,1 -k2,2n > $@


$(DIR)/diploid/insertions.hap.bb: $(DIR)/diploid/insertions.hap.bed
	module load ucsc && bedToBigBed $^ $(REF).fai $@ -type=bed9

$(DIR)/diploid/deletions.hap.bb: $(DIR)/diploid/deletions.hap.bed
	module load ucsc && bedToBigBed $^ $(REF).fai $@ -type=bed9

$(DIR)/diploid/sv.exons.bed: $(DIR)/diploid/sv_calls.vcf
	bedtools intersect -a $^ -b /net/eichler/vol2/eee_shared/assemblies/hg38/genes/refGene.exons.bed  -wb | bedtools groupby -g 1,2 -c 9 -o first -full | cut -f 1-14 > $@

$(DIR)/diploid/indels.exons.bed: $(DIR)/diploid/indels.vcf
	bedtools intersect -a $^ -b /net/eichler/vol2/eee_shared/assemblies/hg38/genes/refGene.exons.bed  -wb | bedtools groupby -g 1,2 -c 9 -o first -full | cut -f 1-14 > $@
