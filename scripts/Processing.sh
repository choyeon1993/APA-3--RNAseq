#! /bin/bash
#PBS -N countpas
#PBS -l walltime=99:9:9
#PBS -l nodes=1:ppn=9
#PBS -o count_pas.log
#PBS -j oe
#PBS -V
PBS_O_WORKDIR=/home/zhaoyan2/data1/01.Projects/08.IntronicPolyA_ZB/MCF7
fqdir=/data1/zhaoyan2/01.Projects/03.GZY/merged_GJ-library-191114/2.cutadapt
cd $PBS_O_WORKDIR
res=`ls *.sort.mapped.bam`
outdir=$PBS_O_WORKDIR/PAS

mkdir -p $outdir

cd $outdir
for file in $res
do
re=`basename $file .sort.mapped.bam`

fq1=/$fqdir/$re.fq.1.gz
fq2=/$fqdir/$re.fq.2.gz


hisat2 -p 16 --no-softclip --no-discordant -x /data1/wanghao/Refgenome_copy/hg38_tran -1 $fq1 -2 $fq2 -S $re.sam 2>$re.log
grep -v "ZS:i:" $re.sam | samtools view -b -f 0x2 >$re.bam
rm $re.sam
bedtools bamtobed -i $re.bam > $re.bed
#Since two random 'N' are cutted out in the second step, so we need to change the position info in .bed file
awk -v OFS='\t' '{if ($6=="-") {$2=$3+1;$3=$2+1} else {$3=$2-1;$2=$3-1} if ($2>0) print $0}' $re.bed | grep /1 > mod$re.bed
#rm$outsir/$re.bed
sort -k1,1 -k2,2n mod$re.bed > $re.bed.sorted

mv $re.bed.sorted mod$re.bed

time bedtools coverage -a /data1/zhaoyan2/04.Ref/human_pAs/human_PAS_hg38.all.bed -b mod$re.bed -S -sorted -counts > $re.bed.all.count
done
