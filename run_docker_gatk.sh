date_prefix=$(date +"%Y_%m_%d_%I_%M_%p")
mkdir -p ./docker_gatk_log/
exec &> >(tee -a ./docker_gatk_log/"$date_prefix.screenlog")

## gatk_realigner ##
docker stop $(docker ps -aq)
docker rm $(docker ps -aq)
for sample in $(ls /media/kt256/T10G/TRUNG-CARRIER/kt155/result/); do
	echo " Run gatk_realigner "
	if [ ! -s "/media/kt256/T10G/TRUNG-CARRIER/kt155/result/${sample}/${sample}.realignment_target.list" ]; then
		# docker create -it --name gatk3 
		docker run -td --name gatk3_${sample} -v /media/kt256/T10G/TRUNG-CARRIER/kt155/1.CODE/:/media/1 \
		-v /media/kt256/T10G/2.resources/human_genome/hg38/:/media/2 \
		-v /media/kt256/T10G/TRUNG-CARRIER/kt155/result/${sample}/:/media/3 broadinstitute/gatk3:3.8-1 \
		java -jar /usr/GenomeAnalysisTK.jar -R /media/2/hg38.22XY.fa -I /media/3/${sample}.dedup.bam -o /media/3/${sample}.realignment_target.list -T RealignerTargetCreator
	fi
done

for sample in $(ls /media/kt256/T10G/TRUNG-CARRIER/kt155/result/); do
	docker wait gatk3_${sample}
done
docker rm $(docker ps -a | grep "Exited (0)" | awk '{print $1}')

## gatk_indel_realigner ##
for sample in $(ls /media/kt256/T10G/TRUNG-CARRIER/kt155/result/); do
	echo " Run gatk_indel_realigner "
	if [ -z "/media/kt256/T10G/TRUNG-CARRIER/kt155/result/${sample}/${sample}.realigned.bam" ]; then
		# docker create -it --name gatk3 
		docker run -td --name gatk3_${sample} -v /media/kt256/T10G/TRUNG-CARRIER/kt155/1.CODE/:/media/1 \
		-v /media/kt256/T10G/2.resources/human_genome/hg38/:/media/2 \
		-v /media/kt256/T10G/TRUNG-CARRIER/kt155/result/${sample}/:/media/3 broadinstitute/gatk3:3.8-1 \
		java -jar /usr/GenomeAnalysisTK.jar -R /media/2/hg38.22XY.fa -I /media/3/${sample}.dedup.bam \
		-o /media/3/${sample}.realigned.bam -T IndelRealigner -targetIntervals \
		"/media/3/${sample}.realignment_target.list"
	fi
done

for sample in $(ls /media/kt256/T10G/TRUNG-CARRIER/kt155/result/); do
	docker wait gatk3_${sample}
done
docker rm $(docker ps -a | grep "Exited (0)" | awk '{print $1}')

## haplotypeCaller_round1 ##
for sample in $(ls /media/kt256/T10G/TRUNG-CARRIER/kt155/result/); do
	echo " Run haplotypeCaller_round1 "
	if [ -z "/media/kt256/T10G/TRUNG-CARRIER/kt155/result/${sample}/${sample}.raw_variants.vcf" ]; then
		# docker create -it --name gatk3 
		docker run -td --name gatk3_${sample} -v /media/kt256/T10G/TRUNG-CARRIER/kt155/1.CODE/:/media/1 \
		-v /media/kt256/T10G/2.resources/human_genome/hg38/:/media/2 \
		-v /media/kt256/T10G/TRUNG-CARRIER/kt155/result/${sample}/:/media/3 broadinstitute/gatk3:3.8-1 \
		java -jar /usr/GenomeAnalysisTK.jar -R /media/2/hg38.22XY.fa -I /media/3/${sample}.realigned.bam \
		-o /media/3/${sample}.raw_variants.vcf -T HaplotypeCaller -nct 3
	fi
done

for sample in $(ls /media/kt256/T10G/TRUNG-CARRIER/kt155/result/); do
	docker wait gatk3_${sample}
done
docker rm $(docker ps -a | grep "Exited (0)" | awk '{print $1}')

## selectVariants_round1 ##

for sample in $(ls /media/kt256/T10G/TRUNG-CARRIER/kt155/result/); do
	echo " Run selectVariants_round1 "
	if [ -z "/media/kt256/T10G/TRUNG-CARRIER/kt155/result/${sample}/${sample}.snps.vcf" ]; then
		# docker create -it --name gatk3 
		docker run -td --name gatk3_${sample} -v /media/kt256/T10G/TRUNG-CARRIER/kt155/1.CODE/:/media/1 \
		-v /media/kt256/T10G/2.resources/human_genome/hg38/:/media/2 \
		-v /media/kt256/T10G/TRUNG-CARRIER/kt155/result/${sample}/:/media/3 broadinstitute/gatk3:3.8-1 \
		java -jar /usr/GenomeAnalysisTK.jar -R /media/2/hg38.22XY.fa -V /media/3/${sample}.raw_variants.vcf \
		-selectType SNP -o /media/3/${sample}.snps.vcf -T SelectVariants 
		
		docker wait gatk3_${sample}
		docker rm gatk3_${sample}
	if [ -z "/media/kt256/T10G/TRUNG-CARRIER/kt155/result/${sample}/${sample}.indels.vcf" ]; then
		docker run -td --name gatk3_${sample} -v /media/kt256/T10G/TRUNG-CARRIER/kt155/1.CODE/:/media/1 \
		-v /media/kt256/T10G/2.resources/human_genome/hg38/:/media/2 \
		-v /media/kt256/T10G/TRUNG-CARRIER/kt155/result/${sample}/:/media/3 broadinstitute/gatk3:3.8-1 \
		java -jar /usr/GenomeAnalysisTK.jar -R /media/2/hg38.22XY.fa -I /media/3/${sample}.raw_variants.vcf \
		-selectType INDEL -o /media/3/${sample}.indels.vcf -T SelectVariants 
	fi
done

for sample in $(ls /media/kt256/T10G/TRUNG-CARRIER/kt155/result/); do
	docker wait gatk3_${sample}
done
docker rm $(docker ps -a | grep "Exited (0)" | awk '{print $1}')