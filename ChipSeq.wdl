version 1.0

# Copyright (c) 2018 Leiden University Medical Center
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import "sample.wdl" as sampleWf
import "structs.wdl" as structs
import "tasks/biowdl.wdl" as biowdl
import "tasks/common.wdl" as common
import "tasks/multiqc.wdl" as multiqc
import "tasks/macs2.wdl" as macs2

workflow ChipSeq {
    input {
        File sampleConfigFile
        String outputDir = "."
        File referenceFasta
        File referenceFastaFai
        File referenceFastaDict
        String platform = "illumina"
        Boolean useBwaKit = false

        BwaIndex? bwaIndex
        BwaIndex? bwaMem2Index
        String? adapterForward = "AGATCGGAAGAG"  # Illumina universal adapter.
        String? adapterReverse = "AGATCGGAAGAG"  # Illumina universal adapter.
        Int? scatterSize

        Int bwaThreads = 4
        Boolean umiDeduplication = false
        Boolean collectUmiStats = false
        File dockerImagesFile

        Int MAPQthreshold = 30
        File? excludeRegions
    }

    meta {
        WDL_AID: {
            exclude: ["DONOTDEFINE"]
        }
        allowNestedInputs: true
    }

    # Parse docker Tags configuration and sample sheet.
    call common.YamlToJson as convertDockerImagesFile {
        input:
            yaml = dockerImagesFile,
            outputJson = "dockerImages.json"
    }

    Map[String, String] dockerImages = read_json(convertDockerImagesFile.json)

    call biowdl.InputConverter as convertSampleConfig {
        input:
            samplesheet = sampleConfigFile,
            dockerImage = dockerImages["biowdl-input-converter"]
    }

    SampleConfig sampleConfig = read_json(convertSampleConfig.json)

    # Running sample subworkflow.
    scatter (sample in sampleConfig.samples) {
        String sampleIds = sample.id
        String sampleDir = outputDir + "/samples/" + sample.id + "/"
        call sampleWf.SampleWorkflow as sampleWorkflow {
            input:
                sampleDir = sampleDir,
                sample = sample,
                referenceFasta = referenceFasta,
                referenceFastaFai = referenceFastaFai,
                referenceFastaDict = referenceFastaDict,
                bwaIndex = bwaIndex,
                bwaMem2Index = bwaMem2Index,
                adapterForward = adapterForward,
                adapterReverse = adapterReverse,
                useBwaKit = useBwaKit,
                dockerImages = dockerImages,
                bwaThreads = bwaThreads,
                platform = platform,
                umiDeduplication = umiDeduplication,
                collectUmiStats = collectUmiStats,
                MAPQthreshold = MAPQthreshold,
                excludeRegions = excludeRegions
        }

    }
    scatter (sample in sampleConfig.samples) {
        call common.GetSamplePositionInArray as casePosition  {
            input:
                sampleIds = sampleIds,
                sample = sample.id,
                dockerImage = dockerImages["python"]
        }

        if (defined(sample.control)) {
            call common.GetSamplePositionInArray as controlPosition  {
                input:
                    sampleIds = sampleIds,
                    sample = select_first([sample.control])
            }
            File controlBam = sampleWorkflow.filteredBam[controlPosition.position]
            File controlBamIndex = sampleWorkflow.filteredBamIndex[controlPosition.position]
        }

        call macs2.PeakCalling as peakcalling {
            input:
                inputBams = [sampleWorkflow.filteredBam[casePosition.position]],
                inputBamsIndex = [sampleWorkflow.filteredBamIndex[casePosition.position]],
                controlBams = select_all([controlBam]),
                controlBamsIndex =  select_all([controlBamIndex]),
                outDir = outputDir + "/macs2",
                sampleName = sample.id
        }
    }



    Array[File] allReports = flatten(sampleWorkflow.reports)

    call multiqc.MultiQC as multiqcTask {
        input:
            reports = allReports,
            outDir = outputDir,
            dockerImage = dockerImages["multiqc"]
    }

    output {
        File dockerImagesList = convertDockerImagesFile.json
        File multiqcReport = multiqcTask.multiqcReport
        Array[File] reports = allReports
        Array[File] filteredBams = sampleWorkflow.filteredBam
        Array[File] filteredBamIndexes = sampleWorkflow.filteredBamIndex
        Array[File] peakFile = select_all(peakcalling.peakFile)
    }

    parameter_meta {
        # inputs
        sampleConfigFile: {description: "The samplesheet, including sample ids, library ids, readgroup ids and fastq file locations.", category: "required"}
        outputDir: {description: "The directory the output should be written to.", category: "common"}
        referenceFasta: {description: "The reference fasta file.", category: "required" }
        referenceFastaFai: {description: "Fasta index (.fai) file of the reference.", category: "required" }
        referenceFastaDict: {description: "Sequence dictionary (.dict) file of the reference.", category: "required" }
        platform: {description: "The platform used for sequencing.", category: "advanced"}
        useBwaKit: {description: "Whether or not BWA kit should be used. If false BWA mem will be used.", category: "advanced"}
        scatterSizeMillions:{description: "Same as scatterSize, but is multiplied by 1000000 to get scatterSize. This allows for setting larger values more easily.", category: "advanced"}
        bwaIndex: {description: "The BWA index files. When these are provided BWA will be used.", category: "common"}
        bwaMem2Index: {description: "The bwa-mem2 index files. When these are provided bwa-mem2 will be used.", category: "common"}
        adapterForward: {description: "The adapter to be removed from the reads first or single end reads.", category: "common"}
        adapterReverse: {description: "The adapter to be removed from the reads second end reads.", category: "common"}
        scatterSize: {description: "The size of the scattered regions in bases for the GATK subworkflows. Scattering is used to speed up certain processes. The genome will be seperated into multiple chunks (scatters) which will be processed in their own job, allowing for parallel processing. Higher values will result in a lower number of jobs. The optimal value here will depend on the available resources.", category: "advanced"}
        bwaThreads: {description: "The amount of threads for the alignment process.", category: "advanced"}
        dockerImagesFile: {description: "A YAML file describing the docker image used for the tasks. The dockerImages.yml provided with the pipeline is recommended.", category: "advanced"}
        umiDeduplication: {description: "Whether or not UMI based deduplication should be performed.", category: "common"}
        collectUmiStats: {description: "Whether or not UMI deduplication stats should be collected. This will potentially cause a massive increase in memory usage of the deduplication step.", category: "advanced"}
        MAPQthreshold: {description: "The mapping quality treshold to filter the BAM files on"}
        excludeRegions: {description: "Regions to exclude from the analysis"}

        # outputs
        dockerImagesList: {description: "Json file describing the docker images used by the pipeline."}
        multiqcReport: {description: "The MultiQC report for this pipeline."}
        reports: {description: "All pipeline reports for this pipeline."}
        filteredBams: {description: ""}
        filteredBamIndexes: {description: ""}
        peakFile: {description: "All peak files generated by MACS2"}
    }
}
