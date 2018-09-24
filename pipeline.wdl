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
                control = sample.control,
                outputDir = outputDir + "/samples/" + sample.id
        }
    }

    ## Peakcalling
    scatter (sample in sampleTasks.sampleToBam) {
        if (defined(sample.right.control)) {
            String controlID = sample.right.control
            File inputBams = sample.right.bam.file
            File inputBamsIndex = sample.right.bam.index
            scatter (sample2 in sampleTasks.sampleToBam) {
                if (controlID == sample2.left) {
                    call macs2.PeakCalling as peakcalling {
                        input:
                            inputBams = inputBams,
                            inputBamsIndex = inputBamsIndex,
                            controlBams = sample2.right.bam.file,
                            controlBamsIndex = sample2.right.bam.index,
                            outDir = outputDir + "/macs2",
                            sampleName = sample.left
                    }
                }
            }
        }
        if (!defined(sample.right.control)) {
            call macs2.PeakCalling as peakcalling {
                input:
                     inputBams = inputBams,
                     inputBamsIndex = inputBamsIndex,
                     outDir = outputDir + "/macs2",
                     sampleName = sample.left
            }
        }
        File peakFile = peakcalling.peakFile
    }



    output {

    }
}
