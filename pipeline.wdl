version 1.0

import "sample.wdl" as sampleWorkflow
import "structs.wdl" as structs
import "tasks/biopet.wdl" as biopet
import "tasks/macs2.wdl" as macs2

workflow pipeline {
    input {
        Array[File] sampleConfigFiles
        String outputDir
        ChipSeqInput chipSeqInput
    }

    call biopet.SampleConfigCromwellArrays as configFile {
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

    output {

    }
}