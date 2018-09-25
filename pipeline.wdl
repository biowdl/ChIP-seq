version 1.0

import "sample.wdl" as sampleWorkflow
import "structs.wdl" as structs
import "tasks/biopet/sampleconfig.wdl" as biopetSampleConfig
import "tasks/macs2.wdl" as macs2

workflow pipeline {
    input {
        Array[File] sampleConfigFiles
        String outputDir
        ChipSeqInput chipSeqInput
    }

    call biopetSampleConfig.SampleConfigCromwellArrays as configFile {
      input:
        inputFiles = sampleConfigFiles,
        outputPath = "samples.json"
    }

    Root config = read_json(configFile.outputFile)

    scatter (sample in config.samples) {
        call sampleWorkflow.Sample as sampleTasks {
            input:
                chipSeqInput = chipSeqInput,
                sample = sample,
                outputDir = outputDir + "/samples/" + sample.id
        }
    }

    ## Peakcalling
    scatter (sample in sampleTasks.sampleResults) {
        ## If sample has a control sample
        if (defined(sample.controlID)) {
            String? controlID = sample.controlID
            ## Loop over the samples again and get the control bam files
            scatter (sample2 in sampleTasks.sampleResults) {
                if (controlID == sample2.sampleID) {
                    File controlBams = sample2.bam.file
                    File controlBamsIndex = sample2.bam.index
                }
            }
            File controlBams = select_first(controlBams)
            File controlBamsIndex = select_first(controlBamsIndex)
        }

        call macs2.PeakCalling as peakcalling {
            input:
                inputBams = sample.bam.file,
                inputBamsIndex = sample.bam.index,
                controlBams = controlBams,
                controlBamsIndex = controlBamsIndex,
                outDir = outputDir + "/macs2",
                sampleName = sample.sampleID
        }
     }

    output {
        Array[File]+ peakFile = peakcalling.peakFile
    }
}
